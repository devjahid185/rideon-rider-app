import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ride_on/core/services/config.dart';
import 'package:ride_on/core/services/data_store.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
import 'package:ride_on/core/utils/theme/theme_style.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/domain/entities/food_models.dart';
import 'package:ride_on/presentation/cubits/food_cubit.dart';
import 'package:ride_on/presentation/screens/food/food_menu_screen.dart';
import 'package:ride_on/presentation/screens/food/food_orders_screen.dart';

const Color _foodBg = Color(0xFFF7FAFF);
const Color _ink = Color(0xFF241916);

class FoodHomeScreen extends StatefulWidget {
  const FoodHomeScreen({super.key});

  @override
  State<FoodHomeScreen> createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends State<FoodHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodRestaurant> _cachedRestaurants = [];
  bool _isLoadingLocation = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    final current = context.read<FoodCubit>().state;
    if (current is FoodNearbyRestaurantsLoaded) {
      _cachedRestaurants = current.restaurants;
    } else {
      _initializeAndLoadRestaurants();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoadRestaurants({bool forceGps = false}) async {
    final cachedLat = double.tryParse(
      (box.get('last_latitude') ?? '').toString(),
    );
    final cachedLng = double.tryParse(
      (box.get('last_longitude') ?? '').toString(),
    );
    if (!forceGps &&
        cachedLat != null &&
        cachedLng != null &&
        cachedLat != 0 &&
        cachedLng != 0 &&
        _cachedRestaurants.isEmpty) {
      debugPrint(
        '[FoodAllRestaurants] loading immediately from cached location '
        'lat=$cachedLat lng=$cachedLng',
      );
      context.read<FoodCubit>().loadNearbyRestaurants(
        latitude: cachedLat,
        longitude: cachedLng,
        radiusKm: 30,
      );
      return;
    }

    setState(() => _isLoadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      debugPrint(
        '[FoodAllRestaurants] loading from GPS location '
        'lat=${position.latitude} lng=${position.longitude}',
      );
      box.put('last_latitude', position.latitude);
      box.put('last_longitude', position.longitude);
      context.read<FoodCubit>().loadNearbyRestaurants(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 30,
      );
    } catch (e) {
      if (!mounted) return;
      context.read<FoodCubit>().showFailure(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  List<String> _categories(List<FoodRestaurant> restaurants) {
    final names = <String>{'All'};
    for (final restaurant in restaurants) {
      for (final category in restaurant.categories) {
        if (category.name.trim().isNotEmpty) {
          names.add(category.name.trim());
        }
      }
    }
    return names.toList();
  }

  List<FoodRestaurant> _filteredRestaurants(List<FoodRestaurant> restaurants) {
    final query = _searchController.text.trim().toLowerCase();
    return restaurants.where((restaurant) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          restaurant.categories.any(
            (category) =>
                category.name.toLowerCase() == _selectedCategory.toLowerCase(),
          );

      if (!matchesCategory) return false;
      if (query.isEmpty) return true;

      final itemNames = restaurant.categories
          .expand((category) => category.items)
          .map((item) => item.name.toLowerCase())
          .join(' ');
      final categoryNames = restaurant.categories
          .map((category) => category.name.toLowerCase())
          .join(' ');

      return restaurant.name.toLowerCase().contains(query) ||
          categoryNames.contains(query) ||
          itemNames.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _foodBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: themeColor,
          backgroundColor: Colors.white,
          onRefresh: () => _initializeAndLoadRestaurants(forceGps: true),
          child: BlocConsumer<FoodCubit, FoodState>(
            listener: (context, state) {
              if (state is FoodNearbyRestaurantsLoaded) {
                _cachedRestaurants = state.restaurants;
              }
            },
            builder: (context, state) {
              final restaurants = state is FoodNearbyRestaurantsLoaded
                  ? state.restaurants
                  : _cachedRestaurants;

              if (_isLoadingLocation ||
                  (state is FoodLoading && restaurants.isEmpty)) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (state is FoodFailure && restaurants.isEmpty) {
                return _buildMessageState(
                  icon: Icons.error_outline_rounded,
                  message: state.message,
                );
              }

              final filtered = _filteredRestaurants(restaurants);
              return _buildContent(restaurants, filtered);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _ink,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FoodOrdersScreen()),
          );
        },
        label: Text(
          'My Orders'.translate(context),
          style: regular2(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        icon: const Icon(
          Icons.receipt_long_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildContent(
    List<FoodRestaurant> restaurants,
    List<FoodRestaurant> filteredRestaurants,
  ) {
    final categories = _categories(restaurants);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        _buildHero(restaurants.length),
        const SizedBox(height: 18),
        _buildSearchBox(),
        const SizedBox(height: 18),
        _buildCategoryChips(categories),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Restaurants near you'.translate(context),
              style: heading3Grey1(
                context,
              ).copyWith(color: _ink, fontWeight: FontWeight.w900),
            ),
            Text(
              '${filteredRestaurants.length} found',
              style: regular2(context).copyWith(
                color: Colors.black.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (restaurants.isEmpty)
          _InlineEmptyState(
            icon: Icons.storefront_rounded,
            title: 'No nearby restaurants found'.translate(context),
            subtitle:
                'Try refreshing or increasing delivery coverage from restaurant branch settings.'
                    .translate(context),
          )
        else if (filteredRestaurants.isEmpty)
          _InlineEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching food found'.translate(context),
            subtitle: 'Try a restaurant name, item name, or another category.'
                .translate(context),
          )
        else
          ...filteredRestaurants.map((restaurant) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: RestaurantCard(restaurant: restaurant),
            );
          }),
      ],
    );
  }

  Widget _buildHero(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D56A5), Color(0xFF0F2F63)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D56A5).withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Food Delivery'.translate(context),
                  style: heading2Grey1(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _initializeAndLoadRestaurants,
                  child: const Padding(
                    padding: EdgeInsets.all(11),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FoodOrdersScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: themeColor,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Order your favourites from local restaurants with live tracking.'
                .translate(context),
            style: regular2(context).copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                icon: Icons.storefront_rounded,
                text: '$count restaurants',
              ),
              const _HeroPill(icon: Icons.timer_rounded, text: 'Fast delivery'),
              const _HeroPill(icon: Icons.verified_rounded, text: 'Fresh menu'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search biryani, burger, pizza...'.translate(context),
          prefixIcon: Icon(Icons.search_rounded, color: themeColor),
          suffixIcon: _searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: _searchController.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final category = categories[index];
          final selected = category == _selectedCategory;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Text(category.translate(context)),
            labelStyle: regular2(context).copyWith(
              color: selected ? Colors.white : _ink,
              fontWeight: FontWeight.w800,
            ),
            backgroundColor: Colors.white,
            selectedColor: themeColor,
            side: BorderSide(
              color: selected
                  ? themeColor
                  : Colors.black.withValues(alpha: 0.06),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildMessageState({required IconData icon, required String message}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        _InlineEmptyState(
          icon: icon,
          title: message,
          subtitle: 'Pull down to retry loading restaurants.'.translate(
            context,
          ),
        ),
      ],
    );
  }
}

class RestaurantCard extends StatelessWidget {
  final FoodRestaurant restaurant;

  const RestaurantCard({super.key, required this.restaurant});

  String _resolveImageUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://'))
      return value;
    final normalized = value.startsWith('/') ? value : '/$value';
    return '${Config.baseDomain}$normalized';
  }

  String get _deliveryTime {
    final min = restaurant.minDeliveryTimeMinutes;
    final max = restaurant.maxDeliveryTimeMinutes;
    if (min != null && max != null) return '$min-$max min';
    if (min != null) return '$min min';
    return '25-35 min';
  }

  String get _distanceText {
    final distance = restaurant.distanceKm;
    if (distance == null) return 'Nearby';
    if (distance < 1) return '${(distance * 1000).round()} m';
    return '${distance.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _resolveImageUrl(
      restaurant.coverImage ?? restaurant.logoImage,
    );
    final logoUrl = _resolveImageUrl(restaurant.logoImage);
    final itemPreview = restaurant.categories
        .expand((category) => category.items)
        .take(3)
        .map((item) => item.name)
        .where((name) => name.trim().isNotEmpty)
        .join(' - ');
    final availabilityLabel =
        restaurant.availabilityLabel ??
        (restaurant.isAcceptingOrders ? 'Open now' : 'Closed');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodMenuScreen(restaurant: restaurant),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.black.withValues(alpha: 0.045)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: coverUrl.isNotEmpty
                          ? Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.48),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: _AvailabilityPill(
                      isOpen: restaurant.isAcceptingOrders,
                      label: availabilityLabel,
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: _MetaBadge(
                      icon: Icons.star_rounded,
                      text: (restaurant.rating ?? 0).toStringAsFixed(1),
                      color: const Color(0xFFFFB000),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Row(
                      children: [
                        _AvatarImage(imageUrl: logoUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            restaurant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: heading3Grey1(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _InfoPill(
                          icon: Icons.timer_rounded,
                          text: _deliveryTime,
                        ),
                        const SizedBox(width: 8),
                        _InfoPill(
                          icon: Icons.near_me_rounded,
                          text: _distanceText,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: themeColor,
                          size: 20,
                        ),
                      ],
                    ),
                    if ((restaurant.branchAddress ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.black.withValues(alpha: 0.35),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              restaurant.branchAddress!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: regular2(context).copyWith(
                                color: Colors.black.withValues(alpha: 0.52),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (itemPreview.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        itemPreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: regular2(context).copyWith(
                          color: Colors.black.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDDEBFF), Color(0xFFF7FAFF)],
        ),
      ),
      child: Icon(Icons.storefront_rounded, size: 44, color: themeColor),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            text,
            style: regular2(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: regular2(
              context,
            ).copyWith(color: _ink, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: themeColor, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: regular2(
              context,
            ).copyWith(color: _ink, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.isOpen, required this.label});

  final bool isOpen;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.storefront_rounded : Icons.lock_clock_rounded,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: regular2(
              context,
            ).copyWith(color: _ink, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final String imageUrl;

  const _AvatarImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.restaurant_rounded, color: themeColor),
            )
          : Icon(Icons.restaurant_rounded, color: themeColor),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InlineEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 46, color: themeColor.withValues(alpha: 0.65)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: heading3Grey1(
              context,
            ).copyWith(color: _ink, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: regular2(context).copyWith(
              color: Colors.black.withValues(alpha: 0.52),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
