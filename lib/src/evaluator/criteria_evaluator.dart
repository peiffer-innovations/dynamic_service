import 'package:dynamic_service/dynamic_service.dart';

abstract class CriteriaEvaluator {
  Future<ServiceContext?> evaluate({
    required ServiceEntry entry,
    required DynamicServiceRegistry registry,
    required ServiceRequest request,
  });
}
