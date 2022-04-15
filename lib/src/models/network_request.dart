import 'dart:convert';

import 'package:json_class/json_class.dart';

class NetworkRequest extends JsonClass {
  NetworkRequest({
    required this.body,
    required this.delay,
    required this.headers,
    required this.id,
    required String? method,
    required this.processBody,
    required this.url,
  }) : method = (method ?? (body.isEmpty ? 'GET' : 'POST')).toUpperCase();

  String body;
  Duration delay;
  Map<String, String> headers;
  String id;
  String method;
  bool processBody;
  String url;

  static NetworkRequest fromDynamic(
    dynamic map, {
    required String defaultId,
  }) {
    var body = map['body'] ?? '';

    if (body is! String) {
      try {
        body = json.encode(body);
      } catch (e) {
        body = body.toString();
      }
    }

    return NetworkRequest(
      body: body,
      delay: Duration(milliseconds: JsonClass.parseInt(map['delay']) ?? 0),
      headers: Map<String, String>.from(map['headers'] ?? <String, String>{}),
      id: map['id'] ?? defaultId,
      method: map['method'],
      processBody: JsonClass.parseBool(map['processBody'], whenNull: true),
      url: map['url'] ?? map['uri'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'body': body,
        'delay': delay,
        'headers': headers,
        'method': method,
        'processBody': processBody,
        'url': url,
      };
}
