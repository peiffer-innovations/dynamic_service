import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';
import 'package:yaon/yaon.dart' as yaon;

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
    var whenFalse = args['steps-false'];
    var whenTrue = args['steps-true'];

    var condition = args['condition'];
    if (condition is! String) {
      try {
        condition = yaon.parse(condition);
      } catch (_) {
        // no-op
      }
    }

    var processed = process(context, condition);
    var result = JsonClass.parseBool(processed);

    _logger.finer('[result]: [$result]');

    var steps = result ? whenTrue : whenFalse;

    if (steps != null) {
      await context.registry.executeDynamicSteps(steps, context: context);
    }
  }
}
