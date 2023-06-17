import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_schema2/json_schema.dart';
import 'package:yaon/yaon.dart';

class ValidateSchemaStep extends ServiceStep {
  ValidateSchemaStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'validate_schema';

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    var schema = args['schema'];
    final content = process(context, args['content']);

    if (schema is String) {
      schema = yaon.parse(schema);
    }
    if (schema is Map && schema[r'$ref'] != null) {
      schema = await context.registry.loadRef(schema[r'$ref']);
    }

    if (schema == null) {
      throw ServiceException(
        body: '[$kType]: Required parameter: [schema] is null.',
      );
    }
    if (content == null) {
      throw ServiceException(
        body: '[$kType]: Required parameter: [content] is null.',
      );
    }

    final vResult = JsonSchema.create(schema).validate(
      yaon.parse(content),
    );
    if (vResult.errors.isNotEmpty == true) {
      var errorStr = 'Schema Error: \n';
      for (var error in vResult.errors) {
        errorStr += ' * [${error.schemaPath}]: ${error.message}\n';
      }

      throw ServiceException(
        body: errorStr,
        code: 400,
      );
    }
  }
}
