import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:logging/logging.dart';
import 'package:template_expressions/template_expressions.dart';

class SetVariablesStep extends ServiceStep {
  SetVariablesStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'set_variables';
  static final Logger _logger = Logger('SetVariablesStep');

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    final ref = args[r'$ref'];

    if (ref == null) {
      context.variables.addAll(
        args.map(
          (key, value) => MapEntry<String, dynamic>(
            key,
            process(context, value),
          ),
        ),
      );
    } else {
      final variable = args[StandardVariableNames.kNameVariable] ?? kType;
      var data = await context.registry.loadRef(ref, context: context);
      var jsonEncoded = false;
      try {
        if (data is Map || data is Iterable) {
          data = json.encode(data);
          jsonEncoded = true;
        }
      } catch (e, stack) {
        _logger.fine({
          'message': 'Error attempting to JSON encode data',
          'sessionId': context.request.sessionId,
          'requestId': context.request.requestId,
        }, e, stack);
      }

      if (data is String) {
        data = Template(
          syntax: context.registry.templateSyntax,
          value: data,
        ).process(context: context.variables);
      }

      if (jsonEncoded) {
        try {
          data = json.decode(data);
        } catch (e, stack) {
          _logger.fine({
            'message': 'Error attempting to JSON decode data',
            'sessionId': context.request.sessionId,
            'requestId': context.request.requestId,
          }, e, stack);
        }
      }

      context.variables[variable] = data;
    }
  }
}
