import 'package:dynamic_service/dynamic_service.dart';
import 'package:dynamic_service/src/definitions/memory_service_definition_loader.dart';
import 'package:logging/logging.dart';
import 'package:template_expressions/template_expressions.dart';

typedef StepBuilder = ServiceStep Function(Map<String, dynamic> args);

class DynamicServiceRegistry {
  DynamicServiceRegistry({
    Map<String, CriteriaEvaluator>? evaluators,
    List<RefLoader>? refLoaders,
    Map<String, StepBuilder>? steps,
    required this.serviceDefinitionLoader,
    List<ExpressionSyntax>? templateSyntax,
  })  : templateSyntax =
            List.unmodifiable(templateSyntax ?? [StandardExpressionSyntax()]),
        _refLoaders = refLoaders ?? [AssetRefLoader()] {
    evaluators?.forEach((key, value) => _evaluators[key] = value);
    steps?.forEach((key, value) => _steps[key] = value);
  }

  static DynamicServiceRegistry defaultInstance = DynamicServiceRegistry(
    serviceDefinitionLoader: MemoryServiceDefinitionLoader(
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
    ),
  );

  static final Logger _logger = Logger('DynamicServiceRegistry');

  final ServiceDefinitionLoader serviceDefinitionLoader;
  final List<ExpressionSyntax> templateSyntax;

  final Map<String, CriteriaEvaluator> _evaluators = {
    AlwaysCriteriaEvaluator.kType: AlwaysCriteriaEvaluator(),
    DefaultCriteriaEvaluator.kType: DefaultCriteriaEvaluator(),
  };
  final List<RefLoader> _refLoaders;
  final Map<String, StepBuilder> _steps = {
    DelayStep.kType: (args) => DelayStep(args: args),
    ETagStep.kType: (args) => ETagStep(args: args),
    SetResponseStep.kType: (args) => SetResponseStep(args: args),
    SetVariablesStep.kType: (args) => SetVariablesStep(args: args),
    ShuffleListStep.kType: (args) => ShuffleListStep(args: args),
    ValidateJwtStep.kType: (args) => ValidateJwtStep(args: args),
    WriteFileStep.kType: (args) => WriteFileStep(args: args),
  };

  CriteriaEvaluator getEvaluator(String? type) {
    var result = _evaluators[type];
    if (result == null) {
      throw Exception(
        '[DynamicServiceRegistry]: unknown evaluator type: [$type].',
      );
    }
    return result;
  }

  ServiceStep getStep({
    required Map<String, dynamic> args,
    required String type,
  }) {
    ServiceStep result;
    var builder = _steps[type];

    if (builder == null) {
      throw Exception('[DynamicServiceRegistry]: unknown step type: [$type]');
    }

    result = builder(args);

    return result;
  }

  Future<dynamic> loadRef(String ref) async {
    try {
      _logger.info('[loadRef]: attempting to load ref: [$ref]');
      RefLoader? refLoader = _refLoaders.firstWhere(
        (loader) => loader.canLoad(ref),
      );

      return await refLoader.load(ref, registry: this);
    } catch (e, stack) {
      throw ServiceException(
        body: 'Unable to load \$ref: [$ref]',
        cause: e,
        stack: stack,
      );
    }
  }

  void registerEvaluator({
    required CriteriaEvaluator evaluator,
    required String type,
  }) =>
      _evaluators[type] = evaluator;

  void registerEvaluators(Map<String, CriteriaEvaluator> evaluators) =>
      _evaluators.addAll(evaluators);

  void registerStep({
    required String type,
    required StepBuilder builder,
  }) =>
      _steps[type] = builder;

  void registerSteps(Map<String, StepBuilder> steps) => _steps.addAll(steps);
}
