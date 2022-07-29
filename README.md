# dynamic_service

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Introduction](#introduction)
- [Steps](#steps)


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

The `create_jwt` step create a JWT with either a `hs256` or `rs256` based signature.  The parameters 

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
`expires`               | No       | [int]                | | Number of seconds 
`key`                   | **Yes**  | [Boolean Expression] | [jwt.yaml](example/server/assets/steps/jwt.yaml) | Expression that determines whether to execute the `steps-true` or `steps-false` steps next.
`keyId` \| `key-id`     | **Yes**  | [Step]\[\]           | [jwt.yaml](example/server/assets/steps/jwt.yaml) | Zero or more steps to execute when the expression evaluates to `false`.
`keyType` \| `key-type` | **Yes**  | [Step]\[\]           | [jwt.yaml](example/server/assets/steps/jwt.yaml) | Zero or more steps to execute when the expression evaluates to `false`.


---


### delay

---


### etag

---


### for_each

---


### load_network

---


### parallel

---


### set_response

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
[Step]: #step
[Template]: #template
[YAML Expression]: #yaml-expression
[YAON Expression]: #yaon-expression