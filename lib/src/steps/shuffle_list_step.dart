import 'dart:math';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:template_expressions/template_expressions.dart';
import 'package:yaon/yaon.dart' as yaon;

class ShuffleListStep extends ServiceStep {
  ShuffleListStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'shuffle_list';

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    var random = Random.secure();
    var list = yaon.parse(args['list']);
    var passes = JsonClass.parseInt(
          Template(
            syntax: context.registry.templateSyntax,
            value: args['passes'] ?? '1',
          ).process(context: context.variables),
        ) ??
        1;
    var variable = args[StandardVariableNames.kNameVariable] ?? kType;

    if (list is List) {
      var result = List.from(list);

      for (var i = 0; i < passes; i++) {
        for (var j = 0; j < result.length; j++) {
          var target = random.nextInt(result.length);

          if (target != j) {
            var temp = result[j];
            result[j] = result[target];
            result[target] = temp;
          }
        }
      }
      context.variables[variable] = result;
    }
  }
}
