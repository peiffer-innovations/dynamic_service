import 'dart:async';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:meta/meta.dart';

class ServiceEntry {
  ServiceEntry({
    ServiceCriteria? criteria,
    String? evaluator,
    required this.id,
    ServiceResponse? response,
    StepLoader? stepLoader,
    dynamic steps,
  })  : assert((stepLoader != null && steps == null) ||
            (stepLoader == null && steps != null)),
        criteria = criteria ?? ServiceCriteria(),
        evaluator = evaluator ?? DefaultCriteriaEvaluator.kType,
        response = response ?? ServiceResponse(),
        stepLoader = stepLoader ?? StepLoader(steps);

  final ServiceCriteria criteria;
  final String evaluator;
  final String id;
  final ServiceResponse response;
  final StepLoader stepLoader;

  static Future<ServiceEntry> fromDynamic(
    dynamic map, {
    required String id,
    bool lazy = true,
    required DynamicServiceRegistry registry,
  }) async {
    if (map == null) {
      throw ServiceException(body: '[ServiceEntry]: map is null');
    }

    return ServiceEntry(
      criteria: ServiceCriteria.fromDynamic(map['criteria']),
      evaluator: map['evaluator']?.toString(),
      id: (map['id'] ?? id).toString(),
      steps: map['steps'],
    );
  }
}

class StepLoader {
  StepLoader(this.steps);

  final dynamic steps;
  List<ServiceStep>? _steps;

  Future<List<ServiceStep>> load({
    required DynamicServiceRegistry registry,
  }) async {
    var result = _steps;

    if (result == null) {
      result = await actualLoad(
        steps,
        registry: registry,
      );
      _steps = result;
    }

    return result;
  }

  @visibleForOverriding
  Future<List<ServiceStep>> actualLoad(
    dynamic steps, {
    required DynamicServiceRegistry registry,
  }) async {
    var result = <ServiceStep>[];

    if (steps is Map) {
      var ref = steps[r'$ref'];
      if (ref == null) {
        result.add(ServiceStep.fromDynamic(steps, registry: registry));
      } else {
        var data = await registry.loadRef(ref);
        data = data['steps'] ?? data;

        if (data is Iterable || data is Map) {
          result.addAll(await actualLoad(
            data,
            registry: registry,
          ));
        } else {
          throw ServiceException(
            body:
                '[StepLoader]: unknown step data type: [${data?.runtimeType.toString()}]',
          );
        }
      }
    } else if (steps is Iterable) {
      for (var step in steps) {
        result.addAll(await actualLoad(
          step,
          registry: registry,
        ));
      }
    } else {
      throw ServiceException(
        body:
            '[StepLoader]: unknown steps data type: [${steps?.runtimeType.toString()}]',
      );
    }

    return result;
  }
}
