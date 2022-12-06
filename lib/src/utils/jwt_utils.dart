import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:jose/jose.dart';
import 'package:x509/x509.dart';

class JwtUtils {
  static String create(JwtArgs args) {
    final builder = JsonWebSignatureBuilder();

    final claims = _buildClaims(
      claims: args.claims,
      expires: args.expires,
    );

    builder.jsonContent = claims.toJson();

    switch (args.keyType) {
      case 'HS256':
        builder.addRecipient(
          JsonWebKey.fromJson({
            'k': args.key,
            if (args.keyId != null) 'kid': args.keyId,
            'kty': 'oct',
          }),
          algorithm: 'HS256',
        );
        break;

      case 'RS256':
        builder.addRecipient(
          JsonWebKey.fromPem(args.key),
          algorithm: 'RS256',
        );
        break;

      default:
    }

    return builder.build().toCompactSerialization();
  }

  static Future<JsonWebToken> validate(
    String token, {
    required String key,
  }) async {
    final parts = token.split('.');

    if (parts.length != 3) {
      throw ServiceException(
        body: '[JwtUtils]: Invalid token; [3] != [${parts.length}]',
        code: 401,
      );
    }

    final header =
        json.decode(utf8.decode(_decodeBase64EncodedBytes(parts[0])));
    final jwt = JsonWebToken.unverified(token);

    if ((jwt.claims.expiry?.millisecondsSinceEpoch ?? 0) <
        DateTime.now().millisecondsSinceEpoch) {
      throw ServiceException(
        code: 403,
        body: 'Token is expired',
      );
    }

    JsonWebKey jwk;
    final alg = header['alg'];
    final keyId = header['kid'];

    switch (alg) {
      case 'HS256':
        jwk = JsonWebKey.fromJson({
          if (keyId != null) 'kid': keyId,
          'kty': 'oct',
          'k': key,
        });
        break;

      case 'RS256':
        final pk = parsePem(key).first;
        jwk = JsonWebKey.rsa(
          exponent: pk.exponent,
          keyId: keyId,
          modulus: pk.modulus,
        );
        break;

      default:
        throw ServiceException(
          body: '[JwtUtils]: unsupported algorithm [${alg}]',
          code: 401,
        );
    }

    final keyStore = JsonWebKeyStore()..addKey(jwk);
    final verified = await jwt.verify(keyStore);

    if (verified != true) {
      throw ServiceException(
        body: '[JwtUtils]: Invalid JWT Signature',
        code: 401,
      );
    }

    return jwt;
  }

  static JsonWebTokenClaims _buildClaims({
    required Map<String, dynamic> claims,
    required Duration expires,
  }) {
    final tokenJson = {
      ...claims,
      'exp': Duration(
        milliseconds:
            DateTime.now().millisecondsSinceEpoch + expires.inMilliseconds,
      ).inSeconds,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    for (var entry in claims.entries) {
      tokenJson[entry.key] = entry.value;
    }

    return JsonWebTokenClaims.fromJson(tokenJson);
  }

  static List<int> _decodeBase64EncodedBytes(String encodedString) =>
      base64Url.decode(encodedString +
          List.filled((4 - encodedString.length % 4) % 4, '=').join());
}
