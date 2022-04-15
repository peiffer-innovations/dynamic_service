import 'package:json_class/json_class.dart';

class ServiceException extends JsonClass implements Exception {
  ServiceException({
    this.body,
    this.cause,
    this.code = 500,
    this.stack,
  });

  final String? body;
  final Object? cause;
  final int code;
  final StackTrace? stack;

  @override
  Map<String, dynamic> toJson() => {
        'body': body,
        'cause': cause?.toString(),
        'code': code,
      };
}
