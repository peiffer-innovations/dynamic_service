import 'dart:async';
import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:functions_framework/functions_framework.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

final _logger = Logger('function');

Middleware? _middleware;

void addMiddleware(Middleware middleware) {
  if (_middleware == null) {
    _middleware = middleware;
  } else {
    _middleware!.addMiddleware(middleware);
  }
}

@CloudFunction()
Future<Response> function(Request request) async {
  var middleware = _middleware;
  var handler = middleware == null ? _process : (await middleware(_process));

  return await handler(request);
}

FutureOr<Response> _process(Request request) async {
  var startTime = DateTime.now().millisecondsSinceEpoch;
  Response? response;
  var req = await ServiceRequest.fromRequest(request);
  try {
    var registry = DynamicServiceRegistry.defaultInstance;

    var definition = await registry.serviceDefinitionLoader.load(registry);

    var evaluatorStartTime = DateTime.now().millisecondsSinceEpoch;
    for (var entry in definition.entries) {
      try {
        var evaluator = registry.getEvaluator(entry.evaluator);

        var context = await evaluator.evaluate(
          entry: entry,
          registry: registry,
          request: req,
        );

        if (context != null) {
          var duration =
              (DateTime.now().millisecondsSinceEpoch - evaluatorStartTime) /
                  1000.0;
          _logger.fine({
            'message':
                '[functions]: Handler [${entry.id}] for [${request.method.toUpperCase()}] [${request.url.path}] in [${duration}s].',
            'sessionId': req.sessionId,
            'requestId': req.requestId,
          });
          var steps = await entry.stepLoader.load(registry: registry);
          for (var step in steps) {
            var startTime = DateTime.now().millisecondsSinceEpoch;
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
              var duration =
                  (DateTime.now().millisecondsSinceEpoch - startTime) / 1000.0;

              _logger.fine({
                'message': '[${step.type}]: executed in: [${duration}s]',
                'sessionId': req.sessionId,
                'requestId': req.requestId,
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
        '[functions]: Unable to locate service entry for [${request.method.toUpperCase()}] [${request.url.path}].',
      );
      throw ServiceException(body: 'Not Found', code: 404);
    }
  } catch (e, stack) {
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
        'sessionId': req.sessionId,
        'requestId': req.requestId,
      }, e, stack);
      response = Response(
        500,
        body: '$e\n$stack',
        headers: {
          'Content-Type': 'text/plain',
        },
      );
    }
  } finally {
    var duration = (DateTime.now().millisecondsSinceEpoch - startTime) / 1000.0;
    _logger.fine({
      'message': '[complete]: request completed in [${duration}s]',
      'sessionId': req.sessionId,
      'requestId': req.requestId,
    });
  }

  return response;
}
