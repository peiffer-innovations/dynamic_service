import 'package:collection/collection.dart';
import 'package:dynamic_service/dynamic_service.dart';

class ChildServiceContext implements ServiceContext {
  ChildServiceContext({
    required this.parent,
  }) : _variables = _ChildMap(parent.variables);

  final ServiceContext parent;

  final _ChildMap _variables;

  @override
  Map<String, dynamic> get variables => _variables;

  @override
  ServiceEntry get entry => parent.entry;

  @override
  DynamicServiceRegistry get registry => parent.registry;

  @override
  ServiceRequest get request => parent.request;

  @override
  ServiceResponse get response => parent.response;

  Map<String, dynamic> get childVariables => _variables._parent;

  @override
  Map<String, dynamic> toJson() => {
        'request': request.toJson(),
        'response': response.toJson(),
        'variables': variables,
      };
}

class _ChildMap extends DelegatingMap<String, dynamic> {
  _ChildMap(Map<String, dynamic> parent)
      : _parent = parent,
        super({});

  final Map<String, dynamic> _parent;

  @override
  dynamic operator [](Object? key) {
    dynamic result;

    if (super.containsKey(key)) {
      result = super[key];
    } else {
      result = _parent[key];
    }

    return result;
  }

  @override
  Iterable<MapEntry<String, dynamic>> get entries => {
        ..._parent.entries.where((e) => super.containsKey(e.key) == false),
        ...super.entries,
      };

  @override
  bool get isEmpty => super.isEmpty && _parent.isEmpty;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  Iterable<String> get keys => {
        ...super.keys,
        ..._parent.keys,
      };

  @override
  int get length => keys.length;

  @override
  Iterable get values {
    var map = <String, dynamic>{};

    map.addAll(_parent);
    map.addAll(this);

    return map.values;
  }

  @override
  bool containsKey(Object? key) =>
      super.containsKey(key) || _parent.containsKey(key);

  @override
  bool containsValue(Object? key) =>
      super.containsValue(key) || _parent.containsValue(key);

  @override
  void forEach(void Function(String key, dynamic value) action) {
    var map = <String, dynamic>{};

    map.addAll(_parent);
    map.addAll(this);

    map.forEach(action);
  }

  @override
  Map<K2, V2> map<K2, V2>(
    MapEntry<K2, V2> Function(String key, dynamic value) convert,
  ) {
    var map = <String, dynamic>{};

    map.addAll(_parent);
    map.addAll(this);

    return map.map(convert);
  }
}
