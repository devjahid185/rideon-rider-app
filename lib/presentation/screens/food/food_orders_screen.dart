import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:ride_on/core/services/config.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
import 'package:ride_on/core/utils/theme/theme_style.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/domain/entities/food_models.dart';
import 'package:ride_on/presentation/cubits/food_cubit.dart';

const Color scaffoldBgColor = Color(0xFFF7FAFF);
const Color _ordersInk = Color(0xFF241916);

class FoodOrdersScreen extends StatefulWidget {
  const FoodOrdersScreen({super.key});

  @override
  State<FoodOrdersScreen> createState() => _FoodOrdersScreenState();
}

class _FoodOrdersScreenState extends State<FoodOrdersScreen> {
  Timer? _timer;
  Timer? _initialSyncTimer;
  int? _selectedOrderId;
  Map<String, dynamic>? _selectedOrder;
  List<Map<String, dynamic>> _timeline = [];
  List<FoodOrderSummary> _cachedOrders = [];
  String _filter = 'All';
  int _manualRefreshPending = 0;
  String? _manualRefreshTarget;

  @override
  void initState() {
    super.initState();
    _cachedOrders = context.read<FoodCubit>().myOrders;
    context.read<FoodCubit>().loadMyOrders(limit: 200);
    var syncAttempt = 0;
    _initialSyncTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _selectedOrderId != null) {
        timer.cancel();
        return;
      }
      syncAttempt++;
      context.read<FoodCubit>().loadMyOrders(limit: 200);
      if (syncAttempt >= 4) timer.cancel();
    });
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      if (_selectedOrderId != null) {
        context.read<FoodCubit>().loadOrderDetails(_selectedOrderId!);
        context.read<FoodCubit>().loadOrderTimeline(_selectedOrderId!);
      } else {
        context.read<FoodCubit>().loadMyOrders(limit: 200);
      }
    });
  }

  @override
  void dispose() {
    _initialSyncTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedOrder = null;
      _selectedOrderId = null;
      _timeline = [];
    });
    context.read<FoodCubit>().loadMyOrders(limit: 200);
  }

  Future<void> _refreshOrders({bool showToast = true}) async {
    if (showToast) {
      _manualRefreshTarget = 'orders';
      _manualRefreshPending = 1;
    }
    await context.read<FoodCubit>().loadMyOrders(limit: 200);
  }

  Future<void> _refreshSelectedOrder({bool showToast = true}) async {
    final orderId = _selectedOrderId;
    if (orderId == null) return;
    if (showToast) {
      _manualRefreshTarget = 'details';
      _manualRefreshPending = 2;
    }
    await Future.wait([
      context.read<FoodCubit>().loadOrderDetails(orderId),
      context.read<FoodCubit>().loadOrderTimeline(orderId),
    ]);
  }

  void _handleManualRefreshSuccess(String message) {
    if (_manualRefreshPending <= 0) return;
    _manualRefreshPending--;
    if (_manualRefreshPending > 0) return;
    _manualRefreshTarget = null;
    _showOrderToast(message);
  }

  void _handleManualRefreshFailure(String message) {
    if (_manualRefreshPending <= 0) return;
    _manualRefreshPending = 0;
    _manualRefreshTarget = null;
    _showOrderToast(message, isError: true);
  }

  void _showOrderToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: isError ? const Color(0xFFD93025) : const Color(0xFF148A45),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message.translate(context),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins SemiBold',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FoodOrderSummary> _filteredOrders(List<FoodOrderSummary> orders) {
    return orders.where((order) {
      final status = order.status.toLowerCase();
      if (_filter == 'Active') {
        return !status.contains('deliver') && !status.contains('cancel');
      }
      if (_filter == 'Completed') {
        return status.contains('deliver') || status.contains('complete');
      }
      if (_filter == 'Cancelled') {
        return status.contains('cancel') || status.contains('fail');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isShowingDetails = _selectedOrder != null;

    return PopScope(
      canPop: !isShowingDetails,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isShowingDetails) {
          _clearSelection();
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        appBar: AppBar(
          backgroundColor: scaffoldBgColor,
          foregroundColor: _ordersInk,
          iconTheme: const IconThemeData(color: _ordersInk),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          leading: isShowingDetails
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: _ordersInk),
                  onPressed: _clearSelection,
                )
              : null,
          title: Text(
            isShowingDetails ? 'Order Details'.translate(context) : 'My Food Orders'.translate(context),
            style: heading3Grey1(context).copyWith(
              color: _ordersInk,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _ordersInk),
              onPressed: () {
                if (_selectedOrderId != null) {
                  _refreshSelectedOrder();
                } else {
                  _refreshOrders();
                }
              },
            ),
          ],
        ),
        body: BlocConsumer<FoodCubit, FoodState>(
          listener: (context, state) {
            if (state is FoodOrderDetailsLoaded) {
              setState(() {
                _selectedOrder = state.order;
                _selectedOrderId = int.tryParse((state.order['id'] ?? '').toString()) ?? _selectedOrderId;
              });
              if (_manualRefreshTarget == 'details') {
                _handleManualRefreshSuccess('Order details refreshed successfully');
              }
            }
            if (state is FoodOrderTimelineLoaded) {
              setState(() {
                _timeline = state.timeline;
              });
              if (_manualRefreshTarget == 'details') {
                _handleManualRefreshSuccess('Order details refreshed successfully');
              }
            }
            if (state is FoodMyOrdersLoaded) {
              setState(() {
                _cachedOrders = state.orders;
              });
              if (_manualRefreshTarget == 'orders') {
                _handleManualRefreshSuccess(
                  state.orders.isEmpty ? 'No food orders found' : 'Orders refreshed successfully',
                );
              }
            }
            if (state is FoodFailure) {
              _handleManualRefreshFailure(state.message);
            }
          },
          builder: (context, state) {
            if (isShowingDetails) {
              return _buildOrderDetailsView();
            }

            if (state is FoodLoading && _cachedOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }

            if (state is FoodFailure && _cachedOrders.isEmpty) {
              return _buildEmptyState(
                icon: Icons.error_outline_rounded,
                title: state.message,
                subtitle: 'Pull down or tap refresh to try again.'.translate(context),
              );
            }

            final cubitOrders = context.read<FoodCubit>().myOrders;
            final orders = state is FoodMyOrdersLoaded
                ? state.orders
                : cubitOrders.isNotEmpty
                    ? cubitOrders
                    : _cachedOrders;
            final filtered = _filteredOrders(orders);
            return RefreshIndicator(
              color: themeColor,
              onRefresh: _refreshOrders,
              child: _buildOrdersList(orders, filtered),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrdersList(
    List<FoodOrderSummary> allOrders,
    List<FoodOrderSummary> filteredOrders,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
      children: [
        _buildOrdersHero(allOrders.length),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 16),
        if (allOrders.isEmpty)
          _buildEmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No food orders yet'.translate(context),
            subtitle: 'Your placed food orders and live tracking will appear here.'.translate(context),
          )
        else if (filteredOrders.isEmpty)
          _buildEmptyState(
            icon: Icons.filter_alt_off_rounded,
            title: 'No $_filter orders'.translate(context),
            subtitle: 'Try another status filter.'.translate(context),
          )
        else
          ...filteredOrders.map((order) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OrderSummaryCard(
                order: order,
                onTap: () {
                  setState(() {
                    _selectedOrderId = order.id;
                  });
                  context.read<FoodCubit>().loadOrderDetails(order.id);
                  context.read<FoodCubit>().loadOrderTimeline(order.id);
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildOrdersHero(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101827), Color(0xFF1D56A5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D56A5).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track every bite'.translate(context),
                  style: heading2Grey1(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count orders saved with live status timeline',
                  style: regular2(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Active', 'Completed', 'Cancelled'];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final filter = filters[index];
          final selected = _filter == filter;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Text(filter.translate(context)),
            labelStyle: regular2(context).copyWith(
              color: selected ? Colors.white : _ordersInk,
              fontWeight: FontWeight.w800,
            ),
            backgroundColor: Colors.white,
            selectedColor: themeColor,
            side: BorderSide(
              color: selected ? themeColor : Colors.black.withValues(alpha: 0.06),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (_) => setState(() => _filter = filter),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: themeColor.withValues(alpha: 0.62)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: heading3Grey1(context).copyWith(
              color: _ordersInk,
              fontWeight: FontWeight.w900,
            ),
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

  Widget _buildOrderDetailsView() {
    final order = _selectedOrder!;
    final status = (order['status'] ?? '').toString();
    final paymentStatus = (order['payment_status'] ?? '').toString();
    final paymentMethod = (order['payment_method'] ?? '').toString();
    final address = (order['delivery_address'] ?? 'N/A').toString();
    final total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
    final itemsSubtotal = double.tryParse(order['items_subtotal']?.toString() ?? '0') ?? 0.0;
    final deliveryFee = double.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0.0;
    final platformFee = double.tryParse(order['platform_fee']?.toString() ?? '0') ?? 0.0;
    final taxAmount = double.tryParse(order['tax_amount']?.toString() ?? '0') ?? 0.0;
    final orderNumber = (order['order_number'] ?? '').toString();
    final deliveryOtp = (order['delivery_otp'] ?? '').toString();
    final restaurant = order['restaurant'] is Map
        ? Map<String, dynamic>.from(order['restaurant'] as Map)
        : <String, dynamic>{};
    final restaurantName = (restaurant['name'] ?? 'Restaurant').toString();
    final items = ((order['items'] as List?) ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return RefreshIndicator(
      color: themeColor,
      onRefresh: _refreshSelectedOrder,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.restaurant_rounded, color: themeColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: heading3Grey1(context).copyWith(
                              color: _ordersInk,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Order #$orderNumber',
                            style: regular2(context).copyWith(
                              color: Colors.black.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scaffoldBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 20, color: themeColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Address'.translate(context),
                              style: regular2(context).copyWith(
                                fontSize: 12,
                                color: Colors.black.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address,
                              style: regular2(context).copyWith(
                                color: _ordersInk,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
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
          ),
          const SizedBox(height: 22),
          if (deliveryOtp.isNotEmpty && status != 'delivered' && status != 'cancelled') ...[
            _buildDeliveryOtpCard(deliveryOtp),
            const SizedBox(height: 22),
          ],
          _sectionTitle('Order Items'.translate(context)),
          const SizedBox(height: 12),
          _buildItemsCard(items),
          const SizedBox(height: 22),
          _sectionTitle('Payment Summary'.translate(context)),
          const SizedBox(height: 12),
          _buildPaymentCard(
            itemsSubtotal: itemsSubtotal,
            taxAmount: taxAmount,
            deliveryFee: deliveryFee,
            platformFee: platformFee,
            total: total,
            paymentStatus: paymentStatus,
            paymentMethod: paymentMethod,
          ),
          const SizedBox(height: 22),
          _sectionTitle('Tracking Timeline'.translate(context)),
          const SizedBox(height: 12),
          _buildTimelineCard(),
        ],
      ),
    );
  }

  Widget _buildDeliveryOtpCard(String otp) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor,
            const Color(0xFFFFB52E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.26),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery OTP'.translate(context),
                  style: regular2(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  otp,
                  style: heading3Grey1(context).copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Give this OTP to the driver after receiving your food.'.translate(context),
                  style: regular2(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy'.translate(context),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: otp));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delivery OTP copied'.translate(context))),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: heading3Grey1(context).copyWith(
        color: _ordersInk,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildItemsCard(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _plainCard(
        child: Text(
          'No items found'.translate(context),
          style: regular2(context).copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    return _plainCard(
      child: Column(
        children: items.map((item) {
          final food = item['food_item'] is Map
              ? Map<String, dynamic>.from(item['food_item'] as Map)
              : <String, dynamic>{};
          final name = (food['name'] ?? 'Food item').toString();
          final qty = int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;
          final total = double.tryParse((item['line_total'] ?? 0).toString()) ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.fastfood_rounded, color: themeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: regular2(context).copyWith(
                      color: _ordersInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'x$qty',
                  style: regular2(context).copyWith(
                    color: Colors.black.withValues(alpha: 0.48),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: regular2(context).copyWith(
                    color: _ordersInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentCard({
    required double itemsSubtotal,
    required double taxAmount,
    required double deliveryFee,
    required double platformFee,
    required double total,
    required String paymentStatus,
    required String paymentMethod,
  }) {
    return _plainCard(
      child: Column(
        children: [
          PaymentStatusBanner(
            paymentStatus: paymentStatus,
            paymentMethod: paymentMethod,
            amount: total,
          ),
          const SizedBox(height: 14),
          _amountRow('Items subtotal'.translate(context), itemsSubtotal),
          _amountRow('Tax'.translate(context), taxAmount),
          _amountRow('Delivery fee'.translate(context), deliveryFee),
          _amountRow('Platform fee'.translate(context), platformFee),
          Divider(height: 24, color: Colors.black.withValues(alpha: 0.08)),
          _amountRow('Total'.translate(context), total, isTotal: true),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: regular2(context).copyWith(
              color: isTotal ? _ordersInk : Colors.black.withValues(alpha: 0.55),
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: regular2(context).copyWith(
              color: isTotal ? themeColor : _ordersInk,
              fontWeight: FontWeight.w900,
              fontSize: isTotal ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    if (_timeline.isEmpty) {
      return _plainCard(
        child: Text(
          'No status updates yet'.translate(context),
          style: regular2(context).copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    return _plainCard(
      child: Column(
        children: List.generate(_timeline.length, (index) {
          final t = _timeline[index];
          final isLast = index == _timeline.length - 1;
          final fromStatus = (t['from_status'] ?? 'Start').toString();
          final toStatus = (t['to_status'] ?? '').toString();
          final time = (t['created_at'] ?? '').toString();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLast ? themeColor : Colors.grey.shade300,
                      border: Border.all(
                        color: isLast ? themeColor.withValues(alpha: 0.25) : Colors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 48,
                      color: Colors.grey.shade200,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$fromStatus -> $toStatus',
                        style: regular2(context).copyWith(
                          fontWeight: isLast ? FontWeight.w900 : FontWeight.w700,
                          color: isLast ? _ordersInk : Colors.black.withValues(alpha: 0.68),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: regular2(context).copyWith(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.42),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _plainCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class OrderSummaryCard extends StatelessWidget {
  final FoodOrderSummary order;
  final VoidCallback onTap;

  const OrderSummaryCard({
    super.key,
    required this.order,
    required this.onTap,
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
    final restaurantName = (order.restaurantName ?? 'Restaurant').trim();
    final logoUrl = _resolveImageUrl(order.restaurantLogo);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.045)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: heading3Grey1(context).copyWith(
                            color: _ordersInk,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Order #${order.orderNumber}',
                          style: regular2(context).copyWith(
                            color: Colors.black.withValues(alpha: 0.48),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (order.branchAddress ?? 'Tap to view delivery and timeline').translate(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: regular2(context).copyWith(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: heading3Grey1(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: themeColor),
                ],
              ),
              const SizedBox(height: 12),
              PaymentStatusBanner(
                paymentStatus: order.paymentStatus,
                paymentMethod: order.paymentMethod,
                amount: order.totalAmount,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentStatusBanner extends StatelessWidget {
  final String paymentStatus;
  final String paymentMethod;
  final double amount;
  final bool compact;

  const PaymentStatusBanner({
    super.key,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.amount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = paymentStatus.trim().toLowerCase() == 'paid';
    final color = isPaid ? const Color(0xFF168A4A) : const Color(0xFFB56A00);
    final method = paymentMethod.replaceAll('_', ' ').trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 13,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.verified_rounded : Icons.schedule_rounded,
            color: color,
            size: compact ? 22 : 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? 'PAID • PAYMENT COMPLETE' : 'PAYMENT PENDING',
                  style: regular2(context).copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 12 : 14,
                  ),
                ),
                if (!compact && method.isNotEmpty)
                  Text(
                    'Paid via ${method.toUpperCase()}',
                    style: regular2(context).copyWith(
                      color: color.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: regular2(context).copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 14 : 17,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color _getStatusColor(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('placed') ||
        lower.contains('accepted') ||
        lower.contains('preparing') ||
        lower.contains('ready') ||
        lower.contains('picked') ||
        lower.contains('way')) {
      return Colors.orange;
    }
    if (lower.contains('deliver') || lower.contains('complete')) return Colors.green;
    if (lower.contains('cancel') || lower.contains('fail')) return Colors.red;
    return themeColor;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final text = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: regular2(context).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}


