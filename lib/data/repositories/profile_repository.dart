import 'package:ride_on/core/services/http.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/material.dart';
import 'package:ride_on/core/utils/translate.dart';

import '../../core/services/config.dart';

class ProfileRepository {
  Future<Map<String, dynamic>> editProfile(
      {required Map<String, dynamic> postData}) async {
    try {
      var response = await httpPost(Config.editProfile, postData,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getSliders(
      {required Map<String, dynamic> postData}) async {
    try {
      var response = await httpGet(Config.sliders, postData,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      var response = await httpPost(Config.deleteAccount, {},
          context: navigatorKey.currentState!.context);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(
      {required Map<String, dynamic> postData}) async {
    try {
      var response = await httpPost(Config.uploadProfileImage, postData,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getSosData(
      {required Map<String, dynamic> postData}) async {
    try {
      var response = await httpGet(Config.sos, postData,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStaticPage(
      BuildContext context, String data) async {
    try {
      dynamic response;
      if (data == "About Us".translate(context)) {
        response = await httpGet(Config.staticPage, {"id": "2"},
            context: navigatorKey.currentContext!);
      } else if (data == "Help and Support".translate(context)) {
        response = await httpGet(Config.staticPage, {"id": "4"},
            context: navigatorKey.currentContext!);
      } else if (data == "Give us feedback".translate(context)) {
        response = await httpGet(Config.staticPage, {"id": "25"},
            context: navigatorKey.currentContext!);
      } else if (data == "Terms and Conditions" || data == "Privacy Policy") {
        response = await httpGet(Config.staticPage, {"id": "11"},
            context: navigatorKey.currentContext!);
      } else if (data == "Support") {
        response = await httpGet(Config.staticPage, {"id": "26"},
            context: navigatorKey.currentContext!);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGeneralData(
      {required Map<String, dynamic> postData}) async {
    try {
      var response = await httpGet(Config.getgeneralSettings, postData,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
