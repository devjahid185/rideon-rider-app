class SliderResponse {
  int? status;
  String? message;
  List<SliderData>? data;

  SliderResponse({
    this.status,
    this.message,
    this.data,
  });

  SliderResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <SliderData>[];
      json['data'].forEach((v) {
        data!.add(SliderData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {};
    dataMap['status'] = status;
    dataMap['message'] = message;
    if (data != null) {
      dataMap['data'] = data!.map((v) => v.toJson()).toList();
    }
    return dataMap;
  }
}

class SliderData {
  int? id;
  String? heading;
  String? image;
  String? url;

  SliderData({
    this.id,
    this.heading,
    this.image,
    this.url,
  });

  SliderData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    heading = json['heading'];
    image = json['image'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {};
    dataMap['id'] = id;
    dataMap['heading'] = heading;
    dataMap['image'] = image;
    dataMap['url'] = url;
    return dataMap;
  }
}