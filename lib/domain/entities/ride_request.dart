class RideRequest {
  String? rideId;
  String? bookingId;
  String? otp;
  String? userId;
  String? userName;
  String? userPhone;
  String? userPhoto;
  String? userRating;
  String? driverId;
  String? driverName;
  String? driverPhone;
  String? driverPhoto;
  dynamic driverRating;
  String? driverConfirmedPayment;
  String? driverPayment;
  String? riderConfirmedPayment;
  String? adminCommission;
  String? status;
  String? tax;
  String? travelCharges;
  String? totalDistance;
  String? totalTravelTime;
  String? distanceRemain;
  String? timeRemain;
  String? paymentMethod;
  String? paymentStatus;
  int? timestamp;
  String? rideStatusLabel;

  FeedbackModel? customerFeedback;
  FeedbackModel? driverFeedback;

  VehicleDetails? vehicleDetails;

  Location? pickupLocation;
  Location? dropoffLocation;

  RideRequest({
    this.rideId,
    this.bookingId,
    this.otp,
    this.userId,
    this.userName,
    this.userPhone,
    this.userPhoto,
    this.userRating,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.driverRating,
    this.driverConfirmedPayment,
    this.driverPayment,
    this.riderConfirmedPayment,
    this.adminCommission,
    this.status,
    this.tax,
    this.travelCharges,
    this.totalDistance,
    this.totalTravelTime,
    this.distanceRemain,
    this.timeRemain,
    this.paymentMethod,
    this.paymentStatus,
    this.timestamp,
    this.rideStatusLabel,
    this.customerFeedback,
    this.driverFeedback,
    this.vehicleDetails,
    this.pickupLocation,
    this.dropoffLocation,
  });

  factory RideRequest.fromJson(String rideId, Map<String, dynamic> json) {
    return RideRequest(
      rideId: rideId,
      bookingId: json["bookingId"],
      otp: json["OTP"],
      userId: json["userId"],
      userName: json["customer"]?["userName"],
      userPhone: json["customer"]?["userPhone"],
      userPhoto: json["customer"]?["userPhoto"],
      userRating: json["customer"]?["userRating"],
      driverId: json["driverId"],
      driverName: json["driver"]?["driverName"],
      driverPhone: json["driver"]?["driverPhone"],
      driverPhoto: json["driver"]?["driverPhoto"],
      driverRating: json["driver"]?["driverRating"],
      driverConfirmedPayment: json["driver"]?["driverConfirmedPayment"],
      driverPayment: json["driver"]?["driverPayment"],
      riderConfirmedPayment: json["riderConfirmedPayment"],
      adminCommission: json["adminCommission"],
      status: json["status"],
      tax: json["tax"],
      travelCharges: json["travelCharges"],
      totalDistance: json["totalDistance"],
      totalTravelTime: json["totalTravelTime"],
      distanceRemain: json["distanceRemain"],
      timeRemain: json["timeRemain"],
      paymentMethod: json["paymentMethod"],
      paymentStatus: json["paymentStatus"],
      timestamp: json["timeStamp"],
      rideStatusLabel: json["rideStatusLabel"],
      customerFeedback: json["customerFeeback"] != null
          ? FeedbackModel.fromJson(
              Map<String, dynamic>.from(json["customerFeeback"]))
          : null,
      driverFeedback: json["driverFeeback"] != null
          ? FeedbackModel.fromJson(
              Map<String, dynamic>.from(json["driverFeeback"]))
          : null,
      vehicleDetails: json["vehicleDetails"] != null
          ? VehicleDetails.fromJson(
              Map<String, dynamic>.from(json["vehicleDetails"]))
          : null,
      pickupLocation: json["pickupLocation"] != null
          ? Location.fromJson(Map<String, dynamic>.from(json["pickupLocation"]))
          : null,
      dropoffLocation: json["dropoffLocation"] != null
          ? Location.fromJson(
              Map<String, dynamic>.from(json["dropoffLocation"]))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "rideId": rideId,
      "bookingId": bookingId,
      "OTP": otp,
      "userId": userId,
      "customer": {
        "userName": userName,
        "userPhone": userPhone,
        "userPhoto": userPhoto,
        "userRating": userRating,
      },
      "driverId": driverId,
      "driver": {
        "driverName": driverName,
        "driverPhone": driverPhone,
        "driverPhoto": driverPhoto,
        "driverRating": driverRating,
        "driverConfirmedPayment": driverConfirmedPayment,
        "driverPayment": driverPayment,
      },
      "riderConfirmedPayment": riderConfirmedPayment,
      "adminCommission": adminCommission,
      "status": status,
      "tax": tax,
      "travelCharges": travelCharges,
      "totalDistance": totalDistance,
      "totalTravelTime": totalTravelTime,
      "distanceRemain": distanceRemain,
      "timeRemain": timeRemain,
      "paymentMethod": paymentMethod,
      "paymentStatus": paymentStatus,
      "timeStamp": timestamp,
      "rideStatusLabel": rideStatusLabel,
      "customerFeeback": customerFeedback?.toJson(),
      "driverFeeback": driverFeedback?.toJson(),
      "vehicleDetails": vehicleDetails?.toJson(),
      "pickupLocation": pickupLocation?.toJson(),
      "dropoffLocation": dropoffLocation?.toJson(),
    };
  }
}

// Location Model (supports pickup/dropoff)
class Location {
  final double lat;
  final double lng;
  final String address;

  Location({required this.lat, required this.lng, required this.address});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      address: json['pickupAddress'] ?? json['dropoffAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "lat": lat,
      "lng": lng,
      "pickupAddress": address,
    };
  }
}

// Feedback model for customer/driver
class FeedbackModel {
  final String rating;
  final String review;

  FeedbackModel({required this.rating, required this.review});

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      rating: json['rating'] ?? '',
      review: json['review'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "rating": rating,
      "review": review,
    };
  }
}

// Vehicle details model
class VehicleDetails {
  final String itemId;
  final String itemTypeName;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleNumber;

  VehicleDetails({
    required this.itemId,
    required this.itemTypeName,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleNumber,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      itemId: json['itemId'] ?? '',
      itemTypeName: json['itemTypeName'] ?? '',
      vehicleMake: json['vehicleMake'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "itemId": itemId,
      "itemTypeName": itemTypeName,
      "vehicleMake": vehicleMake,
      "vehicleModel": vehicleModel,
      "vehicleNumber": vehicleNumber,
    };
  }
}

// for sechedule 
class ScheduledRideModel {
  final String scheduleId;
  final Map<dynamic, dynamic> vehicleData;
  final String pickupAddress;
  final String dropAddress;
 
  final String scheduledAt;
  final String picLat  ;
  final String picLang ;
  final String drplat  ;
  final String drpLang ;

  ScheduledRideModel({
    required this.scheduleId,
    required this.vehicleData,
    required this.pickupAddress,
    required this.dropAddress,
 
    required this.scheduledAt,
    required this.picLat,
    required this.picLang,
    required this.drplat,
    required this.drpLang
  });

  Map<String, dynamic> toMap() {
    return {
      "scheduleId": scheduleId,
      "vehicleData": vehicleData,
      "pickupAddress": pickupAddress,
      "dropAddress": dropAddress,
   
      "scheduledAt": scheduledAt,
      "picLat": picLat ,
      "picLang":picLang,
      "drplat": drplat ,
      "drpLang":drpLang,
    };
  }
}