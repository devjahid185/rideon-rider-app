import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/data/repositories/payment_repository.dart';
import 'package:ride_on/domain/entities/get_item_price.dart';

abstract class PaymentCouponState {}

class CouponInitialState extends PaymentCouponState {}

class CouponLoadingState extends PaymentCouponState {}

class CouponSuccessState extends PaymentCouponState {
  GetItemPrice? getItemPriceData;


  CouponSuccessState({this.getItemPriceData});

  List<Object?> get props => [getItemPriceData];
}

class CouponFailedState extends PaymentCouponState {
  final String message;
  CouponFailedState(this.message);
}
class CouponRemoveState extends PaymentCouponState {
  final String message;
  CouponRemoveState(this.message);
}


/// ----------------------
/// PAYMENT COUPON CUBIT
/// ----------------------
class CouponCubit extends Cubit<PaymentCouponState> {
  PaymentRepository paymentRepository;
  CouponCubit(this.paymentRepository) : super(CouponInitialState());
Future<void> applyCoupon({
   required Map<String, dynamic> postData,
    required BuildContext context,
  }) async {
    try {
      emit(CouponLoadingState());
      final response = await paymentRepository.applyCoupon(postData: postData
             );
      if (response["status"] == 200) {
        GetItemPrice getItemPrice = GetItemPrice.fromJson(response);
 
        emit(CouponSuccessState(getItemPriceData: getItemPrice));
      } else {
        emit(CouponFailedState(response["error"]));
      }
    } catch (error) {
      emit(CouponFailedState("$error"));
    }
  }

  Future<void> removeCoupon({
   required Map<String, dynamic> postData,
    required BuildContext context,
  }) async {
    try {
      emit(CouponLoadingState());
      final response = await paymentRepository.applyCoupon(postData: postData
             );
      if (response["status"] == 200) {
       

        emit(CouponRemoveState(""));
      } else {
        emit(CouponFailedState(response["error"]));
      }
    } catch (error) {
      emit(CouponFailedState("$error"));
    }
  }
  /// Apply Coupon
  

  /// Reset state after success/failure
  void resetCoupon() {
    emit(CouponInitialState());
  }
}


