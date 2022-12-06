import 'dart:async';
import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:template_expressions/template_expressions.dart';

class ServiceHandler {
  ServiceHandler({
    DynamicServiceRegistry? registry,
  }) : _registry = registry ?? DynamicServiceRegistry.defaultInstance;

  final _logger = Logger('service_handler');
  final DynamicServiceRegistry _registry;

  FutureOr<Response> handle(ServiceRequest request) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    Response? response;

    ServiceContext? context;
    ServiceResponse? onError;

    try {
      final definition =
          await _registry.serviceDefinitionLoader.load(_registry);

      final evaluatorStartTime = DateTime.now().millisecondsSinceEpoch;
      for (var entry in definition.entries) {
        // Reset the handler each time to guarantee one can never leak across
        // entries.
        onError = null;

        try {
          final evaluator = _registry.getEvaluator(entry.evaluator);

          context = await evaluator.evaluate(
            entry: entry,
            registry: _registry,
            request: request,
          );

          if (context != null) {
            onError = entry.onError;
            final duration =
                (DateTime.now().millisecondsSinceEpoch - evaluatorStartTime) /
                    1000.0;
            _logger.fine({
              'message':
                  '[functions]: Handler [${entry.id}] for [${request.method.toUpperCase()}] [${request.path}] in [${duration}s].',
              'sessionId': request.sessionId,
              'requestId': request.requestId,
            });
            final steps = await entry.stepLoader.load(registry: _registry);
            for (var step in steps) {
              final startTime = DateTime.now().millisecondsSinceEpoch;
              try {
                await step.execute(context);
              } catch (e, stack) {
                if (e is ServiceException) {
                  rethrow;
                }
                throw ServiceException(
                  body: 'Unknown error in step: [${step.type}]',
                  cause: e,
                  stack: stack,
                );
              } finally {
                final duration =
                    (DateTime.now().millisecondsSinceEpoch - startTime) /
                        1000.0;

                _logger.fine({
                  'message': '[${step.type}]: executed in: [${duration}s]',
                  'sessionId': request.sessionId,
                  'requestId': request.requestId,
                });
              }
            }

            response = context.response.toResponse();
            break;
          }
        } catch (e, stack) {
          if (e is ServiceException) {
            rethrow;
          }

          throw ServiceException(cause: e, stack: stack);
        }
      }

      if (response == null) {
        _logger.severe(
          '[functions]: Unable to locate service entry for [${request.method.toUpperCase()}] [${request.path}].',
        );
        throw ServiceException(body: 'Not Found', code: 404);
      }
    } catch (e, stack) {
      if (onError != null) {
        var body = onError.body;

        try {
          final encoded = utf8.decode(body);
          final template = Template(
            syntax: _registry.templateSyntax,
            value: encoded,
          );

          body = utf8.encode(template.process(
            context: context?.variables ?? {},
          ));
        } catch (_) {}

        onError.body = body;
        response = onError.toResponse();
      } else {
        if (e is ServiceException) {
          _logger.severe(json.encode(e.toJson()), e, e.stack ?? stack);
          response = Response(
            e.code,
            body: e.body ?? '$e\n${e.stack ?? stack}',
            headers: {
              'Content-Type': 'text/plain',
            },
          );
        } else {
          _logger.severe({
            'message': 'Uncaught error',
            'sessionId': request.sessionId,
            'requestId': request.requestId,
          }, e, stack);
          response = Response(
            500,
            body: '$e\n$stack',
            headers: {
              'Content-Type': 'text/plain',
            },
          );
        }
      }
    } finally {
      final duration =
          (DateTime.now().millisecondsSinceEpoch - startTime) / 1000.0;
      _logger.fine({
        'message': '[complete]: request completed in [${duration}s]',
        'sessionId': request.sessionId,
        'requestId': request.requestId,
      });
    }

    return response;
  }
}
