import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/data/repositories/food_repository.dart';
import 'package:ride_on/domain/entities/food_models.dart';

abstract class FoodState {}

class FoodInitial extends FoodState {}

class FoodLoading extends FoodState {}

class FoodFailure extends FoodState {
  final String message;

  FoodFailure(this.message);
}

class FoodNearbyRestaurantsLoaded extends FoodState {
  final List<FoodRestaurant> restaurants;

  FoodNearbyRestaurantsLoaded(this.restaurants);
}

class FoodMenuLoaded extends FoodState {
  final int restaurantId;
  final List<FoodMenuCategory> categories;
  final int? defaultBranchId;

  FoodMenuLoaded({
    required this.restaurantId,
    required this.categories,
    required this.defaultBranchId,
  });
}

class FoodOrderCreated extends FoodState {
  final Map<String, dynamic> order;

  FoodOrderCreated(this.order);
}

class FoodMyOrdersLoaded extends FoodState {
  final List<FoodOrderSummary> orders;

  FoodMyOrdersLoaded(this.orders);
}

class FoodOrderDetailsLoaded extends FoodState {
  final Map<String, dynamic> order;

  FoodOrderDetailsLoaded(this.order);
}

class FoodOrderTimelineLoaded extends FoodState {
  final int orderId;
  final List<Map<String, dynamic>> timeline;

  FoodOrderTimelineLoaded({required this.orderId, required this.timeline});
}

class FoodCubit extends Cubit<FoodState> {
  final FoodRepository repository;
  int _myOrdersRequestId = 0;
  List<FoodOrderSummary> _myOrders = const [];

  FoodCubit(this.repository) : super(FoodInitial());

  List<FoodOrderSummary> get myOrders =>
      List<FoodOrderSummary>.unmodifiable(_myOrders);

  List<Map<String, dynamic>> _extractOrderMaps(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final mapped = Map<String, dynamic>.from(data);
      for (final key in ['orders', 'data', 'items', 'results']) {
        final nested = mapped[key];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return const [];
  }

  List<FoodOrderSummary> _parseOrders(List<Map<String, dynamic>> rawOrders) {
    final ordersById = <int, FoodOrderSummary>{};
    for (final rawOrder in rawOrders) {
      final order = FoodOrderSummary.fromJson(rawOrder);
      if (order.id != 0) {
        ordersById[order.id] = order;
      }
    }
    return ordersById.values.toList()..sort((a, b) => b.id.compareTo(a.id));
  }

  void rememberOrder(Map<String, dynamic> orderJson) {
    if (orderJson.isEmpty) return;
    final order = FoodOrderSummary.fromJson(orderJson);
    if (order.id == 0) return;
    final updated = [
      order,
      ..._myOrders.where((existing) => existing.id != order.id),
    ]..sort((a, b) => b.id.compareTo(a.id));
    _myOrders = updated;
    emit(FoodMyOrdersLoaded(myOrders));
  }

  void showFailure(String message) {
    debugPrint('[FoodCubit] failure forced message=$message');
    emit(FoodFailure(message));
  }

  Future<void> loadNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radiusKm = 8,
  }) async {
    debugPrint(
      '[FoodCubit] loadNearbyRestaurants start '
      'lat=$latitude lng=$longitude radius=$radiusKm',
    );
    emit(FoodLoading());
    try {
      final response = await repository.getNearbyRestaurants(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      debugPrint(
        '[FoodCubit] loadNearbyRestaurants parsed response '
        'status=${response['status']} message=${response['message'] ?? response['error']}',
      );
      if (response['status'] == 200) {
        final List raw = (response['data'] as List?) ?? [];
        final restaurants = raw
            .whereType<Map>()
            .map((e) => FoodRestaurant.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        debugPrint('[FoodCubit] nearby loaded count=${restaurants.length}');
        emit(FoodNearbyRestaurantsLoaded(restaurants));
        return;
      }
      final message =
          (response['message'] ??
                  response['error'] ??
                  'Failed to load restaurants')
              .toString();
      debugPrint(
        '[FoodCubit] nearby failed message=$message response=$response',
      );
      emit(FoodFailure(message));
    } catch (e) {
      debugPrint('[FoodCubit] nearby exception=$e');
      emit(FoodFailure(e.toString()));
    }
  }

  Future<void> loadRestaurantMenu(int restaurantId) async {
    emit(FoodLoading());
    try {
      final response = await repository.getRestaurantMenu(
        restaurantId: restaurantId,
      );
      if (response['status'] == 200) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final List raw = (data['categories'] as List?) ?? [];
        final List branches = (data['branches'] as List?) ?? [];
        int? branchId;
        if (branches.isNotEmpty && branches.first is Map) {
          final firstBranch = Map<String, dynamic>.from(branches.first);
          branchId = int.tryParse((firstBranch['id'] ?? '').toString());
        }
        final categories = raw
            .whereType<Map>()
            .map((e) => FoodMenuCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        emit(
          FoodMenuLoaded(
            restaurantId: restaurantId,
            categories: categories,
            defaultBranchId: branchId,
          ),
        );
        return;
      }
      emit(
        FoodFailure((response['message'] ?? 'Failed to load menu').toString()),
      );
    } catch (e) {
      emit(FoodFailure(e.toString()));
    }
  }

  Future<void> createOrder(Map<String, dynamic> payload) async {
    emit(FoodLoading());
    try {
      final response = await repository.createFoodOrder(payload: payload);
      if (response['status'] == 200 || response['status'] == 201) {
        emit(
          FoodOrderCreated((response['data'] as Map<String, dynamic>?) ?? {}),
        );
        return;
      }
      emit(
        FoodFailure(
          (response['message'] ?? 'Failed to create order').toString(),
        ),
      );
    } catch (e) {
      emit(FoodFailure(e.toString()));
    }
  }

  Future<void> loadMyOrders({String? status}) async {
    final requestId = ++_myOrdersRequestId;
    if (state is! FoodMyOrdersLoaded) {
      emit(FoodLoading());
    }
    try {
      final response = await repository.getMyFoodOrders(status: status);
      if (requestId != _myOrdersRequestId) return;

      if (response['status'] == 200) {
        final orders = _parseOrders(_extractOrderMaps(response['data']));
        _myOrders = orders;
        debugPrint('[FoodCubit] my orders loaded count=${orders.length}');
        emit(FoodMyOrdersLoaded(myOrders));
        return;
      }
      emit(
        FoodFailure(
          (response['message'] ?? 'Failed to load orders').toString(),
        ),
      );
    } catch (e) {
      if (requestId != _myOrdersRequestId) return;
      emit(FoodFailure(e.toString()));
    }
  }

  Future<void> loadOrderDetails(int orderId) async {
    emit(FoodLoading());
    try {
      final response = await repository.getFoodOrderDetails(orderId: orderId);
      if (response['status'] == 200) {
        emit(
          FoodOrderDetailsLoaded(
            (response['data'] as Map<String, dynamic>?) ?? {},
          ),
        );
        return;
      }
      emit(
        FoodFailure(
          (response['message'] ?? 'Failed to load order details').toString(),
        ),
      );
    } catch (e) {
      emit(FoodFailure(e.toString()));
    }
  }

  Future<void> loadOrderTimeline(int orderId) async {
    emit(FoodLoading());
    try {
      final response = await repository.getFoodOrderTimeline(orderId: orderId);
      if (response['status'] == 200) {
        final List raw = (response['data'] as List?) ?? [];
        final timeline = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        emit(FoodOrderTimelineLoaded(orderId: orderId, timeline: timeline));
        return;
      }
      emit(
        FoodFailure(
          (response['message'] ?? 'Failed to load order timeline').toString(),
        ),
      );
    } catch (e) {
      emit(FoodFailure(e.toString()));
    }
  }
}
