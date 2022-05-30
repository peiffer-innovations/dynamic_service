import 'package:dynamic_service/dynamic_service.dart';

abstract class Writer {
  bool canWrite(String ref);

  Future<void> write(
    String target,
    dynamic contents, {
    required ServiceContext context,
    Map<String, dynamic>? properties,
  });
}
