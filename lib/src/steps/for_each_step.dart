import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';

class ForEachStep extends ServiceStep {
  ForEachStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'for_each';

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    var parallel = JsonClass.parseBool(
      args[StandardVariableNames.kNameParallel],
    );
    var variableName = args[StandardVariableNames.kNameVariable] ??
        StandardVariableNames.kNameVariable;
    var indexName = args[StandardVariableNames.kNameIndex] ??
        StandardVariableNames.kNameIndex;

    var input = args[StandardVariableNames.kNameInput];

    var ref = args['\$ref'];
    if (ref != null) {
      input = context.registry.loadRef(ref, context: context);
    }

    var result = json.decode(process(context, input)!);

    var futures = <Future>[];
    var steps = args['steps'];

    if (result is Map) {
      for (var entry in result.entries) {
        var chContext = ChildServiceContext(parent: context);
        chContext.variables[variableName] = entry;
        var future = chContext.registry.executeDynamicSteps(
          steps,
          context: chContext,
        );
        if (parallel) {
          futures.add(future);
          // ignore: unawaited_futures
          future.then((value) {
            context.variables.addAll(chContext.variables);
          });
        } else {
          await future;
          context.variables.addAll(chContext.variables);
        }
      }
    } else if (result is Iterable) {
      var index = 0;
      for (var entry in result) {
        var chContext = ChildServiceContext(parent: context);
        chContext.variables[indexName] = index;
        chContext.variables[variableName] = entry;
        var future = chContext.registry.executeDynamicSteps(
          steps,
          context: chContext,
        );
        if (parallel) {
          futures.add(future);
          // ignore: unawaited_futures
          future.then((value) {
            context.variables.addAll(chContext.variables);
          });
        } else {
          await future;
          context.variables.addAll(chContext.variables);
        }
        index++;
      }
    } else {
      throw ServiceException(
        body: 'Unkown object type for iterating: [${result?.runtimeType}]',
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }
}
