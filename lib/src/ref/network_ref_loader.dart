import 'dart:convert';

import 'package:dynamic_service/dynamic_service.dart';
import 'package:rest_client/rest_client.dart';

class NetworkRefLoader extends RefLoader {
  NetworkRefLoader({
    Authorizer? authorizer,
    Client? client,
    String? urls,
  })  : _authorizer = authorizer,
        _client = client ?? Client(),
        _urls = RegExp(urls ?? r'^(http|https)://.*');

  final Authorizer? _authorizer;
  final Client _client;
  final RegExp _urls;

  @override
  bool canLoad(String ref) => _urls.hasMatch(ref);

  @override
  Future<dynamic> load(
    String ref, {
    required DynamicServiceRegistry registry,
  }) async {
    var request = Request(url: ref);

    try {
      var response = await _client.execute(
        authorizer: _authorizer,
        jsonResponse: false,
        request: request,
      );
      return DynamicStringParser.parse(utf8.decode(response.body));
    } catch (e) {
      throw ServiceException(
        body: '[NetworkRefLoader]: error loading url: [$ref]',
        cause: e,
      );
    }
  }
}
