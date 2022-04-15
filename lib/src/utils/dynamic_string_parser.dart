import 'package:dynamic_service/dynamic_service.dart';
import 'package:logging/logging.dart';
import 'package:yaon/yaon.dart' as yaon;

/// Dynamic string parser that can process either YAML or JSON.
class DynamicStringParser {
  static final Logger _logger = Logger('DynamicStringParser');

  /// Parses the [data] into a result YAML or JSON result.  If neither
  /// successfully parses the data, this will return the [data] as it was passed
  /// in.
  static dynamic parse(String data, {ServiceContext? context}) {
    dynamic result = data;

    try {
      result = yaon.parse(data);
    } catch (e, stack) {
      _logger.info({
        'message': 'Unable to parse: [$data]',
        'sessionId': context?.request.sessionId ?? '<internal>',
        'requestId': context?.request.requestId ?? '<internal>',
      }, e, stack);
    }

    return result;
  }
}
