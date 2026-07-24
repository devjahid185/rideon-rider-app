import 'package:ride_on/core/extensions/workspace.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:ride_on/presentation/cubits/payment/payment_cubit.dart';
import 'package:ride_on/presentation/cubits/profile/edit_profile_cubit.dart';
import 'package:ride_on/presentation/cubits/realtime/get_ride_request_status_cubit.dart';
import 'package:ride_on/presentation/cubits/realtime/ride_request_cubit.dart';
import 'package:ride_on/presentation/cubits/realtime/update_ride_request_parameter.dart';
import 'package:ride_on/presentation/cubits/review/review_cubit.dart';
import 'package:ride_on/presentation/cubits/vehicle_data/get_vehicle_cetgegory_cubit.dart';

import '../../core/utils/theme/project_color.dart';
import 'auth/google_login_cubit.dart';
import 'auth/login_cubit.dart';
import 'auth/otp_verify_cubit.dart';
import 'auth/resend_otp_cubit.dart';
import 'auth/signup_cubit.dart';
import 'auth/user_authenticate_cubit.dart';
import 'book_ride_cubit.dart';
import 'location/get_nearby_drivers_cubit.dart';
import 'location/set_marker_cubit.dart';
import 'location/user_current_location_cubit.dart';

abstract class LogoutState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LogoutInitial extends LogoutState {}

class LogoutLoading extends LogoutState {}

class LogoutSuccess extends LogoutState {}

class LogoutFailure extends LogoutState {
  final String error;
  LogoutFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class LogoutCubit extends Cubit<LogoutState> {
  LogoutCubit() : super(LogoutInitial());

  Future<void> logout(BuildContext context) async {
    try {
      emit(LogoutLoading());

      final box = await Hive.openBox('appBox');
      await box.clear();
      clearData(context);

      appLocale = const Locale('en');
      bool defaultDarkMode = false;
      box.put("getDarkValue", defaultDarkMode);
      box.put("driver_status", false);
      notifires.setIsDark = defaultDarkMode;
      token = "";
      bearerToken = "";
      loginModel = null;
      latitudeGlobal = "";
      longitudeGlobal = "";

      emit(LogoutSuccess());
    } catch (e) {
      emit(LogoutFailure(e.toString()));
    }
  }
}

Future<void> clearData(BuildContext context) async {

      final box = await Hive.openBox('appBox');
      await box.clear();
   appLocale = const Locale('en');
      bool defaultDarkMode = false;
      box.put("getDarkValue", defaultDarkMode);
      box.put("driver_status", false);
      notifires.setIsDark = defaultDarkMode;
      token = "";
      bearerToken = "";
      loginModel = null;
      latitudeGlobal = "";
      longitudeGlobal = "";
     // ignore_for_file: use_build_context_synchronously
  context.read<AuthUserAuthenticateCubit>().resetState();
  context.read<GoogleLoginCubit>().resetState();
  context.read<VehicleDataUpdateCubit>().resetState();
  context.read<BookRideRealTimeDataBaseCubit>().resetState();
  context.read<GetSuggestionAddressCubit>().removeAddress();
  context.read<DriverMapCubit>().resetState();
  context.read<DriverNearByCubit>().resetNearByDriverState();
  context.read<GetPolylineCubit>().resetPolylines();
  context.read<GetCordinatesCubit>().removeCordinates();
  context.read<SetVehicleCategoryCubit>().resetState();
  context.read<SelectedAddressCubit>().resetAllParameter();
  context.read<MarkerCubit>().resetMarker();
  context.read<GetUpdatedLocationCubit>().resetLocation();

  context.read<BookRideUserCubit>().removeBookRideState();
  context.read<RideRequestCubit>().resetState();

  context.read<GetRideRequestStatusCubit>().resetState();

  context.read<ReviewCubit>().resetState();

  context.read<UpdatePaymentByUserCubit>().resetState();
  context.read<UpdateRideRequestParameterCubit>().resetState();
  context.read<AuthLoginCubit>().resetState();
  context.read<AuthOtpVerifyCubit>().resetState();
  context.read<AuthResendOtpCubit>().resetState();
  context.read<AuthSignUpCubit>().resetState();
  context.read<AuthUserAuthenticateCubit>().resetState();
  context.read<SetCountryCubit>().clear();
  context.read<GoogleLoginCubit>().resetState();
  context.read<BookRideRealTimeDataBaseCubit>().resetState();
  context.read<MyImageCubit>().updateMyImage("");
  context.read<NameCubit>().updateName("");
  context.read<EmailCubit>().updateEmail("");
  myImage="";
}


