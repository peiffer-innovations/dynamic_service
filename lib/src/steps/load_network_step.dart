import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';
import 'package:rest_client/rest_client.dart' as rc;

class LoadAssetsStep extends ServiceStep {
  LoadAssetsStep({
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
    var async = JsonClass.parseBool(args['async']);

    var argReqs = args['requests'];
    var requests = <NetworkRequest>[];
    var index = 0;
    for (var arg in argReqs) {
      requests.add(
        NetworkRequest.fromDynamic(
          arg,
          defaultId: (++index).toString(),
        ),
      );
    }

    var variableName = args['variable'] ?? 'load_network_responses';
    var results = <String, dynamic>{};

    var futures = <Future>[];
    for (var request in requests) {
      var rcReq = rc.Request(
        body: request.body,
        headers: request.headers,
        method: rc.RequestMethod.lookup(request.method),
        url: request.url,
      );

      
      var future = () async {
        if (request.delay.inMilliseconds > 0) {
          await Future.delayed(request.delay);
        }
        var response = await rc.Client().execute(
          request: rcReq,
          jsonResponse: request.processBody,
        );

        if (!async) {
          results[request.id] = {
            'body': response.body,
            'headers': response.headers,
            'statusCode': response.statusCode,
          };
        }
      }();

      futures.add(future);
    }

    if (!async) {
      context.variables[variableName] = results;
    }
  }
}
