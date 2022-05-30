import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';

class JwtArgs {
  JwtArgs({
    required this.claims,
    required this.expires,
    required this.key,
    this.keyId,
    required this.keyType,
  });

  final Map<String, dynamic> claims;
  final Duration expires;
  final String key;
  final String? keyId;
  final String keyType;

  static JwtArgs fromDynamic(dynamic map) {
    if (map == null) {
      throw ServiceException(
        body: '[JwtUtils]: missing args for the JWT',
      );
    }

    var key = map['key']?.toString();
    var keyId = (map['keyId'] ?? map['key-id'] ?? 'key0').toString();
    var keyType = (map['keyType'] ?? map['key-type'])?.toString();

    if (key == null || key.isEmpty) {
      throw ServiceException(
        body: '[JwtUtils]: missing "key" arg from the JWT',
      );
    }
    if (keyType == null || keyType.isEmpty) {
      throw ServiceException(
        body: '[JwtUtils]: missing "keyType"/"key-type" arg from the JWT',
      );
    } else if (keyType != 'HS256' && keyType != 'RS256') {
      throw ServiceException(
        body:
            '[JwtUtils]: invalid "keyType"/"key-type" arg from the JWT: [${keyType}]',
      );
    }

    return JwtArgs(
      claims: map['claims'],
      expires: JsonClass.parseDurationFromSeconds(map['expires']) ??
          const Duration(minutes: 30),
      key: key,
      keyType: keyType,
      keyId: keyId,
    );
  }
}
