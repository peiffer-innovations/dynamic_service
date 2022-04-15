import 'package:dynamic_service/dynamic_service.dart';

class MemoryServiceDefinitionLoader extends ServiceDefinitionLoader {
  MemoryServiceDefinitionLoader({
    required this.definition,
  });

  final ServiceDefinition definition;

  @override
  Future<ServiceDefinition> loadServiceDefinition(
    DynamicServiceRegistry registry,
  ) async =>
      definition;
}
