import 'dart:io';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:dynamic_service/functions.dart' as function_library;
import 'package:functions_framework/serve.dart';
import 'package:logging/logging.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

Future<void> main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      // ignore: avoid_print
      print('${record.error}');
    }
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('${record.stackTrace}');
    }
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
