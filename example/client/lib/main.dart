import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rest_client/rest_client.dart';

final _localhost = kIsWeb
    ? 'localhost'
    : Platform.isAndroid
        ? '10.0.2.2'
        : 'localhost';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Client',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> _addressFormKey = GlobalKey<FormState>();

  String _address = 'http://$_localhost:8080';

  Future<void> _execute(
    Request request, {
    bool jsonResponse = true,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ShowResponsePage(
          jsonResponse: jsonResponse,
          request: request,
          uri: request.url,
        ),
      ),
    );
  }

  Future<Map<String, String>> _getInput(Map<String, String> values) async {
    var widgets = <Widget>[];
    for (var entry in values.entries) {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          decoration: InputDecoration(
            label: Text(entry.key),
          ),
          initialValue: entry.value,
          onChanged: (value) => values[entry.key] = value,
        ),
      ));
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_address),
            child: const Text('OK'),
          ),
        ],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        ),
      ),
    );

    return values;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Service Tester'),
        ),
        body: ListView(
          children: [
            ListTile(
              onTap: () async {
                var controller = TextEditingController(text: _address);
                try {
                  _address = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(_address),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (_addressFormKey.currentState?.validate() ==
                                true) {
                              Navigator.of(context).pop(controller.text);
                            }
                          },
                          child: const Text('OK'),
                        ),
                      ],
                      content: Form(
                        key: _addressFormKey,
                        child: TextFormField(
                          autovalidateMode: AutovalidateMode.always,
                          controller: controller,
                          decoration: const InputDecoration(
                            label: Text('URI'),
                          ),
                          validator: (value) =>
                              Uri.tryParse(value ?? '') == null
                                  ? 'Invalid URI'
                                  : null,
                        ),
                      ),
                    ),
                  );
                } finally {
                  controller.dispose();
                  setState(() {});
                }
              },
              title: Text(_address),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/health-check'),
              ),
              title: const Text('health-check'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/hello'),
              ),
              title: const Text('hello'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/goodbye'),
              ),
              title: const Text('goodbye'),
            ),
            ListTile(
              onTap: () async {
                var inputs = await _getInput({
                  'First Name': 'John',
                  'Last Name': 'Doe',
                });
                _execute(
                  Request(
                    url:
                        '$_address/greeting/regex/${inputs['First Name']}/${inputs['Last Name']}',
                  ),
                );
              },
              title: const Text('get_greeting_regex'),
            ),
            ListTile(
              onTap: () async {
                var inputs = await _getInput({
                  'First Name': 'John',
                  'Last Name': 'Doe',
                });
                _execute(
                  Request(
                    url:
                        '$_address/greeting/simple/${inputs['First Name']}/${inputs['Last Name']}',
                  ),
                );
              },
              title: const Text('get_greeting_simple'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/now'),
              ),
              title: const Text('timestamp'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/generate-name/network'),
              ),
              title: const Text('name_generator_network'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/generate-name/network/yaml'),
              ),
              title: const Text('name_generator_network_yaml'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/generate-name/local'),
              ),
              title: const Text('name_generator_local'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/weather'),
                jsonResponse: false,
              ),
              title: const Text('weather'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/mountain'),
                jsonResponse: false,
              ),
              title: const Text('mountain'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/mountain/network'),
                jsonResponse: false,
              ),
              title: const Text('mountain_network'),
            ),
            ListTile(
              onTap: () async {
                var inputs = await _getInput({
                  'First Name': 'John',
                  'Last Name': 'Doe',
                });
                _execute(
                  Request(
                    body: json.encode({
                      'name': {
                        'first': inputs['First Name'],
                        'last': inputs['Last Name'],
                      },
                    }),
                    method: RequestMethod.post,
                    url: '$_address/greeting/list',
                  ),
                );
              },
              title: const Text('post_greeting_list'),
            ),
            ListTile(
              onTap: () async {
                var inputs = await _getInput({
                  'First Name': 'John',
                  'Last Name': 'Doe',
                });
                _execute(
                  Request(
                    body: json.encode({
                      'name': {
                        'first': inputs['First Name'],
                        'last': inputs['Last Name'],
                      },
                    }),
                    method: RequestMethod.post,
                    url: '$_address/greeting/string',
                  ),
                );
              },
              title: const Text('post_greeting_string'),
            ),
            ListTile(
              onTap: () async {
                var inputs = await _getInput({
                  'First Name': 'John',
                  'Last Name': 'Doe',
                });
                _execute(
                  Request(
                    body: json.encode({
                      'name': {
                        'first': inputs['First Name'],
                        'last': inputs['Last Name'],
                      },
                    }),
                    method: RequestMethod.post,
                    url: '$_address/greeting/map',
                  ),
                );
              },
              title: const Text('post_greeting_map'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/user/inline/jane'),
                jsonResponse: false,
              ),
              title: const Text('user_inline_jane'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/user/inline/john'),
                jsonResponse: false,
              ),
              title: const Text('user_inline_john'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/user/jane'),
                jsonResponse: false,
              ),
              title: const Text('user_body_jane'),
            ),
            ListTile(
              onTap: () => _execute(
                Request(url: '$_address/user/john'),
                jsonResponse: false,
              ),
              title: const Text('user_body_john'),
            ),
            ListTile(
              onTap: () async {
                var inputs = await _getInput({
                  'First Name': 'John',
                  'Last Name': 'Doe',
                });
                _execute(
                  Request(
                    body: json.encode({
                      'name': {
                        'first': inputs['First Name'],
                        'last': inputs['Last Name'],
                      },
                    }),
                    method: RequestMethod.put,
                    url: '$_address/user',
                  ),
                );
              },
              title: const Text('write_user'),
            ),
            ListTile(
              onTap: () async {
                var inputs = await _getInput({
                  'First Name': 'John',
                  'Last Name': 'Doe',
                });
                _execute(
                  Request(
                    url:
                        '$_address/user/${inputs['First Name']}/${inputs['Last Name']}',
                  ),
                );
              },
              title: const Text('get_user'),
            ),
            ListTile(
              onTap: () async {
                var inputs = await _getInput({
                  'Message': 'Hello World!',
                });
                _execute(
                  Request(
                    body: inputs['Message'],
                    url: '$_address/for_each/array',
                  ),
                  jsonResponse: false,
                );
              },
              title: const Text('for_each_array'),
            ),
            ListTile(
              onTap: () async {
                var inputs = await _getInput({
                  'Message': 'Hello Parallel World!',
                });
                _execute(
                  Request(
                    body: inputs['Message'],
                    url: '$_address/for_each/array/parallel',
                  ),
                  jsonResponse: false,
                );
              },
              title: const Text('for_each_array_parallel'),
            ),
          ],
        ),
      );
}

class _ShowResponsePage extends StatefulWidget {
  const _ShowResponsePage({
    required this.jsonResponse,
    Key? key,
    required this.request,
    required this.uri,
  }) : super(key: key);

  final bool jsonResponse;
  final Request request;
  final String uri;

  @override
  _ShowResponsePageState createState() => _ShowResponsePageState();
}

class _ShowResponsePageState extends State<_ShowResponsePage> {
  final Client _client = Client();
  Response? _response;

  int _executionTime = 0;

  @override
  void initState() {
    super.initState();

    _execute(widget.request, jsonResponse: widget.jsonResponse);
  }

  void _copyToClipboard(String data) {
    Clipboard.setData(
      ClipboardData(text: data),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('COPIED TO CLIPBOARD'),
      ),
    );
  }

  Future<void> _execute(
    Request request, {
    bool jsonResponse = true,
  }) async {
    _response = null;
    if (mounted == true) {
      setState(() {});
    }

    var start = DateTime.now();
    Response? response;
    try {
      response = await _client.execute(
        jsonResponse: jsonResponse,
        request: request,
      );
    } catch (e) {
      if (e is RestException) {
        response = e.response;
      }
      debugPrint('$e');
    }

    if (response == null) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('DISMISS'),
              ),
            ],
            content: const Text(
              'An error occurred when atempting to call the API',
            ),
            title: const Text('Error'),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(null);
      }
    } else {
      _executionTime =
          DateTime.now().millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      _response = response;
      if (mounted == true) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result;
    var headers = '';

    var response = _response;

    if (response == null) {
      result = Scaffold(
        appBar: AppBar(title: const Text('Response')),
        body: const Center(child: CircularProgressIndicator()),
      );
    } else {
      response.headers.forEach((key, value) => headers += '$key: $value\n');

      Widget body;
      var contentType = response.headers['content-type'];
      try {
        if (contentType == 'image/svg+xml') {
          body = SvgPicture.memory(response.body);
        } else if (contentType == 'text/plain') {
          body = ListTile(
            onLongPress: kIsWeb
                ? null
                : () => _copyToClipboard(response.body?.toString() ?? ''),
            subtitle: Text(response.body?.toString() ?? ''),
            title: const Text('Body'),
          );
        } else if (contentType?.startsWith('image/') == true) {
          body = Image.memory(response.body);
        } else {
          body = ListTile(
            onLongPress: kIsWeb
                ? null
                : () => _copyToClipboard(
                      const JsonEncoder.withIndent('  ').convert(response.body),
                    ),
            subtitle: Text(
              const JsonEncoder.withIndent('  ').convert(response.body),
            ),
            title: const Text('Body'),
          );
        }
      } catch (e) {
        body = ListTile(
          subtitle: Text(response.body?.toString() ?? ''),
          title: const Text('Body'),
        );
      }

      result = Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                _execute(
                  widget.request,
                  jsonResponse: widget.jsonResponse,
                );
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
          title: const Text('Response'),
        ),
        body: ListView(
          children: [
            ListTile(
              subtitle: Text(widget.uri),
              title: Text('URI [${_executionTime / 1000.0}s]'),
            ),
            ListTile(
              subtitle: Text('${response.statusCode}'),
              title: const Text('Status'),
            ),
            if (headers.isNotEmpty)
              ListTile(
                subtitle: Text(headers),
                title: const Text('Headers'),
              ),
            body,
          ],
        ),
      );
    }

    return result;
  }
}
