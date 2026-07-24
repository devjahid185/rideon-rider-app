import 'package:ride_on/core/services/http.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/material.dart';

import '../../core/services/config.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(
      {required String phoneNumber, required String phoneCountry}) async {
    if (!phoneCountry.startsWith("+")) {
      phoneCountry = '+$phoneCountry';
    }
    try {
      final data = {
        "phone": phoneNumber,
        "phone_country": phoneCountry,
      };
      var response = await httpPost(Config.sendMobileLoginOtp, data,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> userAuthenticateLogin(
      {required String phoneNumber,
      required String phoneCountry,
      required String otpValue}) async {
    if (!phoneCountry.startsWith("+")) {
      phoneCountry = '+$phoneCountry';
    }
    try {
      var response = await httpPost(
          Config.userMobileLogin,
          {
            "phone": phoneNumber,
            "phone_country": phoneCountry,
            "otp_value": otpValue,
          },
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signUp(
      {BuildContext? context,
      String? name,
      String? phoneNumber,
      String? email,
      String? phoneCountry,
      String? defaultCountry}) async {
    if (!phoneCountry!.startsWith("+")) {
      phoneCountry = '+$phoneCountry';
    }
    final response = await httpPost(
        Config.registerUser,
        {
          'phone': phoneNumber,
          'email': email,
          "phone_country": phoneCountry,
          "default_country": defaultCountry,
          "first_name": name
        },
        context: navigatorKey.currentContext!);
    return response;
  }

  Future<Map<String, dynamic>> changeEmail({String? email}) async {
    try {
      var data = {"email": email};
      var response = await httpPost(Config.checkEmail, data,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forChangeEmail({
    otp,
    email,
  }) async {
    try {
      var response = await httpPost(
          Config.changeEmail, {"email": email, "otp_value": otp},
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resendEmailOtpForChange(
      Map<String, dynamic> data) async {
    try {
      var response = await httpPost(Config.resendTokenEmailChange, data,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> otpVerify(
      {String? phone,
      String? otpValue,
      String? countryCode,
      String? email,
      String? resetToken,
      bool? changeEmail,
      bool? changeMobile,
      String? defaultCountry}) async {
    if (!countryCode!.startsWith("+")) {
      countryCode = '+$countryCode';
    }
    try {

   var   response = await httpPost(Config.otpVerification,
          {"phone": phone, "otp_value": otpValue, "phone_country": countryCode},
          context: navigatorKey.currentContext!);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resendOtp({
    String? phone,
    String? phoneCountry,

  }) async {
    if (!phoneCountry!.startsWith("+")) {
      phoneCountry = '+$phoneCountry';
    }

    try {


  var    response = await httpPost(
          context: navigatorKey.currentContext!,
          Config.resendOtp,
          {"phone": phone, "phone_country": phoneCountry});


      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> socialLogin(
      String displayName,
      String email,
      String id,
      String profileImage,
      String loginType,
      String identityToken,
      String authorizationCode) async {
    try {
      Map<String, String> postData = {
        "displayName": displayName,
        "email": email,
        "id": id,
        "profile_image": profileImage,
        "login_type": loginType,
        "identityToken": identityToken,
        "authorizationCode": authorizationCode
      };
      var response = await httpPost(
          context: navigatorKey.currentContext!, Config.socialLogin, postData);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changePhone({
    String? phone,
    String? countryCode,
    String? defaultCode,
    String? socialEmail,
  }) async {
    if (!countryCode!.startsWith("+")) {
      countryCode = '+$countryCode';
    }
    try {
      var data = {
        "phone": phone,
        "phone_country": countryCode,
        "default_country": defaultCode,
      };
      var response = await httpPost(
          context: navigatorKey.currentContext!,
          Config.checkMobileNumber,
          data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forChangePhoneNumber(
      {number, cuntryCode, otp, defaultCountry}) async {
    if (!cuntryCode!.startsWith("+")) {
      cuntryCode = '+$cuntryCode';
    }

    try {
      Map<String, dynamic> map = {
        "phone": number,
        "phone_country": cuntryCode,
        "otp_value": otp,
        "default_country": defaultCountry,
      };

      var response = await httpPost(
          context: navigatorKey.currentContext!,
          Config.changeMobileNumber,
          map);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
