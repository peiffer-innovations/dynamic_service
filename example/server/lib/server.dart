import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

class Server {
  Future<void> start(List<String> args) async {
    var parser = ArgParser();
    parser.addOption(
      'port',
      abbr: 'p',
      help: 'Port to run the application on',
      defaultsTo: '8080',
    );
    var params = parser.parse(args);

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      var body = record.object ?? record.message;

      var output = {
        'name': record.loggerName,
        'level': record.level.name,
        'time': record.time.toString(),
      };

      if (body is Map) {
        for (var entry in body.entries) {
          output[entry.key] = entry.value.toString();
        }
      } else {
        output['message'] = body.toString();
      }

      if (record.error != null) {
        output['error'] = '${record.error}';
      }
      if (record.stackTrace != null) {
        output['stack'] = '${record.stackTrace}';
      }

      // ignore: avoid_print
      print(json.encode(output));
    });

    var output = Directory('output');
    if (output.existsSync()) {
      output.deleteSync(recursive: true);
    }
    output.createSync(recursive: true);

    DynamicServiceRegistry.defaultInstance = DynamicServiceRegistry(
      refLoaders: [
        FileRefLoader(),
        FileRefLoader(protocol: 'output'),
        NetworkRefLoader(),
      ],
      serviceDefinitionLoader: AssetServiceDefinitionLoader(
        path: 'service.yaml',
      ),
      writers: [
        FileWriter(),
      ],
    );

    var service = ServiceHandler();

    var handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsHeaders(headers: {
          ACCESS_CONTROL_ALLOW_HEADERS: [
            'accept',
            'accept-encoding',
            'accept-language',
            'authorization',
            'content-type',
            'dnt',
            'if-none-match',
            'origin',
            'user-agent',
            'x-authorization'
          ].join(',')
        }))
        .addHandler(
          (request) async => service.handle(
            await ServiceRequest.fromRequest(request),
          ),
        );
    var server = await shelf_io.serve(
      handler,
      'localhost',
      JsonClass.parseInt(params['port']) ?? 8080,
    );

    server.autoCompress = true;

    // ignore: avoid_print
    print('Serving at http://${server.address.host}:${server.port}');
  }
}
