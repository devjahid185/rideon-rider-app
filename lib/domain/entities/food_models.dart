class FoodRestaurant {
  final int id;
  final String name;
  final String? logoImage;
  final String? coverImage;
  final double? rating;
  final String? branchName;
  final int? branchId;
  final String? branchAddress;
  final double? distanceKm;
  final double? deliveryRadiusKm;
  final int? minDeliveryTimeMinutes;
  final int? maxDeliveryTimeMinutes;
  final bool isOpen;
  final bool isAcceptingOrders;
  final String? availabilityLabel;
  final String? openingTime;
  final String? closingTime;
  final List<FoodMenuCategory> categories;

  FoodRestaurant({
    required this.id,
    required this.name,
    this.logoImage,
    this.coverImage,
    this.rating,
    this.branchName,
    this.branchId,
    this.branchAddress,
    this.distanceKm,
    this.deliveryRadiusKm,
    this.minDeliveryTimeMinutes,
    this.maxDeliveryTimeMinutes,
    this.isOpen = true,
    this.isAcceptingOrders = true,
    this.availabilityLabel,
    this.openingTime,
    this.closingTime,
    this.categories = const [],
  });

  factory FoodRestaurant.fromJson(Map<String, dynamic> json) {
    final restaurant = json['restaurant'] is Map
        ? Map<String, dynamic>.from(json['restaurant'] as Map)
        : json;
    final rawCategories = (restaurant['categories'] as List?) ?? [];
    return FoodRestaurant(
      id: int.tryParse((restaurant['id'] ?? 0).toString()) ?? 0,
      name: (restaurant['name'] ?? '').toString(),
      logoImage: restaurant['logo_image']?.toString(),
      coverImage: restaurant['cover_image']?.toString(),
      rating: double.tryParse((restaurant['rating'] ?? '').toString()),
      branchId: int.tryParse((json['id'] ?? '').toString()),
      branchName: json['name']?.toString(),
      branchAddress: json['address']?.toString(),
      distanceKm: double.tryParse((json['distance_km'] ?? '').toString()),
      deliveryRadiusKm:
          double.tryParse((json['delivery_radius_km'] ?? '').toString()),
      minDeliveryTimeMinutes:
          int.tryParse((json['min_delivery_time_minutes'] ?? '').toString()),
      maxDeliveryTimeMinutes:
          int.tryParse((json['max_delivery_time_minutes'] ?? '').toString()),
      isOpen: json['effective_is_open'] == true || json['is_open'] == true,
      isAcceptingOrders:
          json['is_accepting_orders'] == true || json['effective_is_open'] == true,
      availabilityLabel: json['availability_label']?.toString(),
      openingTime: json['opening_time']?.toString(),
      closingTime: json['closing_time']?.toString(),
      categories: rawCategories
          .whereType<Map>()
          .map((e) => FoodMenuCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class FoodMenuCategory {
  final int id;
  final String name;
  final List<FoodMenuItem> items;

  FoodMenuCategory({
    required this.id,
    required this.name,
    required this.items,
  });

  factory FoodMenuCategory.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? [];
    return FoodMenuCategory(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      items: rawItems
          .whereType<Map>()
          .map((e) => FoodMenuItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class FoodMenuItem {
  final int id;
  final String name;
  final String description;
  final double basePrice;
  final String? image;

  FoodMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    this.image,
  });

  factory FoodMenuItem.fromJson(Map<String, dynamic> json) {
    return FoodMenuItem(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      basePrice: double.tryParse((json['base_price'] ?? 0).toString()) ?? 0,
      image: json['image']?.toString(),
    );
  }
}

class FoodOrderSummary {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final double totalAmount;
  final String? restaurantName;
  final String? restaurantLogo;
  final String? branchAddress;
  final String? createdAt;

  FoodOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.totalAmount,
    this.restaurantName,
    this.restaurantLogo,
    this.branchAddress,
    this.createdAt,
  });

  factory FoodOrderSummary.fromJson(Map<String, dynamic> json) {
    final restaurant = json['restaurant'] is Map
        ? Map<String, dynamic>.from(json['restaurant'] as Map)
        : <String, dynamic>{};
    final branch = json['branch'] is Map
        ? Map<String, dynamic>.from(json['branch'] as Map)
        : <String, dynamic>{};

    return FoodOrderSummary(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      orderNumber: (json['order_number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? '').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      totalAmount: double.tryParse((json['total_amount'] ?? 0).toString()) ?? 0,
      restaurantName: restaurant['name']?.toString(),
      restaurantLogo: restaurant['logo_image']?.toString(),
      branchAddress: branch['address']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
