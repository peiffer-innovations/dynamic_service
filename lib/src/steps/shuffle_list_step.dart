import 'dart:io';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:logging/logging.dart';

class ShuffleListStep extends ServiceStep {
  ShuffleListStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'shuffle_list';

  static final Logger _logger = Logger('ShuffleListStep');

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    var root = args['root']?.toString() ?? 'assets/';
    if (!root.endsWith('/') && root.isNotEmpty) {
      root = '$root/';
    }
    var assets = args['assets'];
    if (assets is! Map) {
      throw ServiceException(
        body:
            '[LoadAssetsStep]: unknown type on assets: [${assets?.runtimeType.toString()}].',
      );
    }

    for (var entry in assets.entries) {
      var file = File('$root${entry.value}');

      if (!file.existsSync()) {
        throw ServiceException(
          body:
              '[LoadAssetsStep]: unable to load file: [${file.absolute.path}].',
        );
      }
      var data = DynamicStringParser.parse(file.readAsStringSync());

      context.variables[entry.key] = data;

      _logger.fine(
        'Loaded [${file.absolute.path}] to variable [${entry.key}]',
      );
    }
  }
}
