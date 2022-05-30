import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_schema2/json_schema2.dart';
import 'package:yaon/yaon.dart' as yaon;

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
    var content = process(context, args['content']);

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

    var errors = JsonSchema.createSchema(schema).validateWithErrors(
      yaon.parse(content),
    );
    if (errors.isNotEmpty == true) {
      var errorStr = 'Schema Error: \n';
      for (var error in errors) {
        errorStr += ' * [${error.schemaPath}]: ${error.message}\n';
      }

      throw ServiceException(
        body: errorStr,
        code: 400,
      );
    }
  }
}
