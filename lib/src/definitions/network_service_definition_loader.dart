import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:logging/logging.dart';
import 'package:rest_client/rest_client.dart';

class NetworkServiceDefinitionLoader extends ServiceDefinitionLoader {
  NetworkServiceDefinitionLoader({
    Authorizer? authorizer,
    Client? client,
    this.ttl = const Duration(minutes: 15),
    required this.url,
  })  : _authorizer = authorizer,
        _client = client ?? Client();

  static final Logger _logger = Logger('NetworkServiceDefinitionLoader');

  final Duration ttl;
  final String url;

  final Authorizer? _authorizer;
  final Client _client;

  String? _etag;

  ServiceDefinition? _serviceDefinition;
  DateTime _updated = DateTime(0);

  @override
  Future<ServiceDefinition> loadServiceDefinition(
    DynamicServiceRegistry registry,
  ) async {
    var now = DateTime.now().millisecondsSinceEpoch;
    var loaded = _updated.millisecondsSinceEpoch;

    var definition = _serviceDefinition;

    if (definition == null || now - ttl.inMilliseconds < loaded) {
      try {
        var response = await _client.execute(
          authorizer: _authorizer,
          jsonResponse: false,
          request: Request(
            headers: {
              'if-none-match': _etag ?? '',
            },
            url: url,
          ),
        );

        if (response.statusCode == 200) {
          _etag = response.headers['etag'];
          var body = DynamicStringParser.parse(utf8.decode(response.body));
          definition = await ServiceDefinition.fromDynamic(
            body,
            registry: registry,
          );
        }

        _updated = DateTime.now();
      } catch (e, stack) {
        _logger.severe('Error loading service definition', e, stack);
      }
    }

    if (definition == null) {
      throw ServiceException(
        body:
            '[NetworkServiceDefinitionLoader]: unable to load definition at: [$url]',
      );
    }

    _serviceDefinition = definition;
    return definition;
  }
}
