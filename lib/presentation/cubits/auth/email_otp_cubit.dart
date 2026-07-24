import 'dart:convert';

import 'package:ride_on/domain/entities/login_data.dart';
import 'package:ride_on/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/data_store.dart';

abstract class EmailOtpState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EmailOtpInitial extends EmailOtpState {}

class EmailOtpLoading extends EmailOtpState {}

class EmailOtpFailed extends EmailOtpState {
  final String error;

  EmailOtpFailed(this.error);
  @override

  List<Object?> get props => [error];
}

class ResendEmailOtpSuccess extends EmailOtpState {
  final String otp;

  ResendEmailOtpSuccess(this.otp);
  @override
  List<Object?> get props => [otp];
}

class OtpSuccessForChangeEmailSate extends EmailOtpState {
  final LoginModel loginModel;

  OtpSuccessForChangeEmailSate(this.loginModel);
  @override
  List<Object?> get props => [loginModel];
}

class EmailOtpCubit extends Cubit<EmailOtpState> {
  final AuthRepository repository;

  EmailOtpCubit(this.repository) : super(EmailOtpInitial());

  Future<void> emailOtpVerifyForChangeEmail(String email, String otp) async {
    try {
      emit(EmailOtpLoading());
      final response = await repository.forChangeEmail(email: email, otp: otp);
      if (response["status"] == 200) {
        LoginModel loginModel = LoginModel.fromJson(response);
        UserData userObj = UserData();
        userObj.saveLoginData("UserData", jsonEncode(response));
        loginModel = loginModel;
        emit(OtpSuccessForChangeEmailSate(loginModel));
      } else {
        emit(EmailOtpFailed(response["error"]));
      }
    } catch (e) {
      emit(EmailOtpFailed("something went wrong"));
    }
  }

  Future<void> resendOtpForChangeEmail(Map<String, dynamic> data) async {
    try {
      emit(EmailOtpLoading());
      final response = await repository.resendEmailOtpForChange(data);

      if (response["status"] == 200) {
        emit(ResendEmailOtpSuccess(response["data"]["reset_token"]));
      } else {
        emit(EmailOtpFailed(response["error"]));
      }
    } catch (e) {
      emit(EmailOtpFailed("something went wrong"));
    }
  }

  void clear() {
    emit(EmailOtpInitial());
  }
}


