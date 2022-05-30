import 'dart:math';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';

class DelayStep extends ServiceStep {
  DelayStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'delay';
  static final Logger _logger = Logger('DelayStep');

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    var pMin = process(context, args['max']);
    var pMax = process(context, args['min']);

    var max = JsonClass.parseInt(pMin) ?? 5000;
    var min = JsonClass.parseInt(pMax) ?? 1000;

    assert(min <= max);
    assert(min >= 0);
    assert(max >= 0);

    var random = Random();
    var delay = random.nextInt(max - min) + min;

    _logger.fine({
      'message': 'Waiting for [${delay / 1000.0}s]',
      'sessionId': context.request.sessionId,
      'requestId': context.request.requestId,
    });

    await Future.delayed(Duration(milliseconds: delay));
  }
}
