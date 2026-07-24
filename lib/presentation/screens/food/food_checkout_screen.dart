import 'package:flutter/material.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
import 'package:ride_on/core/utils/theme/theme_style.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/data/repositories/food_repository.dart';
import 'package:ride_on/domain/entities/food_models.dart';
import 'package:ride_on/presentation/screens/food/food_payment_webview_screen.dart';
import 'package:ride_on/presentation/screens/search/search_map_screen.dart';

const Color _checkoutBg = Color(0xFFF5F7FB);

class FoodCheckoutScreen extends StatefulWidget {
  final FoodRestaurant restaurant;
  final int branchId;
  final Map<int, int> cartQty;
  final Map<int, FoodMenuItem> cartItems;

  const FoodCheckoutScreen({
    super.key,
    required this.restaurant,
    required this.branchId,
    required this.cartQty,
    required this.cartItems,
  });

  @override
  State<FoodCheckoutScreen> createState() => _FoodCheckoutScreenState();
}

class _FoodCheckoutScreenState extends State<FoodCheckoutScreen> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _repository = FoodRepository();

  double? _deliveryLat;
  double? _deliveryLng;
  final String _paymentMethod = 'stripe';
  bool _isPaying = false;
  String? _pendingPaymentUrl;

  double get _itemsSubtotal {
    double total = 0;
    widget.cartQty.forEach((itemId, qty) {
      final item = widget.cartItems[itemId];
      if (item != null) {
        total += item.basePrice * qty;
      }
    });
    return total;
  }

  int get _cartCount => widget.cartQty.values.fold(0, (sum, qty) => sum + qty);
  double get _taxAmount => double.parse((_itemsSubtotal * 0.05).toStringAsFixed(2));
  double get _deliveryFee => 30.0;
  double get _platformFee => 5.0;
  double get _totalAmount => double.parse(
        (_itemsSubtotal + _taxAmount + _deliveryFee + _platformFee).toStringAsFixed(2),
      );

  @override
  void initState() {
    super.initState();
    _deliveryLat = double.tryParse(latitudeGlobal);
    _deliveryLng = double.tryParse(longitudeGlobal);
    final branchAddress = (widget.restaurant.branchAddress ?? '').trim();
    if (branchAddress.isNotEmpty) {
      _addressController.text = branchAddress;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDeliveryLocation() async {
    final picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchMapScreen(
          selectedAddressTitle: _addressController.text.trim(),
          checkStatus: false,
        ),
      ),
    );
    if (!mounted) return;

    if (picked is Map) {
      final address = (picked['address'] ?? '').toString().trim();
      final lat = double.tryParse((picked['lat'] ?? '').toString());
      final lng = double.tryParse((picked['lng'] ?? '').toString());
      setState(() {
        if (address.isNotEmpty) _addressController.text = address;
        _deliveryLat = lat ?? _deliveryLat;
        _deliveryLng = lng ?? _deliveryLng;
      });
    }
  }

  Future<void> _payAndPlaceOrder() async {
    if (!widget.restaurant.isAcceptingOrders) {
      _showMessage('Restaurant is currently closed. You can browse the menu, but ordering is unavailable.'.translate(context));
      return;
    }
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      _showMessage('Please enter delivery address'.translate(context));
      return;
    }
    if (_isPaying) return;

    setState(() => _isPaying = true);

    try {
      var paymentUrl = _pendingPaymentUrl;
      if (paymentUrl == null || paymentUrl.isEmpty) {
        final response = await _repository.createFoodOrder(
          payload: _buildOrderPayload(address: address),
        );
        if (!mounted) return;

        if (response['status'] != 200 && response['status'] != 201) {
          _showMessage((response['message'] ?? response['error'] ?? 'Unable to start payment').toString());
          return;
        }

        final data = response['data'] is Map
            ? Map<String, dynamic>.from(response['data'] as Map)
            : <String, dynamic>{};
        paymentUrl = (data['payment_url'] ?? '').toString();
        if (paymentUrl.isEmpty) {
          _showMessage('Stripe payment URL was not returned by the server'.translate(context));
          return;
        }
        _pendingPaymentUrl = paymentUrl;
      }

      if (!mounted) return;
      final paymentResult = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder: (_) => FoodPaymentWebViewScreen(paymentUrl: paymentUrl!),
        ),
      );
      if (!mounted) return;

      if (paymentResult != false && paymentResult != null) {
        final orderId = int.tryParse(paymentResult.toString()) ??
            _orderIdFromPaymentUrl(paymentUrl);
        final verified = orderId != null
            ? await _waitForPaidOrder(orderId)
            : true;
        if (!mounted) return;

        if (!verified) {
          _showMessage(
            'Payment received. Order is still syncing; please refresh My Orders.'
                .translate(context),
          );
        } else {
          _showMessage(
              'Payment successful. Order placed.'.translate(context));
        }
        Navigator.pop(context, true);
        return;
      }

      _showMessage('Payment was not completed. Your order was not placed.'.translate(context));
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  int? _orderIdFromPaymentUrl(String paymentUrl) {
    return int.tryParse(
      Uri.tryParse(paymentUrl)?.queryParameters['order'] ?? '',
    );
  }

  Future<bool> _waitForPaidOrder(int orderId) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final response =
          await _repository.getFoodOrderDetails(orderId: orderId);
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};
      final paymentStatus =
          (data['payment_status'] ?? '').toString().toLowerCase();
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (response['status'] == 200 &&
          paymentStatus == 'paid' &&
          status != 'payment_pending') {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return false;
    }
    return false;
  }

  Map<String, dynamic> _buildOrderPayload({required String address}) {
    final items = widget.cartQty.entries.map((entry) {
      return {
        'food_item_id': entry.key,
        'quantity': entry.value,
      };
    }).toList();

    final name = '${loginModel?.data?.firstName ?? ''} ${loginModel?.data?.lastName ?? ''}'.trim();

    return <String, dynamic>{
      'token': token,
      'restaurant_id': widget.restaurant.id,
      'restaurant_branch_id': widget.branchId,
      'delivery_address': address,
      'delivery_latitude': _deliveryLat,
      'delivery_longitude': _deliveryLng,
      if (name.isNotEmpty) 'customer_name': name,
      if ((loginModel?.data?.phone ?? '').isNotEmpty) 'customer_phone': loginModel!.data!.phone,
      if ((loginModel?.data?.phoneCountry ?? '').isNotEmpty)
        'customer_phone_country': loginModel!.data!.phoneCountry,
      if ((loginModel?.data?.email ?? '').isNotEmpty) 'customer_email': loginModel!.data!.email,
      'customer_note': _noteController.text.trim(),
      'payment_status': 'pending',
      'payment_method': _paymentMethod,
      'items': items,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _checkoutBg,
      appBar: AppBar(
        backgroundColor: _checkoutBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Secure Checkout'.translate(context),
          style: heading3Grey1(context).copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          _buildDeliveryCard(),
          const SizedBox(height: 16),
          _buildPaymentMethods(),
          const SizedBox(height: 16),
          _buildOrderSummary(),
        ],
      ),
      bottomNavigationBar: _buildPayBar(),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [themeColor, const Color(0xFF0F2F63)],
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                  widget.restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: heading2Grey1(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_cartCount ${'items'.translate(context)} - ${'Pay first, then your food order will be placed.'.translate(context)}',
                  style: regular2(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
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
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return _checkoutCard(
      title: 'Delivery details'.translate(context),
      child: Column(
        children: [
          TextField(
            controller: _addressController,
            decoration: _inputDecoration(
              label: 'Delivery address'.translate(context),
              icon: Icons.location_on_rounded,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _deliveryLat != null && _deliveryLng != null
                      ? 'Precise map location selected'.translate(context)
                      : 'Pick from map for accurate delivery'.translate(context),
                  style: regular2(context).copyWith(color: grey2, fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: _pickDeliveryLocation,
                icon: Icon(Icons.map_rounded, color: themeColor, size: 18),
                label: Text(
                  'Map'.translate(context),
                  style: regular2(context).copyWith(
                    color: themeColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: _inputDecoration(
              label: 'Delivery note (optional)'.translate(context),
              icon: Icons.sticky_note_2_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    const methods = [
      _PaymentOption('stripe', 'Stripe secure card payment', Icons.credit_card_rounded),
    ];

    return _checkoutCard(
      title: 'Payment method'.translate(context),
      child: Column(
        children: methods.map((method) {
          final selected = _paymentMethod == method.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? themeColor : const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? themeColor : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(method.icon, color: selected ? Colors.white : themeColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        method.label.translate(context),
                        style: heading3Grey1(context).copyWith(
                          color: selected ? Colors.white : blackColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: selected ? Colors.white : grey3,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return _checkoutCard(
      title: 'Order summary'.translate(context),
      child: Column(
        children: [
          ...widget.cartQty.entries.map((entry) {
            final item = widget.cartItems[entry.key];
            if (item == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.value} x ${item.name}',
                      style: regular2(context).copyWith(
                        color: blackColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '\$${(item.basePrice * entry.value).toStringAsFixed(2)}',
                    style: regular2(context).copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 22),
          _summaryLine('Subtotal'.translate(context), _itemsSubtotal),
          _summaryLine('Tax'.translate(context), _taxAmount),
          _summaryLine('Delivery fee'.translate(context), _deliveryFee),
          _summaryLine('Platform fee'.translate(context), _platformFee),
          const Divider(height: 22),
          _summaryLine('Total'.translate(context), _totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: regular2(context).copyWith(
              color: isTotal ? blackColor : grey2,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: heading3Grey1(context).copyWith(
              color: isTotal ? themeColor : blackColor,
              fontWeight: FontWeight.w900,
              fontSize: isTotal ? 19 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 10 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isPaying ? null : _payAndPlaceOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: themeColor.withValues(alpha: 0.55),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isPaying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                '${'Continue to Stripe'.translate(context)} - \$${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
      ),
    );
  }

  Widget _checkoutCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: heading3Grey1(context).copyWith(
              fontWeight: FontWeight.w900,
              color: blackColor,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: themeColor),
      filled: true,
      fillColor: _checkoutBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}

class _PaymentOption {
  final String id;
  final String label;
  final IconData icon;

  const _PaymentOption(this.id, this.label, this.icon);
}
