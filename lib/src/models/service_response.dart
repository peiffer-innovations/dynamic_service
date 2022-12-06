import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:json_class/json_class.dart';
import 'package:shelf/shelf.dart';

class ServiceResponse extends JsonClass {
  final CanonicalizedMap<String, String, String> _headers =
      CanonicalizedMap<String, String, String>(
    (value) => value.toString().toLowerCase(),
  );

  List<int> body = [];
  String contentType = 'application/json';
  int status = 200;

  static ServiceResponse? fromDynamic(dynamic map) {
    ServiceResponse? result;

    if (map != null) {
      result = ServiceResponse();
      result._headers.addAll(map['headers'] ?? {});
      result.body = utf8.encode(map['body'] ?? '');
      result.contentType =
          map['contentType'] ?? map['content-type'] ?? 'application/json';
      result.status = JsonClass.parseInt(map['status'] ?? map['code']) ?? 200;
    }

    return result;
  }

  Map<String, String> get headers {
    _headers['content-type'] = contentType;
    return _headers;
  }

  @override
  Map<String, dynamic> toJson({
    Iterable<String> sensitiveHeaders = const {
      'authorization',
      'x-authorization',
    },
  }) {
    final headers = Map<String, String>.from(this.headers);

    for (var h in sensitiveHeaders) {
      headers[h] = '***';
    }
    headers['content-type'] = contentType;
    final result = {
      'headers': headers,
      'status': status,
    };

    if (body.isNotEmpty) {
      try {
        final bodyStr = utf8.decode(body);
        result['body'] = bodyStr;
        try {
          final bodyJson = json.decode(bodyStr);
          result['body'] = bodyJson;
        } catch (e) {
          // no-op
        }
      } catch (e) {
        // no-op
      }
    }

    return result;
  }

  Response toResponse() => Response(
        status,
        body: body,
        headers: headers,
      );
}
