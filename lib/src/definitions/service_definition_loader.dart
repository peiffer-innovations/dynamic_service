import 'dart:async';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:meta/meta.dart';

abstract class ServiceDefinitionLoader {
  Completer<ServiceDefinition>? _completer;

  Future<ServiceDefinition> load(
    DynamicServiceRegistry registry,
  ) async {
    var completer = _completer;
    if (completer == null) {
      completer = Completer<ServiceDefinition>();
      _completer = completer;

      try {
        var result = await loadServiceDefinition(registry);
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
