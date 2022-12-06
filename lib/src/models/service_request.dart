import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:json_class/json_class.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

class ServiceRequest extends JsonClass {
  factory ServiceRequest({
    required List<int> body,
    required Map<String, String> headers,
    required String method,
    required String path,
    required Map<String, String> query,
  }) =>
      ServiceRequest._internal(
        body: body,
        headers: CanonicalizedMap<String, String, String>.from(
          headers,
          (value) => value.toString().toLowerCase(),
        ),
        method: method,
        path: path,
        query: query,
      );

  ServiceRequest._internal({
    required this.body,
    required this.headers,
    required String method,
    required this.path,
    required this.query,
  })  : method = method.toUpperCase(),
        requestId = headers[kHeaderRequestId] ?? const Uuid().v4(),
        sessionId = headers[kHeaderSessionId] ?? const Uuid().v4();

  static const kHeaderRequestId = 'x-request-id';
  static const kHeaderSessionId = 'x-session-id';
  static const kUnlimitedBodySize = -1;

  final List<int> body;
  final CanonicalizedMap<String, String, String> headers;
  final String method;
  final String path;
  final Map<String, String> query;
  final String requestId;
  final String sessionId;

  Map<String, dynamic>? _json;

  static Future<ServiceRequest> fromRequest(Request request) async =>
      ServiceRequest(
        body: await request.read().fold(
            <int>[],
            (List<int> buffer, data) =>
                buffer..addAll(data)).then((value) => value),
        headers: request.headers,
        method: request.method,
        path: request.requestedUri.path,
        query: request.url.queryParameters,
      );

  String get bodyAsString {
    var result = '';

    try {
      result = utf8.decode(body);
    } catch (e) {
      // no-op
    }

    return result;
  }

  @override
  Map<String, dynamic> toJson({
    int maxBodySize = -1,
    Iterable<String> sensitiveHeaders = const {
      'authorization',
      'x-authorization',
    },
  }) {
    var result = _json;

    if (result == null) {
      assert(maxBodySize >= -1);
      final headers = Map<String, String>.from(this.headers);

      for (var h in sensitiveHeaders) {
        headers[h] = '***';
      }

      result = <String, dynamic>{
        'headers': headers,
        'method': method,
        'path': path,
        'query': query,
        'requestId': requestId,
        'sessionId': sessionId,
      };

      if (maxBodySize != 0) {
        var body = '';

        if (this.body.isNotEmpty) {
          final bodyStr = bodyAsString;
          if (bodyStr.isNotEmpty) {
            body = bodyStr;
            try {
              final bodyJson = json.decode(bodyStr);
              body = bodyJson;
            } catch (e) {
              // no-op
            }
          }
        }
        if (maxBodySize != kUnlimitedBodySize && maxBodySize < body.length) {
          body = '${body.substring(0, maxBodySize)}...';
        }
        result['body'] = body;
      }

      _json = result;
    }

    return result;
  }
}
