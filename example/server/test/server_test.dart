// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:jose/jose.dart';
import 'package:rest_client/rest_client.dart';
import 'package:test/test.dart';

Future<void> main() async {
  const kPort = '8081';

  group('server', () {
    final client = Client();
    late Process process;

    setUpAll(() async {
      process = await Process.start('dart', [
        'bin/server.dart',
        '--port',
        kPort,
      ]);
      process.stderr.listen((event) => print('${utf8.decode(event)}'));
      process.stdout.listen((event) => stderr.write('${utf8.decode(event)}'));

      var connected = false;

      final maxAttempts = 20;
      for (var i = 1; i <= maxAttempts; i++) {
        await Future.delayed(const Duration(seconds: 1));

        print('Waiting for server to start up: [$i/$maxAttempts]...');
        try {
          final res = await client.execute(
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

    group('root', () {
      test('health-check', () async {
        final req = Request(url: 'http://localhost:$kPort/health-check');
        final res = await client.execute(request: req);

        expect(res.statusCode, 204);
      });

      test('hello', () async {
        final req = Request(url: 'http://localhost:$kPort/hello');
        final res = await client.execute(request: req);

        expect(res.body, 'Hello World!');
        expect(res.headers['content-type'], 'text/plain');
        expect(res.statusCode, 200);
      });

      test('goodbye', () async {
        final req = Request(url: 'http://localhost:$kPort/goodbye');
        final res = await client.execute(request: req);

        expect(res.body, 'Goodbye Cruel World!!!');
        expect(res.headers['content-type'], 'text/plain');
        expect(res.statusCode, 200);
      });

      test('timestamp', () async {
        final req = Request(url: 'http://localhost:$kPort/now');
        final now = DateTime.now().millisecondsSinceEpoch;
        final res = await client.execute(request: req);

        final utc = DateTime.parse(res.body['utc']);
        expect(utc.isUtc, true);
        expect(
            (utc.millisecondsSinceEpoch - now).abs(), lessThanOrEqualTo(1000));

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
          final req = Request(url: url);
          var res = await client.execute(request: req);

          final firstName = res.body['firstName'];
          final lastName = res.body['lastName'];

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
              'After 5 executions, the names were the same each time. Failing!\n$url',
            );
          }
        }
      });

      test('weather', () async {
        final req = Request(url: 'http://localhost:$kPort/weather');
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );

        expect(res.headers['content-type'], 'image/svg+xml');
        expect(res.statusCode, 200);
      });

      test('mountain', () async {
        final req = Request(url: 'http://localhost:$kPort/mountain');
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );

        expect(res.headers['content-type'], 'image/jpeg');
        expect(res.statusCode, 200);
      });

      test('mountain_network', () async {
        final req = Request(url: 'http://localhost:$kPort/mountain/network');
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );

        expect(res.headers['content-type'], 'image/jpeg');
        expect(res.statusCode, 200);
      });

      test('parallel', () async {
        final req = Request(url: 'http://localhost:$kPort/parallel');
        final start = DateTime.now().millisecondsSinceEpoch;
        final res = await client.execute(
          request: req,
        );

        final end = DateTime.now().millisecondsSinceEpoch;
        final delta = end - start;

        expect(delta, lessThan(2000));
        expect(delta, greaterThan(500));

        expect(res.headers['content-type'], 'text/plain');
        expect(res.body, 'done');
        expect(res.statusCode, 200);
      });
    });

    group('for_each', () {
      test('for_each_array', () async {
        final req = Request(
          method: RequestMethod.get,
          url: 'http://localhost:$kPort/for-each/array',
        );

        final startTime = DateTime.now().millisecondsSinceEpoch;
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );
        final endTime = DateTime.now().millisecondsSinceEpoch;

        expect(res.statusCode, 200);

        final total = endTime - startTime;
        expect(total, lessThan(4000));
        expect(total, greaterThan(990));
        expect(res.body.isNotEmpty, true);
      });

      test('for_each_array_parallel', () async {
        final req = Request(
          method: RequestMethod.get,
          url: 'http://localhost:$kPort/for-each/array/parallel',
        );

        final startTime = DateTime.now().millisecondsSinceEpoch;
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );
        final endTime = DateTime.now().millisecondsSinceEpoch;

        expect(res.statusCode, 200);

        final total = endTime - startTime;
        expect(total, lessThan(1000));
        expect(total, greaterThan(90));
        expect(res.body.isNotEmpty, true);
      });

      test('for_each_map', () async {
        final req = Request(
          method: RequestMethod.get,
          url: 'http://localhost:$kPort/for-each/map',
        );

        final startTime = DateTime.now().millisecondsSinceEpoch;
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );
        final endTime = DateTime.now().millisecondsSinceEpoch;

        expect(res.statusCode, 200);

        final total = endTime - startTime;
        expect(total, lessThan(4000));
        expect(total, greaterThan(990));
        expect(res.body.isNotEmpty, true);
      });

      test('for_each_map_parallel', () async {
        final req = Request(
          method: RequestMethod.get,
          url: 'http://localhost:$kPort/for-each/map/parallel',
        );

        final startTime = DateTime.now().millisecondsSinceEpoch;
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );
        final endTime = DateTime.now().millisecondsSinceEpoch;

        expect(res.statusCode, 200);

        final total = endTime - startTime;
        expect(total, lessThan(1000));
        expect(total, greaterThan(90));
        expect(res.body.isNotEmpty, true);
      });
    });

    group('greetings', () {
      test('get_greeting_regex', () async {
        final req = Request(
          url: 'http://localhost:$kPort/greeting/regex/Jane/Doe',
        );
        final res = await client.execute(request: req);

        expect(res.body, 'Hi Jane Doe');
        expect(res.headers['content-type'], 'text/plain');
        expect(res.statusCode, 200);
      });

      test('get_greeting_simple', () async {
        final req = Request(
          url: 'http://localhost:$kPort/greeting/simple/John/Doe',
        );
        final res = await client.execute(request: req);

        expect(res.body, 'Hello John Doe');
        expect(res.headers['content-type'], 'text/plain');
        expect(res.statusCode, 200);
      });

      test('post_greeting_list', () async {
        final req = Request(
          body: json.encode({
            'name': {
              'first': 'George',
              'last': 'Washington',
            }
          }),
          method: RequestMethod.post,
          url: 'http://localhost:$kPort/greeting/list',
        );
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );

        expect(res.body, 'Howdy George Washington');
        expect(res.headers['content-type'], 'text/plain');
        expect(res.statusCode, 200);
      });

      test('negative: post_greeting_list', () async {
        final req = Request(
          body: json.encode({
            'name': {
              'first': 'George',
            }
          }),
          method: RequestMethod.post,
          url: 'http://localhost:$kPort/greeting/list',
        );

        try {
          await client.execute(
            request: req,
            jsonResponse: false,
          );
          fail('Expected exception');
        } catch (_) {
          // pass
        }
      });

      test('post_greeting_map', () async {
        final req = Request(
          body: json.encode({
            'name': {
              'first': 'Thomas',
              'last': 'Jefferson',
            }
          }),
          method: RequestMethod.post,
          url: 'http://localhost:$kPort/greeting/string',
        );
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );

        expect(res.body, 'Yo Thomas Jefferson');
        expect(res.headers['content-type'], 'text/plain');
        expect(res.statusCode, 200);
      });

      test('negative: post_greeting_map', () async {
        final req = Request(
          body: json.encode({
            'name': {
              'first': 'Thomas',
              'last': '',
            }
          }),
          method: RequestMethod.post,
          url: 'http://localhost:$kPort/greeting/string',
        );

        try {
          await client.execute(
            request: req,
            jsonResponse: false,
          );
          fail('Expected exception');
        } catch (e) {
          // pass
        }
      });

      test('post_greeting_string', () async {
        final req = Request(
          body: json.encode({
            'name': {
              'first': 'Thomas',
              'last': 'Jefferson',
            }
          }),
          method: RequestMethod.post,
          url: 'http://localhost:$kPort/greeting/string',
        );
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );

        expect(res.body, 'Yo Thomas Jefferson');
        expect(res.headers['content-type'], 'text/plain');
        expect(res.statusCode, 200);
      });
    });

    group('users', () {
      test('user_inline_jane', () async {
        final req = Request(
          method: RequestMethod.get,
          url: 'http://localhost:$kPort/user/inline/jane',
        );
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );

        final greeting = 'Nice to meet you';
        final firstName = 'Jane';
        final lastName = 'Smith';

        expect(res.body, '''
$greeting $firstName $lastName
${greeting.toUpperCase()} ${firstName.toUpperCase()} ${lastName.toUpperCase()}
${greeting.toLowerCase()} ${firstName.toLowerCase()} ${lastName.toLowerCase()}''');
        expect(res.headers['content-type'], 'text/plain');
        expect(res.statusCode, 200);
      });

      test('user_inline_john', () async {
        final req = Request(
          method: RequestMethod.get,
          url: 'http://localhost:$kPort/user/inline/john',
        );
        final res = await client.execute(
          request: req,
          jsonResponse: false,
        );

        final greeting = 'Bonjour';
        final firstName = 'John';
        final lastName = 'Smith';

        expect(res.body, '''
$greeting $firstName $lastName
${greeting.toUpperCase()} ${firstName.toUpperCase()} ${lastName.toUpperCase()}
${greeting.toLowerCase()} ${firstName.toLowerCase()} ${lastName.toLowerCase()}''');
        expect(res.headers['content-type'], 'text/plain');
        expect(res.statusCode, 200);
      });

      test('user_body_jane', () async {
        final req = Request(
          method: RequestMethod.get,
          url: 'http://localhost:$kPort/user/jane',
        );
        final res = await client.execute(
          request: req,
        );

        final greeting = 'Nice to meet you';
        final firstName = 'Jane';
        final lastName = 'Smith';

        expect(res.body, {
          'standard': {
            'greeting': '${greeting}',
            'name': {'first': '${firstName}', 'last': '${lastName}'}
          },
          'upper': {
            'greeting': '${greeting.toUpperCase()}',
            'name': {
              'first': '${firstName.toUpperCase()}',
              'last': '${lastName.toUpperCase()}'
            }
          },
          'lower': {
            'greeting': '${greeting.toLowerCase()}',
            'name': {
              'first': '${firstName.toLowerCase()}',
              'last': '${lastName.toLowerCase()}'
            },
          },
        });
        expect(res.headers['content-type'], 'application/json');
        expect(res.statusCode, 200);
      });

      test('user_body_john', () async {
        final req = Request(
          method: RequestMethod.get,
          url: 'http://localhost:$kPort/user/john',
        );
        final res = await client.execute(
          request: req,
        );

        final greeting = 'Bonjour';
        final firstName = 'John';
        final lastName = 'Smith';

        expect(res.body, {
          'standard': {
            'greeting': '${greeting}',
            'name': {'first': '${firstName}', 'last': '${lastName}'}
          },
          'upper': {
            'greeting': '${greeting.toUpperCase()}',
            'name': {
              'first': '${firstName.toUpperCase()}',
              'last': '${lastName.toUpperCase()}'
            }
          },
          'lower': {
            'greeting': '${greeting.toLowerCase()}',
            'name': {
              'first': '${firstName.toLowerCase()}',
              'last': '${lastName.toLowerCase()}'
            },
          },
        });
        expect(res.headers['content-type'], 'application/json');
        expect(res.statusCode, 200);
      });

      test('user', () async {
        final greeting = 'New User:';
        final firstName = 'Test';
        final lastName = 'User';

        var req = Request(
          method: RequestMethod.get,
          url: 'http://localhost:$kPort/user/$firstName/$lastName',
        );
        try {
          await client.execute(
            request: req,
          );
          fail('Expected RestException');
        } catch (e) {
          if (e is RestException) {
            expect(e.response.statusCode, 404);
          } else {
            fail('Expected RestException');
          }
        }

        req = Request(
          body: json.encode({
            'name': {
              'first': firstName,
              'last': lastName,
            },
          }),
          method: RequestMethod.put,
          url: 'http://localhost:$kPort/user',
        );
        var res = await client.execute(
          request: req,
        );

        expect(res.body, {
          'standard': {
            'greeting': '${greeting}',
            'name': {'first': '${firstName}', 'last': '${lastName}'}
          },
          'upper': {
            'greeting': '${greeting.toUpperCase()}',
            'name': {
              'first': '${firstName.toUpperCase()}',
              'last': '${lastName.toUpperCase()}'
            }
          },
          'lower': {
            'greeting': '${greeting.toLowerCase()}',
            'name': {
              'first': '${firstName.toLowerCase()}',
              'last': '${lastName.toLowerCase()}'
            },
          },
        });
        expect(res.headers['content-type'], 'application/json');
        expect(res.statusCode, 200);

        req = Request(
          method: RequestMethod.get,
          url: 'http://localhost:$kPort/user/$firstName/$lastName',
        );

        res = await client.execute(
          request: req,
        );

        expect(res.body, {
          'standard': {
            'greeting': '${greeting}',
            'name': {'first': '${firstName}', 'last': '${lastName}'}
          },
          'upper': {
            'greeting': '${greeting.toUpperCase()}',
            'name': {
              'first': '${firstName.toUpperCase()}',
              'last': '${lastName.toUpperCase()}'
            }
          },
          'lower': {
            'greeting': '${greeting.toLowerCase()}',
            'name': {
              'first': '${firstName.toLowerCase()}',
              'last': '${lastName.toLowerCase()}'
            },
          },
        });
        expect(res.headers['content-type'], 'application/json');
        expect(res.statusCode, 200);
      });
    });

    group('jwt', () {
      const kUsername = 'test_user';

      final actualTest = (mode) async {
        var req = Request(
          body: json.encode({
            'username': kUsername,
          }),
          url: 'http://localhost:$kPort/jwt/$mode/create',
        );

        var res = await client.execute(request: req);

        final decoded = res.body;

        final accessToken = decoded['accessToken'];
        final refreshToken = decoded['refreshToken'];

        final accessJwt = JsonWebToken.unverified(accessToken);
        final refreshJwt = JsonWebToken.unverified(refreshToken);

        expect(
          DateTime.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch +
                const Duration(minutes: 10).inMilliseconds,
          ).millisecondsSinceEpoch,
          lessThan(accessJwt.claims.expiry!.millisecondsSinceEpoch),
        );
        expect(
          DateTime.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch +
                const Duration(minutes: 20).inMilliseconds,
          ).millisecondsSinceEpoch,
          greaterThan(accessJwt.claims.expiry!.millisecondsSinceEpoch),
        );

        expect(
          DateTime.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch +
                const Duration(days: 10).inMilliseconds,
          ).millisecondsSinceEpoch,
          lessThan(refreshJwt.claims.expiry!.millisecondsSinceEpoch),
        );
        expect(
          DateTime.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch +
                const Duration(days: 20).inMilliseconds,
          ).millisecondsSinceEpoch,
          greaterThan(refreshJwt.claims.expiry!.millisecondsSinceEpoch),
        );

        expect(accessJwt.claims.subject, kUsername);
        expect(refreshJwt.claims.subject, kUsername);

        req = Request(
          headers: {'x-authorization': accessToken},
          url: 'http://localhost:$kPort/jwt/$mode/refresh',
        );

        // Can only refresh a refresh token, not an access one
        try {
          await client.execute(request: req);
          fail('Expected exception');
        } catch (e) {
          if (e is RestException) {
            final res = e.response;
            expect(res.body, 'Not a valid refresh token');
          }
        }

        req = Request(
          headers: {'x-authorization': refreshToken},
          url: 'http://localhost:$kPort/jwt/$mode/refresh',
        );
        res = await client.execute(request: req);
        expect(res.body, 'Valid refresh token');

        req = Request(
          headers: {'x-authorization': accessToken},
          url: 'http://localhost:$kPort/jwt/$mode/validate',
        );
        res = await client.execute(request: req);
        expect(res.body, 'Hello, $kUsername');

        req = Request(
          headers: {'x-authorization': refreshToken},
          url: 'http://localhost:$kPort/jwt/$mode/validate',
        );
        res = await client.execute(request: req);
        expect(res.body, 'Hello, $kUsername');
      };

      test('jwt_hmac', () async {
        await actualTest('hmac');
      });
      test('jwt_rsa', () async {
        await actualTest('rsa');
      });
    });
  }, timeout: const Timeout(Duration(seconds: 60)));
}
