import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';
import 'package:rest_client/rest_client.dart' as rc;
import 'package:template_expressions/template_expressions.dart';
import 'package:yaon/yaon.dart';

class LoadNetworkStep extends ServiceStep {
  LoadNetworkStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'load_network';

  static final Logger _logger = Logger('LoadNetworkStep');

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    final async = JsonClass.parseBool(args['async']);

    final argReqs = args['requests'] ?? [args['request']];
    final requests = <NetworkRequest>[];
    var index = 0;
    for (var arg in argReqs) {
      if (arg == null) {
        throw ServiceException(body: '[$kType]: no request or requests set');
      }

      final processed = process(context, arg);

      if (processed == null || processed.isEmpty) {
        throw ServiceException(
          body: '[$kType]: no request template is null or empty',
        );
      }

      requests.add(
        NetworkRequest.fromDynamic(
          json.decode(processed),
          defaultId: (++index).toString(),
        ),
      );
    }

    final variableName = args[StandardVariableNames.kNameVariable] ?? kType;
    final results = <String, dynamic>{};

    final futures = <Future>[];
    for (var request in requests) {
      final rcReq = rc.Request(
        body: request.body,
        headers: request.headers,
        method: rc.RequestMethod.lookup(request.method),
        url: request.url,
      );

      final future = () async {
        if (request.delay.inMilliseconds > 0) {
          await Future.delayed(request.delay);
        }
        final startTime = DateTime.now().millisecondsSinceEpoch;
        try {
          final response = await rc.Client().execute(
            request: rcReq,
            jsonResponse: request.processBody,
          );

          if (!async) {
            var body = response.body is String
                ? yaon.parse(response.body)
                : response.body;

            if (body is String) {
              final template = Template(
                syntax: context.registry.templateSyntax,
                value: body,
              );
              body = template.process(context: context.variables);
            }
            results[request.id] = {
              'body': body,
              'headers': response.headers,
              'statusCode': response.statusCode,
            };
          }
        } catch (e, stack) {
          _logger.severe(
            '[$kType]: error loading url: [${request.url}]',
            e,
            stack,
          );
        } finally {
          final endTime = DateTime.now().millisecondsSinceEpoch;
          final duration = (endTime - startTime) / 1000.0;
          _logger.fine({
            'message':
                '[$kType]: loaded url: [${request.url}] in [${duration}s]',
            'sessionId': context.request.sessionId,
            'requestId': context.request.requestId,
          });
        }
      }();

      futures.add(future);
    }

    if (!async) {
      await Future.wait(futures);
      context.variables[variableName] = results;
    }
  }
}
