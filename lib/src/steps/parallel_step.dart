import 'package:dynamic_service/dynamic_service.dart';

class ParallelStep extends ServiceStep {
  ParallelStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'parallel';

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    var steps = args['steps'];

    await context.registry.executeDynamicSteps(
      steps,
      context: context,
      parallel: true,
    );
  }
}
