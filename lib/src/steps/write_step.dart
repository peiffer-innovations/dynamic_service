import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';
import 'package:template_expressions/template_expressions.dart';

class WriteStep extends ServiceStep {
  WriteStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'write';
  static final Logger _logger = Logger('WriteStep');

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    var contents = args['contents'];
    var path = Template(
      syntax: context.registry.templateSyntax,
      value: args['path'],
    ).process(context: context.variables);

    var format = JsonClass.parseBool(args['format']);
    var ref = args['\$ref'];

    if (ref != null) {
      contents = await context.registry.loadRef(ref, context: context);
    }

    if (contents is Map || contents is List) {
      try {
        contents = format == true
            ? JsonEncoder.withIndent('  ').convert(contents)
            : json.encode(contents);
      } catch (e, stack) {
        _logger.fine({
          'message': 'Error attempting to JSON encode data',
          'sessionId': context.request.sessionId,
          'requestId': context.request.requestId,
        }, e, stack);
      }
    }

    if (contents is String) {
      contents = process(context, contents);
    }

    await context.registry.write(
      path,
      contents,
      context: context,
      properties: args,
    );
  }
}
