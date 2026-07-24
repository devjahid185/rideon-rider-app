// ignore_for_file: use_build_context_synchronously

import 'package:ride_on/domain/entities/login_data.dart';
import 'package:ride_on/data/repositories/auth_repository.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/presentation/cubits/auth/user_authenticate_cubit.dart';

abstract class AuthLoginState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginInitial extends AuthLoginState {}

class LoginLoading extends AuthLoginState {}

class LoginSuccess extends AuthLoginState {
  final LoginModel loginModel;
  LoginSuccess(this.loginModel);
  @override
  List<Object?> get props => [loginModel];
}

class LoginFailure extends AuthLoginState {
  final String error;
  LoginFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class LoginCloseLoading extends AuthLoginState {}

class AuthLoginCubit extends Cubit<AuthLoginState> {
  final AuthRepository authRepository;
  AuthLoginCubit(this.authRepository) : super(LoginInitial());

  Future<void> login(
      {required BuildContext context,
      required String phoneNumber,
      required String phoneCountry}) async {
    try {
      emit(LoginLoading());
      final response = await authRepository.login(
          phoneCountry: phoneCountry, phoneNumber: phoneNumber);

      if (response['status'] == 200) {
        loginModel = LoginModel.fromJson(response);
        if (loginModel != null && loginModel!.data != null) {
          token = loginModel!.data!.token ?? '';
        }
        context.read<SetCountryCubit>().reset();

        emit(LoginSuccess(LoginModel.fromJson(response)));
      } else {
        emit(LoginFailure(response['error']));
      }
    } catch (e) {
      context.read<SetCountryCubit>().reset();
      emit(LoginFailure('Something went wrong: $e'));
    }
  }

  void resetState() {
    emit(LoginInitial());
  }
}


