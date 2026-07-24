class SosResponse {
  int? status;
  String? message;
  SosData? data;
  String? error;

  SosResponse({this.status, this.message, this.data, this.error});

  SosResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? SosData.fromJson(json['data']) : null;
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['status'] = status;
    map['message'] = message;
    if (data != null) map['data'] = data!.toJson();
    map['error'] = error;
    return map;
  }
}

class SosData {
  List<Sos>? sos;

  SosData({this.sos});

  SosData.fromJson(Map<String, dynamic> json) {
    if (json['sos'] != null) {
      sos = <Sos>[];
      json['sos'].forEach((v) {
        sos!.add(Sos.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    if (sos != null) {
      map['sos'] = sos!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Sos {
  int? id;
  String? name;
  String? sosNumber;
  String? status;
  String? createdAt;
  String? updatedAt;

  Sos({
    this.id,
    this.name,
    this.sosNumber,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  Sos.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    sosNumber = json['sos_number'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['id'] = id;
    map['name'] = name;
    map['sos_number'] = sosNumber;
    map['status'] = status;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}
