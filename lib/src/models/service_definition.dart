import 'package:dynamic_service/dynamic_service.dart';

class ServiceDefinition {
  ServiceDefinition({
    required this.entries,
    required this.id,
  });

  final List<ServiceEntry> entries;
  final String id;

  static Future<ServiceDefinition> fromDynamic(
    dynamic map, {
    required DynamicServiceRegistry registry,
  }) async {
    if (map == null) {
      throw Exception('[ServiceDefinition]: map is null');
    }

    return ServiceDefinition(
      entries: await _loadEntries(map, registry: registry),
      id: map['id']?.toString() ?? 'default',
    );
  }

  static Future<List<ServiceEntry>> _loadEntries(
    dynamic map, {
    required DynamicServiceRegistry registry,
  }) async {
    final results = <ServiceEntry>[];

    var entries = map['services'];
    if (entries is List) {
      entries = entries.asMap();
    }
    if (entries is Map) {
      for (var entry in entries.entries) {
        final ref = entry.value[r'$ref'];
        if (ref == null) {
          results.add(
            await ServiceEntry.fromDynamic(
              entry.value,
              id: entry.key.toString(),
              registry: registry,
            ),
          );
        } else {
          final data = await registry.loadRef(ref);
          results.addAll(await _loadEntries(data, registry: registry));
        }
      }
    } else {
      throw Exception(
        '[ServiceDefinition]: unknown type for services: [${entries?.runtimeType}]',
      );
    }

    return results;
  }
}
