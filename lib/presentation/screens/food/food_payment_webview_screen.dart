import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
import 'package:ride_on/core/utils/theme/theme_style.dart';
import 'package:ride_on/core/utils/translate.dart';

class FoodPaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const FoodPaymentWebViewScreen({super.key, required this.paymentUrl});

  @override
  State<FoodPaymentWebViewScreen> createState() => _FoodPaymentWebViewScreenState();
}

class _FoodPaymentWebViewScreenState extends State<FoodPaymentWebViewScreen> {
  bool _isLoading = true;
  bool _handledResult = false;

  void _handleUrl(WebUri? url) {
    if (_handledResult || url == null) return;
    final value = url.toString();
    if (value.contains('/food/payment_success')) {
      _handledResult = true;
      final orderId = Uri.tryParse(value)?.queryParameters['order'];
      Navigator.pop(context, orderId ?? 'paid');
    } else if (value.contains('/food/payment_fail')) {
      _handledResult = true;
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Stripe Payment'.translate(context),
          style: heading3Grey1(context).copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.paymentUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
              transparentBackground: true,
            ),
            onLoadStart: (_, url) {
              if (mounted) setState(() => _isLoading = true);
              _handleUrl(url);
            },
            onLoadStop: (_, url) {
              if (mounted) setState(() => _isLoading = false);
              _handleUrl(url);
            },
            shouldOverrideUrlLoading: (_, action) async {
              _handleUrl(action.request.url);
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            ColoredBox(
              color: Colors.white.withValues(alpha: 0.82),
              child: Center(
                child: CircularProgressIndicator(color: themeColor),
              ),
            ),
        ],
      ),
    );
  }
}
