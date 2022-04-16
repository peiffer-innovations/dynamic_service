import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:jose/jose.dart';

class JwtUtils {
  static String create(JwtArgs args) {
    var builder = JsonWebSignatureBuilder();

    var claims = _buildClaims(
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
    String? keyId,
  }) async {
    var parts = token.split('.');
    if (parts.length != 3) {
      throw ServiceException(
        body: '[JwtUtils]: Invalid token; [3] != [${parts.length}]',
        code: 401,
      );
    }

    var header = json.decode(utf8.decode(base64.decode(parts[0])));
    var jwt = JsonWebToken.unverified(parts.join('.'));

    JsonWebKey jwk;
    var alg = header['alg'];

    switch (alg) {
      case 'HS256':
        jwk = JsonWebKey.fromJson({
          if (keyId != null) 'kid': keyId,
          'kty': 'oct',
          'k': key,
        });
        break;

      case 'RS256':
        jwk = JsonWebKey.fromPem(key, keyId: keyId);
        break;

      default:
        throw ServiceException(
          body: '[JwtUtils]: unsupported algorithm [${alg}]',
          code: 401,
        );
    }

    var keyStore = JsonWebKeyStore()..addKey(jwk);
    var verified = await jwt.verify(keyStore);

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
    var tokenJson = {
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
}
