import 'package:crypto/crypto.dart';
import 'package:dynamic_service/dynamic_service.dart';

class ETagStep extends ServiceStep {
  ETagStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'etag';

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    var body = context.response.body;
    var hash = sha256.convert(body).toString();

    context.response.headers['etag'] = hash;
    if (hash == context.request.headers['if-none-match']) {
      context.response.body = const [];
      context.response.status = 204;
    }
  }
}
