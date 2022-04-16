import 'dart:async';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

abstract class ServiceDefinitionLoader {
  static final Logger _logger = Logger('ServiceDefinitionLoader');

  Completer<ServiceDefinition>? _completer;

  Future<ServiceDefinition> load(
    DynamicServiceRegistry registry,
  ) async {
    var completer = _completer;
    if (completer == null) {
      completer = Completer<ServiceDefinition>();
      _completer = completer;

      try {
        dynamic result;

        var startTime = DateTime.now().millisecondsSinceEpoch;
        try {
          result = await loadServiceDefinition(registry);
        } catch (_) {
          rethrow;
        } finally {
          var duration =
              (DateTime.now().millisecondsSinceEpoch - startTime) / 1000.0;
          _logger.fine(
            '[${runtimeType.toString()}]: loaded service definition in [${duration}s]',
          );
        }
        completer.complete(result);
      } catch (e, stack) {
        completer.completeError(e, stack);
      }
    }

    return completer.future;
  }

  @visibleForOverriding
  Future<ServiceDefinition> loadServiceDefinition(
    DynamicServiceRegistry registry,
  );
}
