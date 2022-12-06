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
    final parallel = JsonClass.parseBool(
      args[StandardVariableNames.kNameParallel],
    );
    final variableName = args[StandardVariableNames.kNameVariable] ??
        StandardVariableNames.kNameVariable;
    final indexName = args[StandardVariableNames.kNameIndex] ??
        StandardVariableNames.kNameIndex;

    var input = args[StandardVariableNames.kNameInput];

    final ref = args['\$ref'];
    if (ref != null) {
      input = context.registry.loadRef(ref, context: context);
    }

    final result = json.decode(process(context, input)!);

    final futures = <Future>[];
    final steps = args['steps'];

    if (result is Map) {
      for (var entry in result.entries) {
        final chContext = ChildServiceContext(parent: context);
        chContext.variables[indexName] = entry.key;
        chContext.variables[variableName] = entry.value;
        final future = chContext.registry.executeDynamicSteps(
          steps,
          context: chContext,
        );
        if (parallel) {
          futures.add(future);
          // ignore: unawaited_futures
          future.then((value) {
            context.variables.addAll(chContext.childVariables);
          });
        } else {
          await future;
          context.variables.addAll(chContext.childVariables);
        }
      }
    } else if (result is Iterable) {
      var index = 0;
      for (var entry in result) {
        final chContext = ChildServiceContext(parent: context);
        chContext.variables[indexName] = index;
        chContext.variables[variableName] = entry;
        final future = chContext.registry.executeDynamicSteps(
          steps,
          context: chContext,
        );
        if (parallel) {
          futures.add(future);
          // ignore: unawaited_futures
          future.then((value) {
            context.variables.addAll(chContext.childVariables);
          });
        } else {
          await future;
          context.variables.addAll(chContext.childVariables);
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
