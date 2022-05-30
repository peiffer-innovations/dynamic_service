import 'package:dynamic_service/dynamic_service.dart';

class MemoryServiceDefinitionLoader extends ServiceDefinitionLoader {
  MemoryServiceDefinitionLoader({
    required this.definition,
  });

  static final defaultInstance = MemoryServiceDefinitionLoader(
    definition: ServiceDefinition(entries: [
      ServiceEntry(
        evaluator: 'always',
        id: 'hello',
        steps: [
          {
            'type': 'apply_response',
            'args': {
              'body': 'Hello World!',
              'code': 200,
              'headers': {
                'content-type': 'text/plain',
              },
            },
          },
        ],
      )
    ], id: 'hello'),
  );

  final ServiceDefinition definition;

  @override
  Future<ServiceDefinition> loadServiceDefinition(
    DynamicServiceRegistry registry,
  ) async =>
      definition;
}
