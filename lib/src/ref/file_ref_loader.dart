import 'dart:convert';
import 'dart:io';

import 'package:dynamic_service/dynamic_service.dart';

class FileRefLoader extends RefLoader {
  FileRefLoader({
    this.protocol = 'assets',
  });

  final String protocol;

  @override
  bool canLoad(String ref) => ref.startsWith('$protocol://');

  @override
  Future<dynamic> load(
    String ref, {
    required DynamicServiceRegistry registry,
  }) async {
    if (ref.contains('../') || ref.contains('..\\')) {
      throw ServiceException(body: 'Invalid ref: [$ref]');
    }

    var file = File('$protocol/${ref.substring(ref.indexOf('://') + 3)}');

    if (!file.existsSync()) {
      throw ServiceException(
        body: '[FileRefLoader]: error loading asset: [${file.absolute.path}]',
      );
    }

    dynamic data = file.readAsBytesSync();

    try {
      data = utf8.decode(data);
    } catch (e) {
      // no-op
    }

    return data is String ? DynamicStringParser.parse(data) : data;
  }
}
