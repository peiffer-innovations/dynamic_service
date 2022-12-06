import 'package:dynamic_service/dynamic_service.dart';

class ValidateJwtStep extends ServiceStep {
  ValidateJwtStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'validate_jwt';

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    final key = process(context, args['key']);

    if (key == null) {
      throw ServiceException(
        code: 403,
        body: 'Missing JWT key',
      );
    }

    final token = process(context, args[StandardVariableNames.kNameToken]);
    if (token == null) {
      throw ServiceException(
        code: 403,
        body: 'Missing authorization token',
      );
    }

    final jwt = await JwtUtils.validate(token, key: key);

    context.variables[
        process(context, args[StandardVariableNames.kNameVariable]) ??
            kType] = jwt.claims.toJson();
  }
}
