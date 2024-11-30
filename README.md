**Archived**: No longer interested in maintaining this package.

# dynamic_service

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Introduction](#introduction)
- [Steps](#steps)
  - [conditional](#conditional)
  - [create_jwt](#create_jwt)
  - [delay](#delay)
  - [etag](#etag)
  - [for_each](#for_each)
  - [load_network](#load_network)
  - [parallel](#parallel)
  - [set_response](#set_response)
  - [set_variables](#set_variables)
  - [shuffle_list](#shuffle_list)
  - [validate_jwt](#validate_jwt)
  - [validate_schema](#validate_schema)
  - [write](#write)
- [Custom Steps](#custom-steps)
- [Types](#types)
  - [Boolean Expression](#boolean-expression)
  - [Expression](#expression)
  - [JSON Expression](#json-expression)
  - [Network Request](#network-request)
  - [Network Response](#network-response)
  - [Step](#step)
  - [Template](#template)
  - [YAML Expression](#yaml-expression)
  - [YAON Expression](#yaon-expression)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

---

## Introduction

The Dynamic Service is a Dart based service that can have a dynamic API definition loaded from the local file system, a network URL, or any other custom plugin that supports loading data.

The package comes with an example [client](examples/client) and an example [server](examples/server).  The server has a [Swagger](https://peiffer-innovations.github.io/dynamic_service/) definition to assist with describing the examples.


---

## Steps

The Dynamic Service operates by executing a series of [Steps](lib/src/models/service_step.dart).  Steps can be registered via the [DynamicServiceRegistry](lib/src/components/dynamic_service_registry.dart).


### conditional

The `conditional` step will evaluate an [Boolean Expression] and determine what, if any, steps to execute next.

**Type**: `conditional`
**Example**:
```yaml
- type: conditional
  with:
    condition: ${(claims['refresh'] ?? '').toString() == 'true'}
    steps-false:
      - type: set_response
        with:
          code: 401
          content-type: text/plain
          body: Not a valid refresh token
    steps-true:
      - type: set_response
        with:
          content-type: text/plain
          body: Valid refresh token
```

Parameters:

Name          | Required | Type                 | Example                                          | Description
--------------|----------|----------------------|--------------------------------------------------|------------
`condition`   | **Yes**  | [Boolean Expression] | [jwt.yaml](example/server/assets/steps/jwt.yaml) | Expression that determines whether to execute the `steps-true` or `steps-false` steps next.
`steps-false` | No       | [Step]\[\]           | [jwt.yaml](example/server/assets/steps/jwt.yaml) | Zero or more steps to execute when the expression evaluates to `false`.
`steps-true`  | No       | [Step]\[\]           | [jwt.yaml](example/server/assets/steps/jwt.yaml) | Zero or more steps to execute when the expression evaluates to `true`.


---

### create_jwt

The `create_jwt` step create a JWT with either a `hs256` or `rs256` based signature.

**Type**: `create_jwt`
**Example**:
```yaml
- type: create_jwt
  with:
    accessToken:
      expires: ${minutes(15).inSeconds}
      key: ${key}
      key-type: HS256
      claims:
        sub: ${body['username']}
    refreshToken:
      expires: ${days(14).inSeconds}
      key: ${key}
      key-type: HS256
      claims:
        refresh: true
        sub: ${body['username']}
```

Parameters:

Name                    | Required | Type                 | Example                                          | Description
------------------------|----------|----------------------|--------------------------------------------------|------------
`expires`               | No       | `int`                | | Number of seconds 
`key`                   | **Yes**  | [Boolean Expression] | [jwt.yaml](example/server/assets/steps/jwt.yaml) | Expression that determines whether to execute the `steps-true` or `steps-false` steps next.
`keyId` \| `key-id`     | **Yes**  | [Step]\[\]           | [jwt.yaml](example/server/assets/steps/jwt.yaml) | Zero or more steps to execute when the expression evaluates to `false`.
`keyType` \| `key-type` | **Yes**  | [Step]\[\]           | [jwt.yaml](example/server/assets/steps/jwt.yaml) | Zero or more steps to execute when the expression evaluates to `false`.


---


### delay

The `delay` step will delay the response between `min` and `max` milliseconds.

**Type**: `delay`
**Example**:
```yaml
- type: delay
  with:
    min: 1000
    max: 5000
```

Parameters:

Name  | Required | Type  | Example                                            | Description
------|----------|-------|----------------------------------------------------|------------
`min` | No       | `int` | [service.yaml](example/server/assets/service.yaml) | Minimum number of milliseconds to wait.
`max` | No       | `int` | [service.yaml](example/server/assets/service.yaml) | Maximum number of milliseconds to wait.


---


### etag

The `etag` step will put an `ETag` header on the response, and if the `If-None-Match` header matches the `ETag` then a `204` will be returned with an empty body

**Type**: `etag`
**Example**:
```yaml
- type: etag
```

Parameters:

n/a

---


### for_each

The `for_each` step will iterate over the given `input` and execute the `steps` for each input item either in series or in parallel.

**Type**: `for_each`
**Example**:
```yaml
- type: for_each
  with:
    input: ${array}
    steps:
      - type: delay
        with:
          min: 100
          max: 300
      - type: set_variables
        with:
          message: |
            ${message + index.toString() + ': ' + variable.toString() + ': ' + request['body']}
```

Parameters:

Name       | Required | Type            | Example                                                       | Description
-----------|----------|-----------------|---------------------------------------------------------------|------------
`input`    | **Yes**  | `List` or `Map` | [for_each.yaml](example/server/assets/services/for_each.yaml) | The list or map to iterate over.
`parallel` | no       | `bool`          | [for_each.yaml](example/server/assets/services/for_each.yaml) | Set to `true` to iterate in parallel, defaults to `false`.
`steps`    | **Yes**  | [Step]\[\]      | [for_each.yaml](example/server/assets/services/for_each.yaml) | The steps to excute for each iteration.


---


### load_network

The `load_network` step will load from a one `request` or multiple `requests`

**Type**: `load_network`
**Example**:
```yaml
  - type: load_network
    with:
      requests:
        - url: https://raw.githubusercontent.com/peiffer-innovations/dynamic_service/main/pages/first_names.json
          variable: first
        - url: https://raw.githubusercontent.com/peiffer-innovations/dynamic_service/main/pages/last_names.json
          variable: last
```

Parameters:

Name       | Required | Type                  | Example                                                            | Description
-----------|----------|-----------------------|--------------------------------------------------------------------|------------
`async`    | no       | `bool`                | n/a                                                                | Send the network calls but do not wait for a response before continuing to the next step.
`request`  | no       | [Network Request]     | n/a                                                                | The singular network request to make.  Either this or `requests` is required.
`requests` | no       | [Network Request]\[\] | [random_names.yaml](example/server/assets/steps/random_names.yaml) | The list of network requests to make.  Either this or `request` is requred.
`variable` | no       | `String`              | n/a                                                                | The variable name to put the responses on when not `async`.  Defaults to `load_network` if not set.


---


### parallel

The `parallel` step execute all sub-steps in parallel rather than series.

**Type**: `delay`
**Example**:
```yaml
- type: parallel
  with:
    steps:
      - type: delay
        with:
          min: 500
          max: 1000
      - type: delay
        with:
          min: 500
          max: 1000
      - type: delay
        with:
          min: 500
          max: 1000
      - type: delay
        with:
          min: 500
          max: 1000
      - type: delay
        with:
          min: 500
          max: 1000
      - type: delay
        with:
          min: 500
          max: 1000
```

Parameters:

Name    | Required | Type       | Example                                            | Description
--------|----------|------------|----------------------------------------------------|------------
`steps` | **Yes**  | [Step]\[\] | [service.yaml](example/server/assets/service.yaml) | The steps to execute in parallel.


---


### set_response

Parameters:

Name           | Required | Type                  | Example                                            | Description
---------------|----------|-----------------------|----------------------------------------------------|------------
`body`         | no       | `dynamic`             | 
`content-type` | no       | `String`              | [service.yaml](example/server/assets/service.yaml) | The steps to execute in parallel.
`file`         | no       | `String`              |
`headers`      | no       | `Map<String, String>` |
`status`       | no       | `int`                 |
`$ref`         | no

---


### set_variables

---


### shuffle_list

---


### validate_jwt

---


### validate_schema

---


### write

---

## Custom Steps

For example, to create a new step that can perform a custom action, you would update your `main` function to look like:

```dart
import 'package:dynamic_service/dynamic_service.dart';

Future<void> main(List<String> args) {
  var registry = DynamicServiceRegistry.defaultInstance;
  registry.registerStep(
    type: _MyCustomStep.kType,
    builder: (args) => _MyCustomStep(args: args),
  );

  await Server().start(args);
}

class _MyCustomStep extends ServiceStep {
  _MyCustomStep({
    Map<String, dynamic>? args,
  }) : super(
          args: args,
          type: kType,
        );
  static const kType = 'my-custom-step';

  @override
  Future<void> applyStep(
    ServiceContext context,
    Map<String, dynamic> args,
  ) async {
    // Your custom code goes here
  }
}
```

---

## Types

### Boolean Expression

An String [Expression] that evaluate to a `true` or `false` boolean result.  The result is considered to be `true` when the final result from the expression resolves to one of:
* true
* yes
* 1


**Examples**:
```
${json_path(body, "$.name.first").isNotEmpty == true && json_path(body, "$.name.last").isNotEmpty == true}
${json_path(body, "$.name.first").isNotEmpty}
```

---

### Expression

An String that uses the [template_expressions](https://pub.dev/packages/template_expressions) syntax to evaluate a singular result.

**Examples**:
```
${json_path(body, "$.name.first").isNotEmpty == true && json_path(body, "$.name.last").isNotEmpty == true}
${json_path(body, "$.name.first").isNotEmpty}
```

---

### JSON Expression

A JSON compatible `List<String>`, `Map<String, dynamic>` or JSON encoded string where the entries may each contain an [Expression].

**Examples**:
```
{
  "${json_path(body, \"$.name.first\")}": ".*\\S.*",
  "${json_path(body, \"$.name.last\")}": ".*\\S.*"
}

[
  "${json_path(body, \"$.name.first\").isNotEmpty}",
  "${json_path(body, \"$.name.last\").isNotEmpty}"
]
```

---

### Network Request

A descriptor for making a network call.

**Properties**

Name          | Required | Type                        | Description
--------------|----------|-----------------------------|-------------
`body`        | no       | `JSON`, `YAML`, or `String` | The body to send on the request.  May be `JSON`, `YAML`, or a plain `String`.
`delay`       | no       | `int`                       | The number of milliseconds to wait before making the network call.
`headers`     | no       | `Map<String, String>`       | The optional headers to send on the request.
`method`      | no       | `String`                    | The HTTP method to use.  Defaults to `GET` if there is no body, and `POST` if a body exists.
`url`         | **Yes**  | `String`                    | The URL of the network endpoint to call.
`variable`    | no       | `String`                    | The variable identifier of the request.  If the step is not `async` then the [Network Response] from the call will be set in the variables.

---

### Network Response

A descriptor for the results of a network call.

**Properties**

Name          | Required | Type                  | Description
--------------|----------|-----------------------|-------------
`body`        | **Yes**  | `dynamic`             | The response body.
`headers`     | **Yes**  | `Map<String, String>` | The response headers.
`statusCode`  | **Yes**  | `int`                 | The response status code.


---

### Step

---

### Template

An string containing zero or more [Expression]'s to create a String based result.

**Examples**:
```
"Howdy ${json_path(body, '$.name.first')} ${json_path(body, '$.name.last')}"
"Hello ${path['firstName']} ${path['lastName']}"
```

---

### YAML Expression

A YAML compatible `List<String>`, `Map<String, dynamic>` or YAML encoded string where the entries may each contain an [Expression].

**Examples**:
```
body:
  '${json_path(body, "$.name.first")}': '.*\\S.*'
  '${json_path(body, "$.name.last")}': '.*\\S.*'


body:
  - '${json_path(body, "$.name.first").isNotEmpty}'
  - '${json_path(body, "$.name.last").isNotEmpty}'

```

---

### YAON Expression

Can be either a [YAML Expression] or a [JSON Expression].




<!-- LINKS -->

[Boolean Expression]: #boolean-expression
[Expression]: #expression
[JSON Expression]: #json-expression
[Network Request]: #network-request
[Network Response]: #network-response
[Step]: #step
[Template]: #template
[YAML Expression]: #yaml-expression
[YAON Expression]: #yaon-expression
