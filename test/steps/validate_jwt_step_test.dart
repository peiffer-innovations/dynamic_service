import 'package:dynamic_service/dynamic_service.dart';
import 'package:test/test.dart';

void main() {
  test('validate_jwt', () async {
    var token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.RTcxqcHQ6-HbkEP1RXbyC1bFJatl0zmvRTRWLVG7v0U';

    var request = ServiceRequest(
      body: const [],
      headers: {
        'authorization': token,
      },
      method: 'GET',
      path: '/test',
      query: {},
    );
    var context = ServiceContext(
      registry: DynamicServiceRegistry.defaultInstance,
      request: request,
      response: ServiceResponse(),
      variables: {
        'request': request.toJson(),
        'key': _hmacSecret,
      },
    );
    var step = ValidateJwtStep(args: {
      'key': r'${base64.encode(utf8.encode(key))}',
      'token': r"${request['headers']['authorization']}",
    });

    await step.execute(context);
  });
}

const _hmacSecret = 'DvVcM6We2tXxTCr9vmZWKMEBbPfG2j5j';
