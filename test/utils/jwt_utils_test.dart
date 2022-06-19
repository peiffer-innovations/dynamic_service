import 'dart:io';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:jose/jose.dart';
import 'package:test/test.dart';

void main() {
  test('hmac', () {});

  test('rsa', () async {
    var publicKey =
        File('example/server/assets/keys/publicKey.pem').readAsStringSync();
    var privateKey =
        File('example/server/assets/keys/privateKey.pem').readAsStringSync();

    var token = JwtUtils.create(JwtArgs(
      claims: {'sub': 'test_user'},
      expires: const Duration(minutes: 10),
      key: privateKey,
      keyType: 'RS256',
      keyId: 'rsa',
    ));

    var jwt = JsonWebToken.unverified(token);
    expect(jwt.claims.subject, 'test_user');

    await JwtUtils.validate(token, key: publicKey);
  });
}
