class GetItemPrice {
  int? status;
  String? message;
  Data? data;
  String? error;

  GetItemPrice({this.status, this.message, this.data, this.error});

  GetItemPrice.fromJson(Map<String, dynamic> json) {
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
  dynamic distance;
  String? pricePerKm;
  String? priceBeforeDiscount;
  String? couponDiscount;
  String? walletAmount;
  String? remainingWalletBalance;
  String? grossPrice;
  String? adminCommissionPercent;
  String? adminCommissionAmount;
  String? couponCode;
  String? pricingType;

  Data(
      {this.distance,
      this.pricePerKm,
      this.priceBeforeDiscount,
      this.couponDiscount,
      this.walletAmount,
      this.remainingWalletBalance,
      this.grossPrice,
      this.adminCommissionPercent,
      this.adminCommissionAmount,
      this.couponCode,
      this.pricingType});

  Data.fromJson(Map<String, dynamic> json) {
    distance = json['distance'];
    pricePerKm = json['price_per_km'];
    priceBeforeDiscount = json['price_before_discount'];
    couponDiscount = json['coupon_discount'];
    walletAmount = json['wallet_amount'];
    remainingWalletBalance = json['remaining_wallet_balance'];
    grossPrice = json['gross_price'];
    adminCommissionPercent = json['admin_commission_percent'];
    adminCommissionAmount = json['admin_commission_amount'];
    couponCode = json['coupon_code'];
    pricingType = json['pricing_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['distance'] = distance;
    data['price_per_km'] = pricePerKm;
    data['price_before_discount'] = priceBeforeDiscount;
    data['coupon_discount'] = couponDiscount;
    data['wallet_amount'] = walletAmount;
    data['remaining_wallet_balance'] = remainingWalletBalance;
    data['gross_price'] = grossPrice;
    data['admin_commission_percent'] = adminCommissionPercent;
    data['admin_commission_amount'] = adminCommissionAmount;
    data['coupon_code'] = couponCode;
    data['pricing_type'] = pricingType;
    return data;
  }
}
