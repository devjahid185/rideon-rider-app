import 'package:ride_on/data/repositories/payment_repository.dart'
    show PaymentRepository;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum PaymentMethod { cash, online }

class PaymentCubit extends Cubit<PaymentMethod?> {
  PaymentCubit() : super(PaymentMethod.cash);

  void selectMethod(PaymentMethod method) => emit(method);
}

abstract class UpdatePaymentByUserState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdatePaymentInitial extends UpdatePaymentByUserState {}

class UpdatePaymentLoading extends UpdatePaymentByUserState {}

class UpdatePaymentSuceess extends UpdatePaymentByUserState {
  @override
  List<Object?> get props => [];
}

class UpdatePaymentFailure extends UpdatePaymentByUserState {
  final String? paymentMessage;
  UpdatePaymentFailure({this.paymentMessage});
  @override
  List<Object?> get props => [];
}

class UpdatePaymentByUserCubit extends Cubit<UpdatePaymentByUserState> {
  PaymentRepository paymentRepository;
  UpdatePaymentByUserCubit(this.paymentRepository)
      : super(UpdatePaymentInitial());

  Future<void> updatePaymentStatusByUser(
      {required BuildContext context,
      required String bookingId,
      required String paymentMethod}) async {
    try {
      emit(UpdatePaymentLoading());

      var response = await paymentRepository.updatePaymentStatusByUser(
          context: context, bookingId: bookingId, paymentMethod: paymentMethod);
      if (response["status"] == 200) {
        emit(UpdatePaymentSuceess());

      } else {
        emit(UpdatePaymentFailure(paymentMessage: response["error"]));
      }
    } catch (err) {
      emit(UpdatePaymentFailure(paymentMessage: "$err"));

    }
  }

  void resetState() {
    emit(UpdatePaymentInitial());
  }
}


