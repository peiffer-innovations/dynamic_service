import 'package:dynamic_service/dynamic_service.dart';
import 'package:dynamic_service/src/definitions/memory_service_definition_loader.dart';
import 'package:dynamic_service/src/steps/load_network_step.dart';
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
    CreateJwtStep.kType: (args) => CreateJwtStep(args: args),
    DelayStep.kType: (args) => DelayStep(args: args),
    ETagStep.kType: (args) => ETagStep(args: args),
    LoadNetworkStep.kType: (args) => LoadNetworkStep(args: args),
    SetResponseStep.kType: (args) => SetResponseStep(args: args),
    SetVariablesStep.kType: (args) => SetVariablesStep(args: args),
    ShuffleListStep.kType: (args) => ShuffleListStep(args: args),
    ValidateJwtStep.kType: (args) => ValidateJwtStep(args: args),
    ValidateSchemaStep.kType: (args) => ValidateSchemaStep(args: args),
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

    try {
      result = builder(args);

      return result;
    } catch (e) {
      _logger.severe('[getStep]: error building step: [$type]');
      rethrow;
    }
  }

  Future<dynamic> loadRef(
    String ref, {
    ServiceContext? context,
  }) async {
    try {
      ref = Template(syntax: templateSyntax, value: ref).process(
        context: context?.variables ?? const <String, dynamic>{},
      );

      _logger.info({
        'message': '[loadRef]: attempting to load ref: [$ref]',
        'sessionId': context?.request.sessionId ?? '<internal>',
        'requestId': context?.request.requestId ?? '<internal>',
      });
      RefLoader? refLoader = _refLoaders.firstWhere(
        (loader) => loader.canLoad(ref),
      );

      var startTime = DateTime.now().millisecondsSinceEpoch;
      var result = await refLoader.load(ref, registry: this);
      var duration =
          (DateTime.now().millisecondsSinceEpoch - startTime) / 1000.0;
      _logger.fine({
        'message': '[loadRef]: loaded ref: [$ref] in [${duration}s]',
        'sessionId': context?.request.sessionId ?? '<internal>',
        'requestId': context?.request.requestId ?? '<internal>',
      });

      return result;
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
