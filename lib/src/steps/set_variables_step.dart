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
    var ref = args[r'$ref'];

    if (ref == null) {
      context.variables.addAll(args);
    } else {
      var variable = args[StandardVariableNames.kNameVariable];
      var data = await context.registry.loadRef(ref, context: context);
      try {
        if (data is Map || data is Iterable) {
          data = json.encode(data);
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
        );
      }

      try {
        data = json.decode(data);
      } catch (e, stack) {
        _logger.fine({
          'message': 'Error attempting to JSON decode data',
          'sessionId': context.request.sessionId,
          'requestId': context.request.requestId,
        }, e, stack);
      }

      var variables = <String, dynamic>{};
      if (data is Map) {
        variables.addAll(
          data.map(
            (key, value) => MapEntry<String, dynamic>(key.toString(), value),
          ),
        );

        if (variable == null) {
          context.variables.addAll(variables);
        } else {
          context.variables[variable] = variables;
        }
      } else {
        context.variables[variable ?? StandardVariableNames.kNameVariable] =
            data;
      }
    }
  }
}
