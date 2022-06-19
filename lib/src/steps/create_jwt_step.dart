import 'package:dynamic_service/dynamic_service.dart';

class CreateJwtStep extends ServiceStep {
  CreateJwtStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'create_jwt';

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    for (var entry in args.entries) {
      var value = <String, dynamic>{};
      entry.value.forEach((k, v) => value[k] = process(context, v));

      // var value = process(context, entry.value)!;
      var jwtArgs = JwtArgs.fromDynamic(value);

      var jwt = JwtUtils.create(jwtArgs);

      context.variables[entry.key] = jwt;
    }
  }
}
