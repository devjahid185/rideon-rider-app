import 'package:flutter/foundation.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:ride_on/core/services/config.dart';
import 'package:ride_on/core/services/http.dart';

class FoodRepository {
  Future<Map<String, dynamic>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radiusKm = 8,
    int limit = 20,
  }) async {
    debugPrint(
      '[FoodRepository] nearby request '
      'lat=$latitude lng=$longitude radius=$radiusKm limit=$limit',
    );
    final response = await httpGet(
      Config.foodNearbyRestaurants,
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius_km': radiusKm.toString(),
        'limit': limit.toString(),
      },
      context: navigatorKey.currentContext!,
    );
    final mapped = Map<String, dynamic>.from(response ?? {});
    final data = mapped['data'];
    debugPrint(
      '[FoodRepository] nearby response '
      'status=${mapped['status']} message=${mapped['message'] ?? mapped['error']} '
      'dataType=${data.runtimeType} count=${data is List ? data.length : 'n/a'}',
    );
    return mapped;
  }

  Future<Map<String, dynamic>> getRestaurantMenu({
    required int restaurantId,
  }) async {
    final response = await httpGet(
      '${Config.foodRestaurantMenu}/$restaurantId/menu',
      {},
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> createFoodOrder({
    required Map<String, dynamic> payload,
  }) async {
    final response = await httpPost(
      Config.foodCreateOrder,
      payload,
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> getMyFoodOrders({
    String? status,
    int limit = 20,
  }) async {
    final response = await httpGet(
      Config.foodMyOrders,
      {
        'token': token,
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': limit.toString(),
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      },
      context: navigatorKey.currentContext!,
    );
    final mapped = Map<String, dynamic>.from(response ?? {});
    final data = mapped['data'];
    debugPrint(
      '[FoodRepository] my orders response '
      'status=${mapped['status']} message=${mapped['message'] ?? mapped['error']} '
      'loggedInUserId=${loginModel?.data?.id ?? 'unknown'} '
      'dataType=${data.runtimeType} count=${data is List ? data.length : 'n/a'} '
      'orders=${data is List ? data.whereType<Map>().map((order) => '${order['id']}:${order['order_number']}:${order['status']}:${order['payment_status']}').join(',') : 'n/a'}',
    );
    return mapped;
  }

  Future<Map<String, dynamic>> getFoodOrderDetails({
    required int orderId,
  }) async {
    final response = await httpGet(
      '${Config.foodOrderDetails}/$orderId',
      {
        'token': token,
      },
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> getFoodOrderTimeline({
    required int orderId,
  }) async {
    final response = await httpGet(
      '${Config.foodOrderTimeline}/$orderId/timeline',
      {
        'token': token,
      },
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }
}
