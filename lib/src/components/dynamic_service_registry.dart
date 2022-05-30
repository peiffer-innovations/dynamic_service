import 'package:dynamic_service/dynamic_service.dart';
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
    List<Writer>? writers,
  })  : templateSyntax =
            List.unmodifiable(templateSyntax ?? [StandardExpressionSyntax()]),
        _refLoaders = refLoaders ?? [FileRefLoader()],
        _writers = writers ?? const [] {
    evaluators?.forEach((key, value) => _evaluators[key] = value);
    steps?.forEach((key, value) => _steps[key] = value);
  }

  static DynamicServiceRegistry defaultInstance = DynamicServiceRegistry(
    serviceDefinitionLoader: MemoryServiceDefinitionLoader.defaultInstance,
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
    ForEachStep.kType: (args) => ForEachStep(args: args),
    LoadNetworkStep.kType: (args) => LoadNetworkStep(args: args),
    ParallelStep.kType: (args) => ParallelStep(args: args),
    SetResponseStep.kType: (args) => SetResponseStep(args: args),
    SetVariablesStep.kType: (args) => SetVariablesStep(args: args),
    ShuffleListStep.kType: (args) => ShuffleListStep(args: args),
    ValidateJwtStep.kType: (args) => ValidateJwtStep(args: args),
    ValidateSchemaStep.kType: (args) => ValidateSchemaStep(args: args),
    WriteStep.kType: (args) => WriteStep(args: args),
  };
  final List<Writer> _writers;

  Future<void> executeDynamicSteps(
    dynamic steps, {
    required ServiceContext context,
    bool parallel = false,
  }) async {
    var loader = StepLoader(steps);
    var loaded = await loader.load(registry: context.registry);

    var futures = <Future>[];
    for (var s in loaded) {
      var future = s.execute(context);

      if (parallel) {
        futures.add(future);
      } else {
        await future;
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

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

  Future<void> write(
    String target,
    dynamic contents, {
    required ServiceContext context,
    Map<String, dynamic>? properties,
  }) async {
    try {
      target = Template(syntax: templateSyntax, value: target).process(
        context: context.variables,
      );

      _logger.info({
        'message': '[write]: attempting to write: [$target]',
        'sessionId': context.request.sessionId,
        'requestId': context.request.requestId,
      });
      Writer? writer = _writers.firstWhere(
        (loader) => loader.canWrite(target),
      );

      var startTime = DateTime.now().millisecondsSinceEpoch;
      await writer.write(
        target,
        contents,
        context: context,
        properties: properties,
      );
      var duration =
          (DateTime.now().millisecondsSinceEpoch - startTime) / 1000.0;
      _logger.fine({
        'message': '[write]: wrote: [$target] in [${duration}s]',
        'sessionId': context.request.sessionId,
        'requestId': context.request.requestId,
      });
    } catch (e, stack) {
      throw ServiceException(
        body: 'Unable to write: [$target]',
        cause: e,
        stack: stack,
      );
    }
  }
}
