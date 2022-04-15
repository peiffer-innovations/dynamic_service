import 'package:dynamic_service/dynamic_service.dart';

abstract class RefLoader {
  bool canLoad(String ref);

  Future<dynamic> load(String ref, {required DynamicServiceRegistry registry});
}
