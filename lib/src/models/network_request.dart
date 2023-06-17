import 'package:json_class/json_class.dart';
import 'package:yaon/yaon.dart';

class NetworkRequest extends JsonClass {
  NetworkRequest({
    required this.body,
    required this.delay,
    required this.headers,
    required String? method,
    required this.url,
    required this.variable,
  }) : method = (method ?? (body.isEmpty ? 'GET' : 'POST')).toUpperCase();

  String body;
  Duration delay;
  Map<String, String> headers;
  String method;
  String url;
  String variable;

  static NetworkRequest fromDynamic(
    dynamic map, {
    required String defaultVariable,
  }) {
    var body = map['body'] ?? '';

    if (body is! String) {
      try {
        body = yaon.parse(body);
      } catch (e) {
        body = body.toString();
      }
    }

    return NetworkRequest(
      body: body,
      delay: Duration(milliseconds: JsonClass.parseInt(map['delay']) ?? 0),
      headers: Map<String, String>.from(map['headers'] ?? <String, String>{}),
      method: map['method'],
      url: map['url'] ?? map['uri'],
      variable: map['variable'] ?? defaultVariable,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'body': body,
        'delay': delay,
        'headers': headers,
        'method': method,
        'url': url,
        'variable': variable,
      };
}
