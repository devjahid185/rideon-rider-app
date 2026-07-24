import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/core/services/config.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
import 'package:ride_on/core/utils/theme/theme_style.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/domain/entities/food_models.dart';
import 'package:ride_on/presentation/cubits/food_cubit.dart';
import 'package:ride_on/presentation/screens/food/food_checkout_screen.dart';
import 'package:ride_on/presentation/screens/food/food_orders_screen.dart';

// Defined globally so all widgets in this file can use the same modern background
const Color scaffoldBgColor = Color(0xFFF8F9FA);

class FoodMenuScreen extends StatefulWidget {
  final FoodRestaurant restaurant;

  const FoodMenuScreen({super.key, required this.restaurant});

  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> {
  final Map<int, int> _cartQty = {};
  final Map<int, FoodMenuItem> _cartItems = {};
  int? _selectedCategoryId;
  FoodMenuLoaded? _cachedMenu;

  @override
  void initState() {
    super.initState();
    context.read<FoodCubit>().loadRestaurantMenu(widget.restaurant.id);
  }

  double get _cartTotal {
    double total = 0;
    _cartQty.forEach((itemId, qty) {
      final item = _cartItems[itemId];
      if (item != null) {
        total += item.basePrice * qty;
      }
    });
    return total;
  }

  int get _cartCount => _cartQty.values.fold(0, (sum, qty) => sum + qty);

  String _resolveImageUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    final normalized = value.startsWith('/') ? value : '/$value';
    return '${Config.baseDomain}$normalized';
  }

  String get _deliveryTime {
    final min = widget.restaurant.minDeliveryTimeMinutes;
    final max = widget.restaurant.maxDeliveryTimeMinutes;
    if (min != null && max != null) return '$min-$max min';
    if (min != null) return '$min min';
    return '25-35 min';
  }

  String get _distanceText {
    final distance = widget.restaurant.distanceKm;
    if (distance == null) return 'Nearby';
    if (distance < 1) return '${(distance * 1000).round()} m';
    return '${distance.toStringAsFixed(1)} km';
  }

  void _increment(FoodMenuItem item) {
    if (!widget.restaurant.isAcceptingOrders) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant is currently closed. You can browse the menu, but ordering is unavailable.'.translate(context))),
      );
      return;
    }
    final current = _cartQty[item.id] ?? 0;
    setState(() {
      _cartQty[item.id] = current + 1;
      _cartItems[item.id] = item;
    });
  }

  void _decrement(FoodMenuItem item) {
    final current = _cartQty[item.id] ?? 0;
    if (current <= 0) return;
    setState(() {
      if (current == 1) {
        _cartQty.remove(item.id);
        _cartItems.remove(item.id);
      } else {
        _cartQty[item.id] = current - 1;
      }
    });
  }

  Future<void> _showCheckoutSheet(FoodMenuLoaded menuState) async {
    if (_cartQty.isEmpty) return;
    if (!widget.restaurant.isAcceptingOrders) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant is currently closed. Please order when it opens.'.translate(context))),
      );
      return;
    }
    final branchId = widget.restaurant.branchId ?? menuState.defaultBranchId;
    if (branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No active branch found for this restaurant'.translate(context))),
      );
      return;
    }

    final placed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodCheckoutScreen(
          restaurant: widget.restaurant,
          branchId: branchId,
          cartQty: Map<int, int>.from(_cartQty),
          cartItems: Map<int, FoodMenuItem>.from(_cartItems),
        ),
      ),
    );

    if (placed == true && mounted) {
      setState(() {
        _cartQty.clear();
        _cartItems.clear();
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FoodOrdersScreen()),
      );
    }
  }

  Future<void> _openMyFoodOrders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FoodOrdersScreen()),
    );

    if (!mounted) return;
    context.read<FoodCubit>().loadRestaurantMenu(widget.restaurant.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: scaffoldBgColor,
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.black87),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Restaurant'.translate(context),
          style: heading3Grey1(context).copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.black87),
            onPressed: _openMyFoodOrders,
          ),
        ],
      ),
      body: BlocConsumer<FoodCubit, FoodState>(
        listener: (context, state) {
          if (state is FoodMenuLoaded &&
              state.restaurantId == widget.restaurant.id) {
            _cachedMenu = state;
          } else if (state is FoodOrderCreated) {
            setState(() {
              _cartQty.clear();
              _cartItems.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order placed successfully'.translate(context))),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FoodOrdersScreen()),
            );
          } else if (state is FoodFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final activeMenu = state is FoodMenuLoaded &&
                  state.restaurantId == widget.restaurant.id
              ? state
              : _cachedMenu;

          if (state is FoodLoading && activeMenu == null) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state is FoodFailure && activeMenu == null) {
            return Center(
              child: Text(state.message, style: regular2(context).copyWith(color: Colors.grey.shade600)),
            );
          }
          if (activeMenu != null) {
            _cachedMenu = activeMenu;
            _selectedCategoryId ??= activeMenu.categories.isNotEmpty
                ? activeMenu.categories.first.id
                : null;
            if (activeMenu.categories.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildRestaurantHero(),
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No menu found'.translate(context),
                          style: regular2(context).copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final visibleCategories = _selectedCategoryId == null
                ? activeMenu.categories
                : activeMenu.categories
                    .where((category) =>
                        category.id == _selectedCategoryId)
                    .toList();

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      _buildRestaurantHero(),
                      const SizedBox(height: 18),
                      _buildCategorySelector(activeMenu.categories),
                      const SizedBox(height: 10),
                      ...visibleCategories.map((category) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category.name,
                                      style: heading2Grey1(context).copyWith(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 21,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${category.items.length} items',
                                    style: regular2(context).copyWith(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...category.items.map((item) {
                              final qty = _cartQty[item.id] ?? 0;
                              return FoodItemCard(
                                item: item,
                                quantity: qty,
                                onIncrement: () => _increment(item),
                                onDecrement: () => _decrement(item),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                if (_cartQty.isNotEmpty)
                  _buildBottomCartBar(context, activeMenu),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBottomCartBar(BuildContext context, FoodMenuLoaded state) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 16, 
        bottom: MediaQuery.of(context).padding.bottom > 0 
            ? MediaQuery.of(context).padding.bottom 
            : 16
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_cartCount items',
                    style: regular2(context).copyWith(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    '\$${_cartTotal.toStringAsFixed(2)}',
                    style: heading2Grey1(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.restaurant.isAcceptingOrders ? themeColor : Colors.grey,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: widget.restaurant.isAcceptingOrders
                  ? () => _showCheckoutSheet(state)
                  : null,
              child: Row(
                children: [
                  Text(
                    (widget.restaurant.isAcceptingOrders ? 'Checkout' : 'Closed').translate(context),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantHero() {
    final coverUrl = _resolveImageUrl(widget.restaurant.coverImage ?? widget.restaurant.logoImage);
    final logoUrl = _resolveImageUrl(widget.restaurant.logoImage);
    final address = (widget.restaurant.branchAddress ?? '').trim();
    final availabilityLabel = (widget.restaurant.availabilityLabel ?? (widget.restaurant.isAcceptingOrders ? 'Open now' : 'Closed')).trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _restaurantPlaceholder(),
                        )
                      : _restaurantPlaceholder(),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.58),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: logoUrl.isNotEmpty
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.restaurant_rounded, color: themeColor),
                            )
                          : Icon(Icons.restaurant_rounded, color: themeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: heading2Grey1(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _AvailabilityBadge(
                            isOpen: widget.restaurant.isAcceptingOrders,
                            label: availabilityLabel,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Freshly prepared food delivered to your door'.translate(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: regular2(context).copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MenuMetaPill(
                      icon: Icons.star_rounded,
                      text: (widget.restaurant.rating ?? 0).toStringAsFixed(1),
                      color: const Color(0xFFFFB000),
                    ),
                    _MenuMetaPill(
                      icon: Icons.timer_rounded,
                      text: _deliveryTime,
                      color: themeColor,
                    ),
                    _MenuMetaPill(
                      icon: Icons.near_me_rounded,
                      text: _distanceText,
                      color: Colors.teal,
                    ),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: themeColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: regular2(context).copyWith(
                            color: Colors.black.withValues(alpha: 0.58),
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(List<FoodMenuCategory> categories) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final category = categories[index];
          final selected = category.id == _selectedCategoryId;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Text(category.name),
            labelStyle: regular2(context).copyWith(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w800,
            ),
            backgroundColor: Colors.white,
            selectedColor: themeColor,
            side: BorderSide(
              color: selected ? themeColor : Colors.black.withValues(alpha: 0.06),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (_) => setState(() => _selectedCategoryId = category.id),
          );
        },
      ),
    );
  }

  Widget _restaurantPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDDEBFF), Color(0xFFF7FAFF)],
        ),
      ),
      child: Icon(Icons.restaurant_rounded, color: themeColor, size: 48),
    );
  }
}

class _MenuMetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MenuMetaPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: regular2(context).copyWith(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class FoodItemCard extends StatelessWidget {
  final FoodMenuItem item;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const FoodItemCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  String _resolveImageUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    final normalized = value.startsWith('/') ? value : '/$value';
    return '${Config.baseDomain}$normalized';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(item.image);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: heading3Grey1(context).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Popular',
                        style: regular2(context).copyWith(
                          fontSize: 10,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: regular2(context).copyWith(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${item.basePrice.toStringAsFixed(2)}',
                      style: heading3Grey1(context).copyWith(
                        color: themeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    _buildCounter(context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(BuildContext context) {
    if (quantity == 0) {
      return InkWell(
        onTap: onIncrement,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Add',
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scaffoldBgColor, 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CounterButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            color: Colors.grey.shade600,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: heading3Grey1(context).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            color: themeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.fastfood_rounded, color: Colors.grey.shade300, size: 32),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({
    required this.isOpen,
    required this.label,
  });

  final bool isOpen;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.storefront_rounded : Icons.lock_clock_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

