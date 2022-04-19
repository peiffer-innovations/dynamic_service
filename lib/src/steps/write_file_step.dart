import 'dart:convert';
import 'dart:io';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';
import 'package:template_expressions/template_expressions.dart';

class WriteFileStep extends ServiceStep {
  WriteFileStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'write_file';
  static final Logger _logger = Logger('WriteFileStep');

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

    if (path.contains('../') || path.contains('..\\')) {
      throw ServiceException(body: 'Invalid path: [$path]');
    }

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

    var file = File(path);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    var bytes = contents is String ? utf8.encode(contents) : contents;

    file.writeAsBytesSync(bytes);

    _logger.fine({
      'message': 'Wrote file: [${file.path}]',
      'sessionId': context.request.sessionId,
      'requestId': context.request.requestId,
    });
  }
}
