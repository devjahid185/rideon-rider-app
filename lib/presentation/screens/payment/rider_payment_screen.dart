import 'dart:convert';
import 'package:ride_on/core/services/data_store.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/presentation/cubits/payment/coupon_cubit.dart';
import 'package:ride_on/presentation/screens/payment/payment_geteway_screen.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/book_ride_cubit.dart';
import '../../cubits/location/get_nearby_drivers_cubit.dart';
import '../../cubits/payment/payment_cubit.dart';
import '../../cubits/realtime/get_ride_request_status_cubit.dart';
import '../../cubits/realtime/ride_request_cubit.dart';
import '../../cubits/realtime/update_ride_request_parameter.dart';
import '../../widgets/review_widget.dart';
import '../Home/item_home_screen.dart';

class RiderPaymentScreen extends StatefulWidget {
  final String? bookingId, rideId, fare, paymentUrl;
  const RiderPaymentScreen({
    super.key,
    this.bookingId,
    this.rideId,
    this.fare,
    this.paymentUrl,
  });

  @override
  State<RiderPaymentScreen> createState() => _RiderPaymentScreenState();
}

class _RiderPaymentScreenState extends State<RiderPaymentScreen> {
  Map<String, dynamic> vehicle = {};
  String paymentStatus = "";
  bool isCash = true;
  bool isOpenReview = false;
  TextEditingController couponController = TextEditingController();
  double originalFare = 0;
  double discountedFare = 0;
  double discountAmount = 0;
  bool couponApplied = false;

  @override
void initState() {
  super.initState();

  final bookingCount = box.get("bookingCount") ?? "0";
  final savedCoupon = box.get("coupon") ?? "";
  currency=box.get("currency");
   
  
  final savedVehicle = box.get('selected_vehicle');
    if (savedVehicle != null && savedVehicle.isNotEmpty) {
      vehicle = jsonDecode(savedVehicle);
    }
 
   
  if (bookingCount == "1" && savedCoupon.isNotEmpty) {

    couponController.text=savedCoupon;
    isShowCoupon=true;
  
  }
 
  if ((widget.rideId ?? "").isNotEmpty) {
    context.read<GetRideRequestPaymentCubit>().resetStatus();
    context
        .read<GetRideRequestPaymentCubit>()
        .listenToPaymentStatusAndMethod(rideId: widget.rideId!);
 
    
  }
 
  originalFare = double.tryParse(widget.fare ?? '0') ?? 0.0;
  discountedFare = originalFare;
}

  void _applyCouponDiscount(double discount) {
    setState(() {
      discountAmount = discount;
      discountedFare = originalFare - discountAmount;
      couponApplied = true;
    });
  }

  bool isShowCoupon = false;

  void _removeCoupon() {
    context.read<CouponCubit>().removeCoupon(
      postData: {
        "item_type_id": vehicle["id"],
        "booking_id": widget.bookingId,
        "distance": vehicle["distance"],
        "coupon_code": "",
        "wallet_amount": "",
        "selected_currency_code": currency
      },
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocListener<GetRideRequestPaymentCubit, Map<String, String>>(
        listener: (context, state) {
          paymentStatus = state["paymentStatus"] ?? "";
        },
        child: Scaffold(
          backgroundColor: whiteColor,
          appBar: CustomAppBarNew(
            title: "Trip Summary".translate(context),
            onBackTap: () {
              context
                  .read<GetRideRequestPaymentCubit>()
                  .listenToPaymentStatusAndMethod(rideId: widget.rideId!);
              if (paymentStatus == "Collected") {
                box.delete("ride_data");
                context.read<GetPolylineCubit>().resetPolylines();
                context.read<BookRideRealTimeDataBaseCubit>().resetState();
                clearAllRiderData(context);
                goTo(const ItemHomeScreen());
              } else {
                dialogExit(context);
              }
            },
          ),
          body: BlocListener<GetRideRequestPaymentCubit, Map<String, String>>(
            listener: (context, state) {
              if (state["paymentMethod"] == "cash") {
                context.read<PaymentCubit>().selectMethod(PaymentMethod.cash);
              } else {
                context.read<PaymentCubit>().selectMethod(PaymentMethod.online);
              }

              if (state["paymentStatus"] == "collected") {
                paymentStatus = "collected";
                box.delete("ride_data");
                context.read<GetPolylineCubit>().resetPolylines();
                context.read<BookRideRealTimeDataBaseCubit>().resetState();
                if (isOpenReview) return;
                isOpenReview = true;
          
                showModalBottomSheet(
                  context: context,
                  enableDrag: false,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CustomReviewWidget(
                    bookingId: widget.bookingId,
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocBuilder<PaymentCubit, PaymentMethod?>(
                builder: (context, selectedMethod) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDriverInfoSection(context),

                        const SizedBox(height: 20),

                        _buildRouteInfoSection(context),

                        const SizedBox(height: 20),
                       box.get("bookingCount").toString()=="1"? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GestureDetector(
                            onTap: () {
                              isShowCoupon = !isShowCoupon;
                              setState(() {});
                            },
                            child: Row(
                              children: [
                                Icon(Icons.local_offer_outlined,
                                    color: redColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Apply Coupon".translate(context),
                                  style: headingBlack(context).copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                isShowCoupon
                                    ? Icon(
                                        Icons.arrow_drop_up,
                                        color: blackColor,
                                        size: 26,
                                      )
                                    : Icon(
                                        Icons.arrow_drop_down,
                                        color: blackColor,
                                        size: 26,
                                      )
                              ],
                            ),
                          ),
                        ):const SizedBox(),

                        isShowCoupon
                            ? Column(
                                children: [
                                  _buildCouponSection(context),
                                  const SizedBox(height: 10),
                                  _buildFareBreakdown(context),
                                ],
                              )
                            : const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFareRow(
                                "Total Amount".translate(context),
                                discountedFare.toStringAsFixed(2),
                                isTotal: true,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Select a payment method to pay"
                                    .translate(context),
                                style: heading3Grey1(context).copyWith(
                                  fontSize: 14,
                                  color: blackColor.withValues(alpha: .6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Payment Methods
                        _buildPaymentMethods(context, selectedMethod),

                        const SizedBox(height: 30),

                        // Pay Now Button (for online payment)
                        if (selectedMethod == PaymentMethod.online)
                          _buildPayNowButton(context),
                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfoSection(BuildContext context) {
    return BlocBuilder<RideRequestCubit, RideRequestState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notifires.getbgcolor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: grey5.withValues(alpha: .3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: themeColor, width: 2),
                ),
                child: ClipOval(
                  child: myNetworkImage(state.acceptedDriverImageUrl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.acceptedDriverName,
                      style: headingBlack(context).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: greentext.withValues(alpha: .1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: greentext,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "RIDE COMPLETE".translate(context),
                            style: regular(context).copyWith(
                              color: greentext,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

  Widget _buildRouteInfoSection(BuildContext context) {
    return BlocBuilder<RideRequestCubit, RideRequestState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      size: 20,
                      color: Colors.green,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade200, Colors.red.shade200],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flag,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pickup".translate(context),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.pickupAddress,
                      style: heading3Grey1(context).copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Drop".translate(context),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.dropOffAddress,
                      style: heading3Grey1(context).copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notifires.getbgcolor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: grey6.withValues(alpha: 0.2),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: regular2(context).copyWith(color: grey1),
                  controller: couponController,
                  decoration: InputDecoration(
                    hintText: "Enter coupon code".translate(context),
                    filled: true,
                    fillColor: grey5,
                    hintStyle: regular2(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: couponApplied
                        ? IconButton(
                            icon: Icon(Icons.close, color: redColor),
                            onPressed: _removeCoupon,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              BlocConsumer<CouponCubit, PaymentCouponState>(
                listener: (context, state) {
              
                  if (state is CouponSuccessState) {
                 
                    double discount = double.parse(
                        state.getItemPriceData?.data?.couponDiscount ?? "0");
                    _applyCouponDiscount(discount);
                    context
                        .read<UpdateRideRequestParameterCubit>()
                        .updatePaymentAmountFirebase(
                            rideId: widget.rideId ?? "",
                            totalFare: discountedFare.toStringAsFixed(2),
                            discountFare: discountAmount.toString(),
                            couponApply: "yes");
                    context.read<CouponCubit>().resetCoupon();
                  } else if (state is CouponFailedState) {
                    showErrorToastMessage(state.message);
                    context.read<CouponCubit>().resetCoupon();
                  } else if (state is CouponRemoveState) {
                    couponController.clear();
                    discountAmount = 0;
                    discountedFare = originalFare;
                    couponApplied = false;
                    context
                        .read<UpdateRideRequestParameterCubit>()
                        .updatePaymentAmountFirebase(
                            rideId: widget.rideId ?? "",
                            totalFare: discountedFare.toStringAsFixed(2),
                            discountFare: discountAmount.toString(),
                            couponApply: "no");
                    context.read<CouponCubit>().resetCoupon();
                    setState(() {});
                  }
                },
                builder: (context, state) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [themeColor, themeColor.withValues(alpha: .8)],
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: state is CouponLoadingState
                          ? null
                          : () {
                              if (couponApplied) {
                                return;
                              }
                              if (couponController.text.isEmpty) {
                                showErrorToastMessage(
                                    "Please enter coupon code");
                                return;
                              }
                              context.read<CouponCubit>().applyCoupon(
                                postData: {
                                  "item_type_id": vehicle["id"],
                                  "booking_id": widget.bookingId,
                                  "distance": vehicle["distance"],
                                  "coupon_code": couponController.text,
                                  "wallet_amount": "",
                                  "selected_currency_code": currency
                                },
                                context: context,
                              );
                            },
                      child: state is CouponLoadingState
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              couponApplied && discountAmount != 0
                                  ? "Applied".translate(context)
                                  : "Apply".translate(context),
                              style: regular(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),

          // Coupon Applied Message
          if (couponApplied && discountAmount != 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: greentext.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: greentext.withValues(alpha: .3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: greentext, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Coupon applied successfully!".translate(context),
                    style: regular(context).copyWith(
                      color: greentext,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFareBreakdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: notifires.getbgcolor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: grey5.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Fare Breakdown".translate(context),
            style: headingBlack(context).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // Original Fare
          _buildFareRow(
            "Original Fare".translate(context),
            originalFare.toStringAsFixed(2),
            isTotal: false,
          ),

          // Discount (if applied)
          if (couponApplied && discountAmount != 0) ...[
            _buildFareRow(
              "Discount".translate(context),
              "-${discountAmount.toStringAsFixed(2)}",
              isTotal: false,
              isDiscount: true,
            ),
          ],

          // Divider
          const SizedBox(height: 8),
          Divider(color: grey5.withValues(alpha: .5)),

          // Total Fare
        ],
      ),
    );
  }

  Widget _buildFareRow(String label, String amount,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.translate(context),
            style: regular(context).copyWith(
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isDiscount ? greentext : blackColor.withValues(alpha: 0.8),
            ),
          ),
          Text(
            "$currency $amount",
            style: regular(context).copyWith(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal
                  ? themeColor
                  : isDiscount
                      ? greentext
                      : blackColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(
      BuildContext context, PaymentMethod? selectedMethod) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notifires.getbgcolor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: grey5.withValues(alpha: 0.2),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Method".translate(context),
            style: headingBlack(context).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // Cash Payment Option
          _buildPaymentOption(
            context: context,
            icon: Icons.attach_money,
            title: "Cash".translate(context),
            subtitle: "Pay with cash to driver".translate(context),
            method: PaymentMethod.cash,
            selectedMethod: selectedMethod,
          ),

          const SizedBox(height: 12),

          // Online Payment Option
          _buildPaymentOption(
            context: context,
            icon: Icons.credit_card,
            title: "Online".translate(context),
            subtitle: "Pay securely online".translate(context),
            method: PaymentMethod.online,
            selectedMethod: selectedMethod,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required PaymentMethod method,
    required PaymentMethod? selectedMethod,
  }) {
    bool isSelected = selectedMethod == method;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? themeColor.withValues(alpha: 0.1)
            : notifires.getboxcolor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? themeColor : grey5.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? themeColor : grey5.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? whiteColor : blackColor.withValues(alpha: 0.7),
          ),
        ),
        title: Text(
          title,
          style: headingBlack(context).copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle.translate(context),
          style: regular(context).copyWith(
            fontSize: 12,
            color: blackColor.withValues(alpha: 0.6),
          ),
        ),
        trailing: Radio<PaymentMethod>(
          activeColor: themeColor,
          value: method,
          groupValue: selectedMethod,
          onChanged: (value) {
            if (value != null) {
              context.read<PaymentCubit>().selectMethod(value);
              context
                  .read<UpdateRideRequestParameterCubit>()
                  .updatePaymentMehod(
                    rideId: widget.rideId ?? "",
                    paymentMethod:
                        value == PaymentMethod.cash ? "cash" : "online",
                  );
            }
          },
        ),
        onTap: () {
          context.read<PaymentCubit>().selectMethod(method);
          context.read<UpdateRideRequestParameterCubit>().updatePaymentMehod(
                rideId: widget.rideId ?? "",
                paymentMethod: method == PaymentMethod.cash ? "cash" : "online",
              );
        },
      ),
    );
  }

  Widget _buildPayNowButton(BuildContext context) {
    return BlocConsumer<UpdatePaymentByUserCubit, UpdatePaymentByUserState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: CustomsButtons(
              text: "Pay Now - $currency ${discountedFare.toStringAsFixed(2)}",
              backgroundColor: themeColor,
              onPressed: () {
                goTo(PaymentsScreen(
                  rideId: widget.rideId,
                  url: widget.paymentUrl,
                ));
              }),
        );
      },
      listener: (context, state) {
        if (state is UpdatePaymentLoading) {
          Widgets.showLoader(context);
        }
        if (state is UpdatePaymentSuceess) {
          Widgets.hideLoder(context);
          clearAllRiderData(context);
          showModalBottomSheet(
            context: context,
            enableDrag: false,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CustomReviewWidget(
              bookingId: widget.bookingId,
            ),
          );
        } else if (state is UpdatePaymentFailure) {
          Widgets.hideLoder(context);
          showErrorToastMessage(state.paymentMessage ?? "");
        }
      },
    );
  }
}


