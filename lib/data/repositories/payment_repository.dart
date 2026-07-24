import 'package:ride_on/core/extensions/workspace.dart';
import 'package:ride_on/core/services/http.dart';
import 'package:flutter/material.dart';

import '../../core/services/config.dart';

class PaymentRepository {
  Future<Map<String, dynamic>> updatePaymentStatusByUser(
      {required BuildContext context,
      required String bookingId,
      required String paymentMethod}) async {
    try {
      var response = await httpPost(
        Config.updatePaymentStatusByUser,
        context: context,
        {"booking_id": bookingId, "payment_method": paymentMethod},
      );
      return response;
    } catch (error) {
      rethrow;
    }
  }


  Future<Map<String, dynamic>> applyCoupon(
      {required Map<String, dynamic> postData}) async {
    try {
      var response = await httpPost(Config.getItemPrices, postData,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
