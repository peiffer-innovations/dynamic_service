import 'package:json_class/json_class.dart';

class ServiceCriteria extends JsonClass {
  ServiceCriteria({
    this.body,
    this.headers,
    String? method,
    String? path,
  })  : method = method ?? '(DELETE|GET|PATCH|POST|PUT)',
        path = path ?? '.*';

  final dynamic body;
  final dynamic headers;
  final String method;
  final String path;

  static ServiceCriteria? fromDynamic(dynamic map) {
    ServiceCriteria? result;

    if (map != null) {
      result = ServiceCriteria(
        body: map['body'],
        headers: map['headers'],
        method: map['method'],
        path: map['path'],
      );
    }

    return result;
  }

  @override
  Map<String, dynamic> toJson() => {
        'body': body,
        'headers': headers,
        'method': method,
        'path': path,
      };
}
