import 'package:ride_on/core/services/http.dart';
import 'package:flutter/material.dart';

import '../../core/services/config.dart';

class HistoryRepository {
  Future<Map<String, dynamic>> getHistoryData({
    required BuildContext context,
    required Map<String, dynamic> bookingKeyMap,
  }) async {
    try {
      var response =
          await httpPost(Config.bookingRecord, bookingKeyMap, context: context);

      return response;
    } catch (err) {
      rethrow;
    }
  }
}
