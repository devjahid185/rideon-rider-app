import 'dart:convert';
import 'package:ride_on/domain/entities/login_data.dart';
import 'package:ride_on/core/services/data_store.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/cubits/book_ride_cubit.dart';

final List locale = [
  {'name': 'English', 'locale': "en"},
  {'name': 'Arabic', 'locale': 'ar'}
];

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String token = "";
LoginModel? loginModel;
String selectedCountry = "+1";
String defaultCountry = "US";
var loginWithSocialMedia = false;
String bearerToken = box.get("bearerToken")??"";
String myImage = "";
String myName = "";
String socialEmail = "";
String socialFirstName = "";
String socialLastName = "";
Locale appLocale = const Locale('en');
var latitudeGlobal = "";
var longitudeGlobal = "";
dynamic oneSignalPlayerId = "";
dynamic oneSignalToken = "";
dynamic oneSignalOptedIn = "";
bool isManuallyCancelled = false;
String? activeRideRequestId;
bool isNumeric=false;

String distanceInKmRide = "";
getUserLocation() async {
  try {
    await Future.delayed(const Duration(seconds: 3));
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permissionGranted = await Geolocator.checkPermission();
    if (permissionGranted == LocationPermission.denied) {
      permissionGranted = await Geolocator.requestPermission();
    }
    if (permissionGranted == LocationPermission.denied ||
        permissionGranted == LocationPermission.deniedForever) {
      return;
    }

    final locationData = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    latitudeGlobal = locationData.latitude.toString();
    longitudeGlobal = locationData.longitude.toString();
  } catch (e) {
    //
  }
}

String currency = "";
getUserDataLocallyToHandleTheState(BuildContext context) async {
  if (box.get("UserData") != null) {
    String data = box.get("UserData");


    if (data.isNotEmpty) {
      try {
        var json = jsonDecode(data);
        loginModel = LoginModel.fromJson(json);

        if (loginModel?.data != null) {
          final userData = loginModel!.data!;
          token = userData.token ?? "";
          myName = loginModel!.data!.firstName!;
          socialEmail = userData.email ?? "";
          if (userData.profileImage != null &&
              userData.profileImage["url"] != null &&
              userData.profileImage["url"].toString().isNotEmpty) {
            myImage = userData.profileImage["url"].toString();
            context
                .read<BookRideRealTimeDataBaseCubit>()
                .updateUserImageUrl(userImageUrl: myImage);
          }

          context.read<BookRideRealTimeDataBaseCubit>().updateUserDetails(
              userName: loginModel!.data!.firstName,
              userPhoneNumber:
                  "${loginModel!.data!.phoneCountry} ${loginModel!.data!.phone}",
              userId: loginModel!.data!.id!.toInt());
        }
      } catch (e) {
  //
      }
    }
  }
}
