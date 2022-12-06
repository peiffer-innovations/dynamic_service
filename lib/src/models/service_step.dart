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

    final type = map['type'];
    if (type == null) {
      throw Exception('[ServiceStep]: type is null\n$map');
    }
    var args = map['with'] ?? const <String, dynamic>{};

    try {
      if (args is Map) {
        args = Map<String, dynamic>.from(args);
      }

      result = registry.getStep(
        args: args,
        type: type,
      );
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }

      throw Exception('[ServiceStep]: error building step\n$map');
    }

    return result;
  }

  @visibleForOverriding
  Future<void> applyStep(ServiceContext context, Map<String, dynamic> args);

  Future<void> execute(ServiceContext context) => applyStep(context, args);

  String? process(ServiceContext context, dynamic value) {
    String? data;

    if (value != null) {
      if (value is String) {
        data = value;
      } else if (value is Map || value is List) {
        try {
          data = json.encode(value);
        } catch (e) {
          // no-op
        }
      } else {
        data = value.toString();
      }
    }

    if (data != null && data.isNotEmpty) {
      data = Template(
        syntax: context.registry.templateSyntax,
        value: data.toString(),
      ).process(context: context.variables);
    }

    return data;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'with': args,
      };
}
