import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';

class ConditionalStep extends ServiceStep {
  ConditionalStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'conditional';

  static final _logger = Logger('ConditionalStep');

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    final whenFalse = args['steps-false'];
    final whenTrue = args['steps-true'];

    final condition = args['condition']?.toString();

    final processed = process(context, condition);
    final result = JsonClass.parseBool(processed);

    _logger.finer('[result]: [$result]');

    final steps = result ? whenTrue : whenFalse;

    if (steps != null) {
      await context.registry.executeDynamicSteps(steps, context: context);
    }
  }
}
