import 'dart:convert';
import 'dart:io';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:logging/logging.dart';

class FileWriter extends Writer {
  FileWriter({
    this.path = 'output',
    this.protocol = 'output',
  });

  static final Logger _logger = Logger('FileWriter');

  final String path;
  final String protocol;

  @override
  bool canWrite(String ref) => ref.startsWith('$protocol://');

  @override
  Future<void> write(
    String target,
    dynamic contents, {
    required ServiceContext context,
    Map<String, dynamic>? properties,
  }) async {
    var path = target.substring(target.indexOf('://') + 3);
    if (path.startsWith('/')) {
      throw ServiceException(
        body: 'Invalid path: [$path]; only relative paths are supported',
      );
    }

    if (path.contains('../') || path.contains('..\\')) {
      throw ServiceException(body: 'Invalid path: [$path]');
    }

    var file = File('${this.path}/$path');
    if (contents == null) {
      if (file.existsSync()) {
        file.deleteSync();
      }
    } else {
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      var bytes = contents is String ? utf8.encode(contents) : contents;

      file.writeAsBytesSync(bytes);
    }
    _logger.fine({
      'message': 'Wrote file: [${file.path}]',
      'sessionId': context.request.sessionId,
      'requestId': context.request.requestId,
    });
  }
}
