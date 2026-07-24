class ServiceTypeResponse {
  int? status;
  String? message;
  ServiceTypeData? data;
  String? error;

  ServiceTypeResponse({
    this.status,
    this.message,
    this.data,
    this.error,
  });

  ServiceTypeResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'] ?? 0;
    message = json['message'] ?? '';
    error = json['error'] ?? '';

    data = json['data'] != null
        ? ServiceTypeData.fromJson(json['data'])
        : ServiceTypeData();
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status ?? 0,
      'message': message ?? '',
      'data': data?.toJson() ?? {},
      'error': error ?? '',
    };
  }
}
class ServiceTypeData {
  List<ServiceType>? serviceTypes;

  ServiceTypeData({this.serviceTypes});

  ServiceTypeData.fromJson(Map<String, dynamic> json) {
    if (json['service_types'] != null) {
      serviceTypes = [];
      json['service_types'].forEach((v) {
        serviceTypes!.add(ServiceType.fromJson(v));
      });
    } else {
      serviceTypes = [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'service_types':
          serviceTypes?.map((e) => e.toJson()).toList() ?? [],
    };
  }
}
class ServiceType {
  int? id;
  String? name;
  String? status;

  ServiceType({
    this.id,
    this.name,
    this.status,
  });

  ServiceType.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    name = json['name'] ?? '';
    status = json['status']?.toString() ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? 0,
      'name': name ?? '',
      'status': status ?? '',
    };
  }
}
