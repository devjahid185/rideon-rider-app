import 'package:ride_on/core/services/http.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/material.dart';

import '../../core/services/config.dart';

class VehicleRepository {
  Future<Map<String, dynamic>> getCategories() async {
    try {
      var response = await httpGet(
          context: navigatorKey.currentContext!, Config.getAllCategories, {});
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getServiceType() async {
    try {
      var response = await httpGet(
          context: navigatorKey.currentContext!, Config.serviceTypes, {});
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getItemTypesByService(String id) async {
    try {
      var response = await httpGet(
          context: navigatorKey.currentContext!,
          Config.getItemTypesByService,
          {"service_type_id": id});
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getItemPrice(
      {required int itemTypeId,
      required double distance,
      required BuildContext context}) async {
    try {
      Map<String, dynamic> mapData = {
        "item_type_id": itemTypeId,
        "distance": distance,
        "coupon_code": "",
        "wallet_amount": "",
        "selected_currency_code": "USD"
      };
      final response = await httpPost(
        Config.getItemPrices,
        mapData,
        context: context,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> bookRide(
      {required int itemTypeId,
      required String rideId,
      required String driverId,
      required String totalFare,
      required String serviceTypeId,
      required BuildContext context,
      required String itemId,
      required String estimatedDistance,
      required String pickupAddress,
      required String dropOffAddress,
      required String date,
      required String pickupLat,
      required String pickupLng,
      required String paymentMethod,
      required String dropOffLat,
      required String dropOffLng}) async {
    try {
      Map<String, dynamic> mapData = {
        "ride_id": rideId,
        "item_id": itemId,
        "driver_id": driverId,
        "ride_date": date,
        "item_type_id": itemTypeId,
        "pickup_latitude": pickupLat,
        "pickup_longitude": pickupLng,
        "dropoff_latitude": dropOffLat,
        "dropoff_longitude": dropOffLng,
        "estimated_distance_km": estimatedDistance,
        "pickup_address": pickupAddress,
        "dropoff_address": dropOffAddress,
        "service_charge": "",
        "wallet_amount": "",
        "payment_method": "",
        "currency_code": currency,
        "coupon_code": "",
        "coupon_discount": "",
        "discount_price": "",
        "amount_to_pay": totalFare,
        "estimated_duration_min": "",
        "service_type_id": serviceTypeId,
      };
      final response = await httpPost(
        Config.bookItem,
        mapData,
        context: context,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateRideStatus(
      {required BuildContext context,
      required String bookingId,
      required String rideStatus}) async {
    try {
      var response = await httpPost(Config.updateBookingStatusByUser,
          {"booking_id": bookingId, "status": rideStatus},
          context: context);
      return response;
    } catch (error) {
      rethrow;
    }
  }
}
