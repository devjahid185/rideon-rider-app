class HistoryModel {
  int? status;
  String? message;
  Data? data;
  String? error;

  HistoryModel({this.status, this.message, this.data, this.error});

  HistoryModel.fromJson(Map<String, dynamic> json) {
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
  List<Bookings>? bookings;
  int? offset;
  int? limit;

  Data({this.bookings, this.offset, this.limit});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['Bookings'] != null) {
      bookings = <Bookings>[];
      json['Bookings'].forEach((v) {
        bookings!.add(Bookings.fromJson(v));
      });
    }
    offset = json['offset'];
    limit = json['limit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (bookings != null) {
      data['Bookings'] = bookings!.map((v) => v.toJson()).toList();
    }
    data['offset'] = offset;
    data['limit'] = limit;
    return data;
  }
}

class Bookings {
  int? id;
  String? token;
  String? itemid;
  String? userid;
  String? hostId;
  String? rideDate;
  String? checkOut;
  dynamic startTime;
  dynamic endTime;
  String? status;
  String? totalNight;
  String? perNight;
  dynamic bookFor;
  String? basePrice;
  String? cleaningCharge;
  String? guestCharge;
  String? serviceCharge;
  String? securityMoney;
  String? ivaTax;
  dynamic couponCode;
  int? couponDiscount;
  int? discountPrice;
  String? totalGuest;
  String? amountToPay;
  String? total;
  String? adminCommission;
  String? vendorCommission;
  String? vendorCommissionGiven;
  String? currencyCode;
  dynamic cancellationReasion;
  String? cancelledCharge;
  dynamic transaction;
  String? paymentMethod;
  String? paymentStatus;
  String? itemImg;
  dynamic itemTitle;
  dynamic itemData;
  String? wallAmt;
  dynamic note;
  String? rating;
  String? module;
  String? rideData;
  dynamic cancelledBy;
  int? deductedAmount;
  int? refundableAmount;
  String? createdAt;
  String? updatedAt;
  dynamic deletedAt;
  int? isItemDelivered;
  int? isItemReceived;
  int? isItemReturned;
  String? userName;
  String? userNumber;
  String? userEmail;
  String? userPhoneCountry;
  String? reviewStatus;
  String? reviewRating;
  String? review;
  String? isItemDeliveredButton;
  String? isItemReturnedButton;
  PickupLocation? pickupLocation;
  DropoffLocation? dropoffLocation;
  String? estimatedDistanceKm;
  int? estimatedDurationMin;
  List<String>? deliveryPhotos;

  Bookings(
      {this.id,
      this.token,
      this.itemid,
      this.userid,
      this.hostId,
      this.rideDate,
      this.checkOut,
      this.startTime,
      this.endTime,
      this.status,
      this.totalNight,
      this.perNight,
      this.bookFor,
      this.rideData,
      this.basePrice,
      this.cleaningCharge,
      this.guestCharge,
      this.serviceCharge,
      this.securityMoney,
      this.ivaTax,
      this.couponCode,
      this.couponDiscount,
      this.discountPrice,
      this.totalGuest,
      this.amountToPay,
      this.total,
      this.adminCommission,
      this.vendorCommission,
      this.vendorCommissionGiven,
      this.currencyCode,
      this.cancellationReasion,
      this.cancelledCharge,
      this.transaction,
      this.paymentMethod,
      this.paymentStatus,
      this.itemImg,
      this.itemTitle,
      this.itemData,
      this.wallAmt,
      this.note,
      this.rating,
      this.module,
      this.cancelledBy,
      this.deductedAmount,
      this.refundableAmount,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.isItemDelivered,
      this.isItemReceived,
      this.isItemReturned,
      this.userName,
      this.userNumber,
      this.userEmail,
      this.userPhoneCountry,
      this.reviewStatus,
      this.reviewRating,
      this.review,
      this.isItemDeliveredButton,
      this.isItemReturnedButton,
      this.pickupLocation,
      this.dropoffLocation,
      this.estimatedDistanceKm,
      this.estimatedDurationMin,
      this.deliveryPhotos = const []});

  Bookings.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    token = json['token'];
    itemid = json['itemid'];
    userid = json['userid'];
    hostId = json['host_id'];
    rideDate = json['ride_date'];
    checkOut = json['check_out'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    status = json['status'];
    totalNight = json['total_night'];
    perNight = json['per_night'];
    bookFor = json['book_for'];
    basePrice = json['base_price'];
    rideData = json['firebase_json'];
    cleaningCharge = json['cleaning_charge'];
    guestCharge = json['guest_charge'];
    serviceCharge = json['service_charge'];
    securityMoney = json['security_money'];
    ivaTax = json['iva_tax'];
    couponCode = json['coupon_code'];
    couponDiscount = json['coupon_discount'];
    discountPrice = json['discount_price'];
    totalGuest = json['total_guest'];
    amountToPay = json['amount_to_pay'];
    total = json['total'];
    adminCommission = json['admin_commission'];
    vendorCommission = json['vendor_commission'];
    vendorCommissionGiven = json['vendor_commission_given'];
    currencyCode = json['currency_code'];
    cancellationReasion = json['cancellation_reasion'];
    cancelledCharge = json['cancelled_charge'];
    transaction = json['transaction'];
    paymentMethod = json['payment_method'];
    paymentStatus = json['payment_status'];
    itemImg = json['item_img'];
    itemTitle = json['item_title'];
    itemData = json['item_data'];
    wallAmt = json['wall_amt'];
    note = json['note'];
    rating = json['rating'];
    module = json['module'];
    cancelledBy = json['cancelled_by'];
    deductedAmount = json['deductedAmount'];
    refundableAmount = json['refundableAmount'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    isItemDelivered = json['is_item_delivered'];
    isItemReceived = json['is_item_received'];
    isItemReturned = json['is_item_returned'];
    userName = json['user_name'];
    userNumber = json['user_number'];
    userEmail = json['user_email'];
    userPhoneCountry = json['user_phone_country'];
    reviewStatus = json['review_status'];
    reviewRating = json['review_rating'];
    review = json['review'];
    isItemDeliveredButton = json['is_item_delivered_button'];
    isItemReturnedButton = json['is_item_returned_button'];
    pickupLocation = json['pickup_location'] != null
        ? PickupLocation.fromJson(json['pickup_location'])
        : null;
    dropoffLocation = json['dropoff_location'] != null
        ? DropoffLocation.fromJson(json['dropoff_location'])
        : null;
    estimatedDistanceKm = json['estimated_distance_km'];
    estimatedDurationMin = json['estimated_duration_min'];
    if (json['delivery_images'] != null) {
      deliveryPhotos = List<String>.from(json['delivery_images']);
    } else {
      deliveryPhotos = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['token'] = token;
    data['itemid'] = itemid;
    data['userid'] = userid;
    data['host_id'] = hostId;
    data['check_in'] = rideDate;
    data['check_out'] = checkOut;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['status'] = status;
    data['firebase_json'] = rideData;
    data['total_night'] = totalNight;
    data['per_night'] = perNight;
    data['book_for'] = bookFor;
    data['base_price'] = basePrice;
    data['cleaning_charge'] = cleaningCharge;
    data['guest_charge'] = guestCharge;
    data['service_charge'] = serviceCharge;
    data['security_money'] = securityMoney;
    data['iva_tax'] = ivaTax;
    data['coupon_code'] = couponCode;
    data['coupon_discount'] = couponDiscount;
    data['discount_price'] = discountPrice;
    data['total_guest'] = totalGuest;
    data['amount_to_pay'] = amountToPay;
    data['total'] = total;
    data['admin_commission'] = adminCommission;
    data['vendor_commission'] = vendorCommission;
    data['vendor_commission_given'] = vendorCommissionGiven;
    data['currency_code'] = currencyCode;
    data['cancellation_reasion'] = cancellationReasion;
    data['cancelled_charge'] = cancelledCharge;
    data['transaction'] = transaction;
    data['payment_method'] = paymentMethod;
    data['payment_status'] = paymentStatus;
    data['item_img'] = itemImg;
    data['item_title'] = itemTitle;
    data['item_data'] = itemData;
    data['wall_amt'] = wallAmt;
    data['note'] = note;
    data['rating'] = rating;
    data['module'] = module;
    data['cancelled_by'] = cancelledBy;
    data['deductedAmount'] = deductedAmount;
    data['refundableAmount'] = refundableAmount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    data['is_item_delivered'] = isItemDelivered;
    data['is_item_received'] = isItemReceived;
    data['is_item_returned'] = isItemReturned;
    data['user_name'] = userName;
    data['user_number'] = userNumber;
    data['user_email'] = userEmail;
    data['user_phone_country'] = userPhoneCountry;
    data['review_status'] = reviewStatus;
    data['review_rating'] = reviewRating;
    data['review'] = review;
    data['is_item_delivered_button'] = isItemDeliveredButton;
    data['is_item_returned_button'] = isItemReturnedButton;
    if (pickupLocation != null) {
      data['pickup_location'] = pickupLocation!.toJson();
    }
    if (dropoffLocation != null) {
      data['dropoff_location'] = dropoffLocation!.toJson();
    }
    data['estimated_distance_km'] = estimatedDistanceKm;
    data['estimated_duration_min'] = estimatedDurationMin;
    data['delivery_images'] = deliveryPhotos;
    return data;
  }
}

class PickupLocation {
  String? latitude;
  String? longitude;
  String? address;

  PickupLocation({this.latitude, this.longitude, this.address});

  PickupLocation.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['address'] = address;
    return data;
  }
}

class DropoffLocation {
  String? latitude;
  String? longitude;
  String? address;

  DropoffLocation({this.latitude, this.longitude, this.address});

  DropoffLocation.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['address'] = address;
    return data;
  }
}

class BookingRideData {
  String? otp;
  String? adminCommission;
  String? rideId;
  String? bookingId;
  String? selectedDriverId;
  String? rideStatusLabel;
  Location? pickupLocation;
  Location? dropoffLocation;
  String? status;
  String? userId;
  Customer? customer;
  Driver? driver;
  String? driverPayment;
  String? totalDistance;
  String? distanceRemain;
  String? totalTime;
  String? timeRemain;
  String? tax;
  String? paymentStatus;
  String? paymentMethod;
  String? travelCharges;
  VehicleDetails? vehicleDetails;
  FeedbackData? customerFeedback;
  FeedbackData? driverFeedback;
  ParcalData? parcalData;
  String? driverConfirmedPayment;
  String? riderConfirmedPayment;
  String? timestamp;

  BookingRideData();

  BookingRideData.fromMap(Map<dynamic, dynamic>? map) {
    otp = map?['OTP'];
    adminCommission = map?['adminCommission'];
    rideId = map?['rideId'];
    bookingId = map?['bookingId'];
    selectedDriverId = map?['selectedDriverId'];
    rideStatusLabel = map?['rideStatusLabel'];
    pickupLocation = Location.fromMap(map?['pickupLocation']);
    dropoffLocation = Location.fromMap(map?['dropoffLocation']);
    status = map?['status'];
    userId = map?['userId'];
    customer = Customer.fromMap(map?['customer']);
    driver = Driver.fromMap(map?['driver']);
    driverPayment = map?['driverPayment'];
    totalDistance = map?['totalDistance'];
    distanceRemain = map?['distanceRemain'];
    totalTime = map?['totalTime'];
    timeRemain = map?['timeRemain'];
    tax = map?['tax'];
    paymentStatus = map?['paymentStatus'];
    paymentMethod = map?['paymentMethod'];
    travelCharges = map?['travelCharges'];
    vehicleDetails = VehicleDetails.fromMap(map?['vehicleDetails']);
    customerFeedback = FeedbackData.fromMap(map?['customerFeeback']);
    driverFeedback = FeedbackData.fromMap(map?['driverFeeback']);
    parcalData = ParcalData.fromMap(map?['parcelData']);
    driverConfirmedPayment = map?['driverConfirmedPayment'];
    riderConfirmedPayment = map?['riderConfirmedPayment'];
    timestamp = map?['timestamp'];
  }

  Map<String, dynamic> toJson() {
    return {
      'OTP': otp,
      'adminCommission': adminCommission,
      'rideId': rideId,
      'bookingId': bookingId,
      'selectedDriverId': selectedDriverId,
      'rideStatusLabel': rideStatusLabel,
      'pickupLocation': pickupLocation?.toJson(),
      'dropoffLocation': dropoffLocation?.toJson(),
      'status': status,
      'userId': userId,
      'customer': customer?.toJson(),
      'driver': driver?.toJson(),
      'driverPayment': driverPayment,
      'totalDistance': totalDistance,
      'distanceRemain': distanceRemain,
      'totalTime': totalTime,
      'timeRemain': timeRemain,
      'tax': tax,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'travelCharges': travelCharges,
      'vehicleDetails': vehicleDetails?.toJson(),
      'customerFeeback': customerFeedback?.toJson(),
      'driverFeeback': driverFeedback?.toJson(),
      'parcelData': parcalData?.toJson(),
      'driverConfirmedPayment': driverConfirmedPayment,
      'riderConfirmedPayment': riderConfirmedPayment,
      'timestamp': timestamp,
    };
  }

  setTotalTime(value) {
    totalTime = value;
  }
}

class Location {
  double? lat;
  double? lng;
  String? pickupAddress;
  String? dropoffAddress;

  Location();

  Location.fromMap(Map<dynamic, dynamic>? map) {
    lat = (map?['lat'] as num?)?.toDouble();
    lng = (map?['lng'] as num?)?.toDouble();
    pickupAddress = map?['pickupAddress'];
    dropoffAddress = map?['dropoffAddress'];
  }
  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
    };
  }
}

class Customer {
  String? userName;
  String? userPhone;
  String? userPhoto;
  String? userRating;

  Customer();

  Customer.fromMap(Map<dynamic, dynamic>? map) {
    userName = map?['userName'];
    userPhone = map?['userPhone'];
    userPhoto = map?['userPhoto'];
    userRating = map?['userRating'];
  }
  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userPhone': userPhone,
      'userPhoto': userPhoto,
      'userRating': userRating,
    };
  }
}

class Driver {
  String? driverName;
  String? driverPhone;
  String? driverPhoto;
  String? driverRating;

  Driver();

  Driver.fromMap(Map<dynamic, dynamic>? map) {
    driverName = map?['driverName'];
    driverPhone = map?['driverPhone'];
    driverPhoto = map?['driverPhoto'];
    driverRating = map?['driverRating'];
  }
  Map<String, dynamic> toJson() {
    return {
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverPhoto': driverPhoto,
      'driverRating': driverRating,
    };
  }
}

class VehicleDetails {
  String? itemId;
  String? itemTypeName;
  String? vehicleNumber;
  String? vehicleMake;
  String? vehicleModel;

  VehicleDetails();

  VehicleDetails.fromMap(Map<dynamic, dynamic>? map) {
    itemId = map?['itemId'].toString();
    itemTypeName = map?['itemTypeName'];
    vehicleNumber = map?['vehicleNumber'];
    vehicleMake = map?['vehicleMake'];
    vehicleModel = map?['vehicleModel'];
  }
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemTypeName': itemTypeName,
      'vehicleNumber': vehicleNumber,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
    };
  }
}

class FeedbackData {
  String? rating;
  String? review;

  FeedbackData();

  FeedbackData.fromMap(Map<dynamic, dynamic>? map) {
    rating = map?['rating'];
    review = map?['review'];
  }
  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'review': review,
    };
  }
}

class ParcalData {
  String? name;
  String? weight;
  String? reciverName;
  String? reciverNumber;
  String? instruction;

  ParcalData();
  ParcalData.fromMap(Map<dynamic, dynamic>? map) {
    name = map?['name'];
    weight = map?['weight'];
    reciverName = map?['receiverName'];
    reciverNumber = map?['receiverPhone'];
    instruction = map?['pickupInstructions'];
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'receiverName': reciverName,
      'receiverPhone': reciverNumber,
      'pickupInstructions': instruction,
    };
  }
}
