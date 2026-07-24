class BookingSucessModel {
  int? status;
  String? message;
  Data? data;
  String? error;

  BookingSucessModel({this.status, this.message, this.data, this.error});

  BookingSucessModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['error'] = error;
    return data;
  }
}

class Data {
  int? bookingId;
  String? pickupOtp;
  String? status;
  String? paymentUrl;

  Data({this.bookingId, this.pickupOtp, this.status, this.paymentUrl});

  Data.fromJson(Map<String, dynamic> json) {
    bookingId = json['booking_id'];
    pickupOtp = json['pickup_otp'];
    status = json['status'];
    paymentUrl = json['payment_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['booking_id'] = bookingId;
    data['pickup_otp'] = pickupOtp;
    data['status'] = status;
    data['payment_url'] = paymentUrl;
    return data;
  }
}
