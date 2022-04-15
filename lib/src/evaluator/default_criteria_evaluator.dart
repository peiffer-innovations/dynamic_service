import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';
import 'package:template_expressions/template_expressions.dart';

class DefaultCriteriaEvaluator extends CriteriaEvaluator {
  static const kType = 'default';

  static final Logger _logger = Logger('DefaultCriteriaEvaluator');

  @override
  Future<ServiceContext?> evaluate({
    required ServiceEntry entry,
    required DynamicServiceRegistry registry,
    required ServiceRequest request,
  }) async {
    ServiceContext? result;
    var criteria = entry.criteria;

    try {
      var isMatch = true;
      var variables = <String, dynamic>{};

      try {
        variables['body'] = json.decode(request.bodyAsString);
      } catch (e) {
        // no-op
      }

      var path = criteria.path;
      if (path.contains('/:')) {
        path = path.split('/').map((e) {
          var result = e;
          if (result.startsWith(':')) {
            result = '(?<${result.substring(1)}>[^/]*)';
          }
          return result;
        }).join('/');
      }

      var regex = RegExp(path);

      var reqJson = request.toJson();
      var template = Template(
        syntax: registry.templateSyntax,
        value: json.encode(reqJson),
      );
      var req = json.decode(template.process(context: reqJson));

      var pathMatches = regex.allMatches(request.path);

      if (pathMatches.isNotEmpty) {
        var pathVars = <String, String>{};
        pathVars['uri'] = request.path;
        pathMatches.forEach((match) {
          var names = match.groupNames;
          for (var name in names) {
            var value = match.namedGroup(name);
            if (value != null) {
              pathVars[name] = value;
            }
          }
        });

        variables['path'] = pathVars;
      } else {
        _logger.finest(
          '[id: ${entry.id}]: path does not match -- [${request.path}] != [${criteria.path}]',
        );
        isMatch = false;
      }

      if (isMatch) {
        regex = RegExp(criteria.method);
        var matches = regex.hasMatch(request.method);

        if (matches) {
          variables['method'] = request.method;
        } else {
          _logger.finest(
            '[id: ${entry.id}]: method does not match -- [${request.method}] != [${criteria.method}]',
          );
          isMatch = false;
        }
      }

      var evaluate = (test, {canonicalize = false}) {
        var conditionMatch = true;

        if (test != null) {
          if (test is Iterable) {
            for (var e in test) {
              var input = Template(
                syntax: registry.templateSyntax,
                value: e,
              ).process(context: variables);
              var result = JsonClass.parseBool(input);

              if (!result) {
                _logger.finest(
                  '[id: ${entry.id}]: condition does not match -- [${input}] != [${result}]',
                );
                conditionMatch = false;
                break;
              }
            }
          } else if (test is Map) {
            if (canonicalize) {
              test = CanonicalizedMap.from(test, (key) => key.toLowerCase());
            }
            for (var e in test.entries) {
              var input = Template(
                syntax: registry.templateSyntax,
                value: e.key,
              ).process(context: variables);
              var result = RegExp(e.value).hasMatch(input);

              if (!result) {
                _logger.finest(
                  '[id: ${entry.id}]: condition does not match -- [${input}] != [${result}]',
                );
                conditionMatch = false;
                break;
              }
            }
          } else if (test is String) {
            var input = Template(
              syntax: registry.templateSyntax,
              value: test,
            ).process(context: variables);
            var result = JsonClass.parseBool(input);

            conditionMatch = result;
            if (!conditionMatch) {
              _logger.finest(
                '[id: ${entry.id}]: condition does not match -- [${input}] != [${result}]',
              );
            }
          }
        }

        return conditionMatch;
      };

      isMatch = isMatch && evaluate(criteria.headers);
      isMatch = isMatch && evaluate(criteria.body);

      if (isMatch) {
        variables['request'] = req;
        result = ServiceContext(
          registry: registry,
          request: request,
          response: ServiceResponse(),
          variables: variables,
        );
      }
      _logger.fine(
        '[id: ${entry.id}] -- [${request.method}: ${request.path}]: matches: [$isMatch] -- criteria: $criteria',
      );
    } catch (e, stack) {
      _logger.severe(
        'Exception in evaluation of: ${criteria.toString()}',
        e,
        stack,
      );
    }

    return result;
  }
}
