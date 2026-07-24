// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:ride_on/core/extensions/helper/push_notifications.dart';
import 'package:ride_on/domain/entities/login_data.dart';
import 'package:ride_on/data/repositories/auth_repository.dart';
import 'package:ride_on/core/services/data_store.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ride_on/presentation/cubits/auth/user_authenticate_cubit.dart';

import '../../../core/utils/common_widget.dart';
import '../../../domain/entities/check_mobile.dart';
import '../book_ride_cubit.dart';

abstract class GoogleLoginState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GoogleInitial extends GoogleLoginState {}

class GoogleLoading extends GoogleLoginState {}

class GoogleLoginSucess extends GoogleLoginState {
  @override
  List<Object?> get props => [];
}

class GoogleLoginFailure extends GoogleLoginState {
  final String error;
  GoogleLoginFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class GoogleLoginCubit extends Cubit<GoogleLoginState> {
  AuthRepository authRepository;
  GoogleLoginCubit(this.authRepository) : super(GoogleInitial());

  Future<void> googleLogin(BuildContext context) async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    await googleSignIn.signOut();
    try {
      debugPrint("[GoogleLogin] Start sign-in flow");
      Widgets.showLoader(context);

      var result = await googleSignIn.signIn();
      if (result != null) {
        debugPrint(
            "[GoogleLogin] Account selected | email=${result.email} | id=${result.id}");

        GoogleSignInAuthentication? googleAuth = await result.authentication;
        debugPrint(
            "[GoogleLogin] Token received | hasAccessToken=${googleAuth.accessToken != null} | hasIdToken=${googleAuth.idToken != null}");
        OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        User? firebaseUser = userCredential.user;
        if (firebaseUser != null) {
          debugPrint(
              "[GoogleLogin] Firebase sign-in success | uid=${firebaseUser.uid} | email=${firebaseUser.email}");

          final response = await authRepository.socialLogin(
            "${result.displayName}",
            result.email,
            result.id,
            "${result.photoUrl}",
            "google",
            "",
            "",
          );
          debugPrint(
              "[GoogleLogin] socialLogin response | status=${response["status"]} | message=${response["message"] ?? response["error"] ?? "n/a"} | exception=${response["exception"] ?? "n/a"} | raw=${response["raw_body"] ?? "n/a"}");
          if (response["status"] == 200) {

            LoginModel socialLoginModel = LoginModel.fromJson(response);
            box.put("UserData", jsonEncode(socialLoginModel.toJson()));
            loginModel = LoginModel.fromJson(socialLoginModel.toJson());
            context.read<BookRideRealTimeDataBaseCubit>().updateUserDetails(
                userName: loginModel!.data!.firstName,
                userPhoneNumber:
                    "${loginModel!.data!.phoneCountry} ${loginModel!.data!.phone}",
                userId: loginModel!.data!.id!.toInt());

            box.put('Remember', true);
            box.put('Firstuser', true);
            UserData userObj = UserData();
            userObj.saveLoginData("UserData", jsonEncode(response));
            token = socialLoginModel.data?.token ?? "";
            await syncPendingFcmTokenIfAny(forceSync: true);

            if (socialLoginModel.data!.phone == null) {
              Widgets.hideLoder(context);
              debugPrint("[GoogleLogin] Phone missing, navigating to update screen");
              emit(AddPhoneNumberState(socialLoginModel));
            } else {
              Widgets.hideLoder(context);
              debugPrint("[GoogleLogin] Login complete, navigating home");
              emit(GoogleLoginSucess());
            }
          } else {
            Widgets.hideLoder(context);
            emit(GoogleLoginFailure(
                response["error"]?.toString() ??
                    response["message"]?.toString() ??
                    "Social login failed"));
          }
        } else {
          Widgets.hideLoder(context);
          emit(GoogleLoginFailure("Firebase user is null after Google sign-in"));
        }
      } else {
        Widgets.hideLoder(context);
        debugPrint("[GoogleLogin] User cancelled account selection");
        emit(GoogleLoginFailure("Google sign-in cancelled"));
      }
    } catch (error) {
      Widgets.hideLoder(context);
      debugPrint("[GoogleLogin] Exception: $error");
      emit(GoogleLoginFailure(error.toString()));


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
      Widgets.showLoader(context);
      final response = await authRepository.changePhone(
          phone: phone,
          countryCode: countryCode,
          defaultCode: defaultCode,
          socialEmail: socialEmail);
      Widgets.hideLoder(context);

      if (response["status"] == 200) {
        context.read<SetCountryCubit>().reset();
        emit(GoogleUpdatePhoneSuccess(CheckMobileModel.fromJson(response)));
      } else {
        emit(GoogleCheckFailureState(response["error"]));
      }
    } catch (e) {
      context.read<SetCountryCubit>().reset();
      Widgets.hideLoder(context);
      emit(GoogleCheckFailureState("Failed to check host status."));
    }
  }

  void resetState() {
    emit(GoogleInitial());
  }
}

class AddPhoneNumberState extends GoogleLoginState {
  final LoginModel loginModel;

  AddPhoneNumberState(this.loginModel);

  @override
  List<Object?> get props => [loginModel];
}

class GoogleUpdatePhoneSuccess extends GoogleLoginState {
  final CheckMobileModel checkMobileModel;

  GoogleUpdatePhoneSuccess(this.checkMobileModel);

  @override
  List<Object?> get props => [checkMobileModel];
}

class GoogleCheckLoadingState extends GoogleLoginState {}

class GoogleCheckFailureState extends GoogleLoginState {
  final String error;

  GoogleCheckFailureState(this.error);

  @override
  List<Object?> get props => [error];
}


