import 'dart:io';

import 'package:dynamic_service/dynamic_service.dart';

class AssetServiceDefinitionLoader extends ServiceDefinitionLoader {
  AssetServiceDefinitionLoader({required this.path, String? root})
      : root = root == null
            ? 'assets/'
            : root.endsWith('/') == true
                ? root
                : '$root/';

  final String path;
  final String root;

  @override
  Future<ServiceDefinition> loadServiceDefinition(
    DynamicServiceRegistry registry,
  ) async {
    var file = File('$root$path');

    if (!file.existsSync()) {
      throw ServiceException(
        body:
            '[AssetServiceDefinitionLoader]: error loading asset: [${file.absolute.path}]',
      );
    }

    var data = file.readAsStringSync();

    var parsed = DynamicStringParser.parse(data);

    return ServiceDefinition.fromDynamic(parsed, registry: registry);
  }
}
