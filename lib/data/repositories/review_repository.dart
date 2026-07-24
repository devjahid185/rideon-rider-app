import 'package:ride_on/core/services/http.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/material.dart';

import '../../core/services/config.dart';

class ReviewRepository {
  Future<Map<String, dynamic>> submitReview(
      {required BuildContext context,
      required String bookingId,
      required String rating,
      required String message}) async {
    try {
      var response = await httpPost(
        Config.giveReviewByUser,
        context: navigatorKey.currentContext!,
        {"booking_id": bookingId, "rating": rating, "message": message},
      );
      return response;
    } catch (error) {
      rethrow;
    }
  }
}
