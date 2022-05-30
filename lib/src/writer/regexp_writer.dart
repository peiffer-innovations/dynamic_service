import 'package:dynamic_service/dynamic_service.dart';

abstract class RegExpWriter extends Writer {
  RegExpWriter({
    required RegExp regExp,
  }) : _regExp = regExp;

  final RegExp _regExp;

  @override
  bool canWrite(String ref) => _regExp.hasMatch(ref);
}
