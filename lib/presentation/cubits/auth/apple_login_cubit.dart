import 'dart:convert';

// ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/entities/check_mobile.dart';
import '../../../domain/entities/login_data.dart';
import '../../../domain/entities/static_data.dart';

abstract class AppleLoginState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppleLoginInitial extends AppleLoginState {}

class AppleLoginLoading extends AppleLoginState {}

class AppleLoginSuccess extends AppleLoginState {
  final StaticModel staticModel;

  AppleLoginSuccess(this.staticModel);

  @override
  List<Object?> get props => [staticModel];
}

class AppleLoginFailure extends AppleLoginState {
  final String error;

  AppleLoginFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class AppleLoginCubit extends Cubit<AppleLoginState> {
  final AuthRepository authRepository;
  AppleLoginCubit(this.authRepository) : super(AppleLoginInitial());

  Future<void> appleLogin(BuildContext context) async {
    try {
      showLoading();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      var name = credential.givenName ?? '';
      var email = credential.email ?? '';
      
      final response = await authRepository.socialLogin(
        name,
        email,
        credential.userIdentifier!,
        "",
        "apple",
        credential.identityToken!,
        credential.authorizationCode,
      );

      if (response["status"] == 200) {

        LoginModel socialLoginModel = LoginModel.fromJson(response);
        box.put("UserData", jsonEncode(socialLoginModel.toJson()));
        loginModel = LoginModel.fromJson(socialLoginModel.toJson());
        box.put('Remember', true);
        box.put('Firstuser', true);
        UserData userObj = UserData();
        userObj.saveLoginData("UserData", jsonEncode(response));
       
        token = socialLoginModel.data?.token ?? "";
        socialEmail = socialLoginModel.data?.email ?? "";
        socialFirstName = socialLoginModel.data?.firstName ?? "";
        socialLastName = socialLoginModel.data?.lastName ?? "";

        
        if (socialLoginModel.data!.phone == null) {
          closeLoading();
          emit(AddPhoneNumberAppleState(socialLoginModel));
        } else {
          
          closeLoading();
          emit(AppleLoginSuccess(StaticModel.fromJson(response)));
        }
      } else {

        closeLoading();
      }
    } catch (e) {

      closeLoading();
    }
  }

  Future<void> updatePhonePhone(
      BuildContext context, {
        String? phone,
        String? countryCode,
        String? defaultCode,
        String? socialEmail,
      }) async {
    try {
      showLoading();
      final response = await authRepository.changePhone(
          phone: phone,
          countryCode: countryCode,
          defaultCode: defaultCode,
          socialEmail: socialEmail);
      if (response["status"] == 200) {
        closeLoading();
        Map map = {
          "phone": phone,
          "phone_country": countryCode,
          "first_name": socialLastName,
          "last_name": socialLastName,
          "email": socialEmail,
          "default_country": defaultCode,
        };
        emit(
            GoogleUpdatePhoneSuccess(CheckMobileModel.fromJson(response), map));
      } else {
        closeLoading();
        emit(GoogleCheckFailureState(response["error"]));
      }
    } catch (e) {
      closeLoading();
      emit(GoogleCheckFailureState("Failed to check host status."));
    }
  }
}

class AddPhoneNumberAppleState extends AppleLoginState {
  final LoginModel loginModel;

  AddPhoneNumberAppleState(this.loginModel);

  @override
  List<Object?> get props => [loginModel];
}

class GoogleUpdatePhoneSuccess extends AppleLoginState {
  final CheckMobileModel checkMobileModel;
  final Map? changeMobiles;

  GoogleUpdatePhoneSuccess(this.checkMobileModel, this.changeMobiles);

  @override
  List<Object?> get props => [checkMobileModel, changeMobiles];
}

class GoogleCheckLoadingState extends AppleLoginState {}

class GoogleCheckFailureState extends AppleLoginState {
  final String error;

  GoogleCheckFailureState(this.error);

  @override
  List<Object?> get props => [error];
}


