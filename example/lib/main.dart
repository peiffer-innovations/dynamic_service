import 'dart:convert';
import 'dart:io';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:dynamic_service/functions.dart' as function_library;
import 'package:functions_framework/serve.dart';
import 'package:logging/logging.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

Future<void> main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    var body = record.object ?? record.message;

    var output = {'level': record.level.name, 'time': record.time.toString()};

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
      AssetRefLoader(),
      AssetRefLoader(protocol: 'output'),
      NetworkRefLoader(),
    ],
    serviceDefinitionLoader: AssetServiceDefinitionLoader(
      path: 'service.yaml',
    ),
  );

  await serve(
    args,
    _nameToFunctionTarget,
    autoCompress: true,
    customMiddleware: corsHeaders(),
  );
}

FunctionTarget? _nameToFunctionTarget(String name) {
  switch (name) {
    case 'function':
      return FunctionTarget.http(
        function_library.function,
      );
    default:
      return null;
  }
}
