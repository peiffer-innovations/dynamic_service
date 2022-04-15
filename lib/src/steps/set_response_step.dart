import 'dart:convert';
import 'dart:io';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:template_expressions/template_expressions.dart';

class SetResponseStep extends ServiceStep {
  SetResponseStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'set_response';
  static final Logger _logger = Logger('SetResponseStep');

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    var body = args['body'];
    var contentType = context.response.contentType;

    var ref = args[r'$ref'];
    if (ref == null) {
      var file = args['file'];
      if (file != null) {
        contentType = lookupMimeType(file) ?? contentType;
        body = File(file).readAsBytesSync().toList();
      }
    } else {
      var data = await context.registry.loadRef(ref);

      if (data is Map || data is Iterable) {
        try {
          data = json.encode(data);
        } catch (e, stack) {
          _logger.fine('Error attempting to JSON encode data', e, stack);
        }
      }

      body = data;
    }

    if (body is String) {
      body = Template(
        syntax: context.registry.templateSyntax,
        value: body,
      ).process(context: context.variables);
    }

    context.response.body = body is String ? utf8.encode(body) : body;
    context.response.contentType =
        args['content-type'] ?? args['contentType'] ?? contentType;
    context.response.headers.addAll(
      args['headers'] ?? const <String, String>{},
    );
    context.response.status = JsonClass.parseInt(args['status']) ?? 200;
  }
}
