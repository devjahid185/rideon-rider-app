
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:ride_on/app/route_settings.dart';
import 'package:ride_on/domain/entities/ride_request.dart';
import 'package:ride_on/presentation/screens/Splash/splash_screen.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../cubits/book_ride_cubit.dart';
import '../../cubits/realtime/check_ride_request_cubit.dart';
import '../../cubits/realtime/ride_request_cubit.dart';
import '../Home/item_home_screen.dart';
import '../Onboarding/on_boarding_screen.dart';
import '../Search/send_ride_request_screen.dart';
import '../payment/rider_payment_screen.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});
  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  late Box box;
  dynamic data;
  RideRequest? rideData;

  @override
  void initState() {
    super.initState();
    box = Hive.box('appBox');
    getCurrency(context);
    _handleNavigation();
  }

  void _handleNavigation() {
    final bool isFirstUser = box.get('Firstuser', defaultValue: false) != true;
    final duration = Duration(seconds: isFirstUser ? 4 : 0);

    Timer(duration, () {
      if (isFirstUser) {
        navigateToScreen(context, () => const Onboardingscreen());
        return;
      }

      data = box.get('ride_data');
      if (data == null) {
        navigateToScreen(context, () => const ItemHomeScreen());
      } else {
        final String rideId = data["rideId"] ?? "";
        context.read<CheckStatusCubit>().checkStatus(rideId);
      }
    });
  }

  void _clearRideData() {
    box.delete("ride_data");
    box.delete("payment_url");
    box.delete("PickOtp");
    box.delete("bookingId");
    box.delete("selected_vehicle");
  }

  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);

    return Scaffold(
      backgroundColor: notifires.getbgcolor,
      body: BlocListener<CheckStatusCubit, CheckRideStatusState>(
        listener: _rideStatusListener,
        child: const SplashScreen(),
      ),
    );
  }

  void _rideStatusListener(BuildContext context, CheckRideStatusState state) {
    if (state is CheckRideSuccess) {
      _handleRideSuccess(context, state);
    } else if (state is CheckRideFailed) {
      _clearRideData();
      navigateToScreen(context, () => const ItemHomeScreen());
    }
  }

  void _handleRideSuccess(
      BuildContext context, CheckRideSuccess state) {
    context.read<RideRequestCubit>().loadRideFromHive();

    final bookRideCubit =
        context.read<BookRideRealTimeDataBaseCubit>();

    bookRideCubit.updatePickupLatAndLng(
      pickupAddressLatitude: data["pickLat"].toString(),
      pickupAddressLongitude: data["pickLng"].toString(),
    );

    bookRideCubit.updateDropOffLatAndLng(
      dropoffAddressLatitude: data["dropLat"].toString(),
      dropoffAddressLongitude: data["dropLng"].toString(),
    );

    bookRideCubit.updatePickupAddress(
        pickupAddress: data["pickAddress"]);
    bookRideCubit.updateDropOffAddress(
        dropoffAddress: data["dropAddress"]);

    final Map<String, dynamic> vehicle =
        jsonDecode(box.get('selected_vehicle'));

    switch (state.status) {
      case "pending":
      case "accepted":
      case "ongoing":
      case "pick_up":
        goToWithReplacement(
          SendRideRequestScreen(
            selectedVehicleData: vehicle,
            statusOfRide: state.status,
            pickUpOtp: box.get("PickOtp") ?? "",
            dropotp: box.get("DropOtp") ?? "",
            bookingId: box.get("bookingId")?.toString() ?? "",
            rideId: data["rideId"],
            paymentUrl: box.get("payment_url") ?? "",
          ),
        );
        break;

      case "completed":
        if (state.paymentStatus == "collected") {
          _clearRideData();
          navigateToScreen(context, () => const ItemHomeScreen());
        } else {
          navigateToScreen(
            context,
            () => RiderPaymentScreen(
              bookingId: box.get("bookingId")?.toString() ?? "",
              rideId: data["rideId"],
              fare: vehicle["fare"],
              paymentUrl: box.get("payment_url"),
            ),
          );
        }
        break;

      case "rejected":
        _clearRideData();
        navigateToScreen(context, () => const ItemHomeScreen());
        break;
    }
  }
}


