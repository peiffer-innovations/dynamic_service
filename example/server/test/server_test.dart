// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rest_client/rest_client.dart';
import 'package:test/test.dart';

Future<void> main() async {
  const kPort = '8081';

  group('server', () {
    var client = Client();
    late Process process;

    setUpAll(() async {
      process = await Process.start('dart', [
        'bin/server.dart',
        '--port',
        kPort,
      ]);
      process.stderr.listen((event) => print('${utf8.decode(event)}'));
      process.stdout.listen((event) => print('${utf8.decode(event)}'));

      var connected = false;

      var maxAttempts = 20;
      for (var i = 1; i <= maxAttempts; i++) {
        await Future.delayed(Duration(seconds: 1));

        print('Waiting for server to start up: [$i/$maxAttempts]...');
        try {
          var res = await client.execute(
            request: Request(
              url: 'http://localhost:$kPort/health-check',
            ),
          );

          if (res.statusCode == 204) {
            connected = true;
            break;
          } else {
            throw Exception();
          }
        } catch (_) {
          // fail
        }
      }

      if (connected == true) {
        print('Connection established, server is online');
      } else {
        throw Exception('Timeout attempting to connect to the server');
      }
    });

    tearDownAll(() {
      process.kill(ProcessSignal.sigint);
    });

    test('hello', () async {
      var req = Request(url: 'http://localhost:$kPort/hello');
      var res = await client.execute(request: req);

      expect(res.body, 'Hello World!');
      expect(res.headers['content-type'], 'text/plain');
      expect(res.statusCode, 200);
    });

    test('goodbye', () async {
      var req = Request(url: 'http://localhost:$kPort/goodbye');
      var res = await client.execute(request: req);

      expect(res.body, 'Goodbye Cruel World!!!');
      expect(res.headers['content-type'], 'text/plain');
      expect(res.statusCode, 200);
    });

    test('get_greeting_regex', () async {
      var req = Request(url: 'http://localhost:$kPort/greeting/regex/Jane/Doe');
      var res = await client.execute(request: req);

      expect(res.body, 'Hi Jane Doe');
      expect(res.headers['content-type'], 'text/plain');
      expect(res.statusCode, 200);
    });

    test('get_greeting_simple', () async {
      var req =
          Request(url: 'http://localhost:$kPort/greeting/simple/John/Doe');
      var res = await client.execute(request: req);

      expect(res.body, 'Hello John Doe');
      expect(res.headers['content-type'], 'text/plain');
      expect(res.statusCode, 200);
    });

    test('timestamp', () async {
      var req = Request(url: 'http://localhost:$kPort/now');
      var now = DateTime.now().millisecondsSinceEpoch;
      var res = await client.execute(request: req);

      var utc = DateTime.parse(res.body['utc']);
      expect(utc.isUtc, true);
      expect((utc.millisecondsSinceEpoch - now).abs(), lessThanOrEqualTo(1000));

      expect(res.headers['content-type'], 'application/json');
      expect(res.statusCode, 200);
    });

    test('name_generator_*', () async {
      const endpoints = [
        'http://localhost:$kPort/generate-name/network',
        'http://localhost:$kPort/generate-name/network/yaml',
        'http://localhost:$kPort/generate-name/local',
      ];
      for (var url in endpoints) {
        var req = Request(url: url);
        var res = await client.execute(request: req);

        var firstName = res.body['firstName'];
        var lastName = res.body['lastName'];

        expect(res.headers['content-type'], 'application/json');
        expect(res.statusCode, 200);

        var diff = false;
        // While this cannot GUARANTEE that the generator creates a truly random
        // name each call, it is fair to say running it 5 times SHOULD give us at
        // least one different name if things are working properly.
        for (var i = 0; i < 5; i++) {
          res = await client.execute(request: req);

          expect(res.headers['content-type'], 'application/json');
          expect(res.statusCode, 200);
          if (res.body['firstName'] != firstName ||
              res.body['lastName'] != lastName) {
            diff = true;
            break;
          }
        }

        if (!diff) {
          throw Exception(
            'After 5 executions, the names were the same each time. Failing!',
          );
        }
      }
    });

    test('weather', () async {
      var req = Request(url: 'http://localhost:$kPort/weather');
      var res = await client.execute(
        request: req,
        jsonResponse: false,
      );

      expect(res.headers['content-type'], 'image/svg+xml');
      expect(res.statusCode, 200);
    });

    test('mountain', () async {
      var req = Request(url: 'http://localhost:$kPort/mountain');
      var res = await client.execute(
        request: req,
        jsonResponse: false,
      );

      expect(res.headers['content-type'], 'image/jpeg');
      expect(res.statusCode, 200);
    });

    test('mountain_network', () async {
      var req = Request(url: 'http://localhost:$kPort/mountain/network');
      var res = await client.execute(
        request: req,
        jsonResponse: false,
      );

      expect(res.headers['content-type'], 'image/jpeg');
      expect(res.statusCode, 200);
    });

    test('post_greeting_list', () async {
      var req = Request(
        body: json.encode({
          'name': {
            'first': 'George',
            'last': 'Washington',
          }
        }),
        method: RequestMethod.post,
        url: 'http://localhost:$kPort/greeting/list',
      );
      var res = await client.execute(
        request: req,
        jsonResponse: false,
      );

      expect(utf8.decode(res.body), 'Howdy George Washington');
      expect(res.headers['content-type'], 'text/plain');
      expect(res.statusCode, 200);
    });

    test('post_greeting_string', () async {
      var req = Request(
        body: json.encode({
          'name': {
            'first': 'Thomas',
            'last': 'Jefferson',
          }
        }),
        method: RequestMethod.post,
        url: 'http://localhost:$kPort/greeting/string',
      );
      var res = await client.execute(
        request: req,
        jsonResponse: false,
      );

      expect(utf8.decode(res.body), 'Yo Thomas Jefferson');
      expect(res.headers['content-type'], 'text/plain');
      expect(res.statusCode, 200);
    });
  }, timeout: const Timeout(Duration(seconds: 10)));
}
