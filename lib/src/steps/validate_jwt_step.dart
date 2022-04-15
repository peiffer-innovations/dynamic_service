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
    var token = args['token'];
    var key = args['key']?.toString();

    if (key == null) {
      throw ServiceException(
        code: 401,
        body: 'Missing JWT key',
      );
    }

    var jwt = await JwtUtils.validate(token, key: key);

    context.variables[args['variable'] ?? 'token'] = jwt.claims.toJson();
  }
}
