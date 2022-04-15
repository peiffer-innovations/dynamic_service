import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:meta/meta.dart';
import 'package:template_expressions/template_expressions.dart';

abstract class ServiceStep extends JsonClass {
  ServiceStep({
    Map<String, dynamic>? args,
    required this.type,
  }) : args = args ?? const <String, dynamic>{};

  final Map<String, dynamic> args;
  final String type;

  static ServiceStep fromDynamic(
    dynamic map, {
    required DynamicServiceRegistry registry,
  }) {
    ServiceStep result;

    if (map == null) {
      throw Exception('[ServiceStep]: map is null');
    }

    var type = map['type'];
    var args = map['with'];

    if (args is Map) {
      args = Map<String, String>.from(args);
    }

    result = registry.getStep(
      args: args,
      type: type,
    );

    return result;
  }

  Future<void> execute(ServiceContext context) async {
    var template = Template(value: json.encode(args));
    var templateData = template.process(context: context.variables);

    var processed = json.decode(templateData);

    return applyStep(context, processed);
  }

  @visibleForOverriding
  Future<void> applyStep(ServiceContext context, Map<String, dynamic> args);

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'with': args,
      };
}
