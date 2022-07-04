<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [dynamic_service](#dynamic_service)
  - [Introduction](#introduction)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# dynamic_service

## Introduction

The Dynamic Service is a Dart based service that can have a dynamic API definition loaded from the local file system, a network URL, or any other custom plugin that supports loading data.

The package comes with an example [client](examples/client) and an example [server](examples/server).  The server has a [Swagger](https://peiffer-innovations.github.io/dynamic_service/) definition to assist with describing the examples.


## Steps

The Dynamic Service operates by executing a series of [Steps](lib/src/models/service_step.dart).  Steps can be registered via the [DynamicServiceRegistry](lib/src/components/dynamic_service_registry.dart).

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

