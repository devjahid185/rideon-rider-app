import 'package:ride_on/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ResendOtpState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ResendOtpInitial extends ResendOtpState {}

class ResendOtpLoading extends ResendOtpState {}

class ResendOtpSuccess extends ResendOtpState {
  final String? otpValue;
  ResendOtpSuccess(this.otpValue);
  @override
  List<Object?> get props => [otpValue];
}

class ResendOtpFailure extends ResendOtpState {
  final String error;
  ResendOtpFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class AuthResendOtpCubit extends Cubit<ResendOtpState> {
  final AuthRepository authRepository;
  AuthResendOtpCubit(this.authRepository) : super(ResendOtpInitial());

  Future<void> resendOtp({
    String? phone,
    String? phoneCountry,
  }) async {
    try {
      emit(ResendOtpLoading());
      var response = await authRepository.resendOtp(
        phone: phone,
        phoneCountry: phoneCountry,
      );

      if (response["status"] == 200) {
        emit(ResendOtpSuccess(response['data']['otp_value']));
      } else {
        emit(ResendOtpFailure(response['error']));
      }
    } catch (error) {
      //
    }
  }

  void resetState() {
    emit(ResendOtpInitial());
  }
}


