import 'dart:convert';
import 'dart:io';

import 'package:dynamic_service/dynamic_service.dart';
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
    var contents = context.variables['contents'];
    var path = Template(
      syntax: context.registry.templateSyntax,
      value: args['path'],
    ).process(context: context.variables);

    if (path.contains('../') || path.contains('..\\')) {
      throw ServiceException(body: 'Invalid path: [$path]');
    }

    var ref = args['\$ref'];

    if (ref != null) {
      var data = await context.registry.loadRef(ref);

      if (data is Map || data is Iterable) {
        try {
          data = json.encode(data);
        } catch (e, stack) {
          _logger.fine('Error attempting to JSON encode data', e, stack);
        }
      }

      contents = data;
    }

    if (contents is String) {
      contents = Template(
        syntax: context.registry.templateSyntax,
        value: contents,
      ).process(context: context.variables);
    }

    var file = File(path);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    var bytes = contents is String ? utf8.encode(contents) : contents;

    file.writeAsBytesSync(bytes);

    _logger.fine('Wrote file: [${file.path}]');
  }
}
