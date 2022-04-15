import 'package:dynamic_service/dynamic_service.dart';
import 'package:json_class/json_class.dart';

class ServiceContext extends JsonClass {
  ServiceContext({
    required this.registry,
    required this.request,
    required this.response,
    required this.variables,
  });

  final DynamicServiceRegistry registry;
  final ServiceRequest request;
  final ServiceResponse response;
  final Map<String, dynamic> variables;

  @override
  Map<String, dynamic> toJson() => {
        'request': request.toJson(),
        'response': response.toJson(),
        'variables': variables,
      };
}
