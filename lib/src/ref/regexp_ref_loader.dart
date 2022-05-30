import 'package:dynamic_service/dynamic_service.dart';

abstract class RegExpRefLoader extends RefLoader {
  RegExpRefLoader({
    required RegExp regExp,
  }) : _regExp = regExp;

  final RegExp _regExp;

  @override
  bool canLoad(String ref) => _regExp.hasMatch(ref);
}
