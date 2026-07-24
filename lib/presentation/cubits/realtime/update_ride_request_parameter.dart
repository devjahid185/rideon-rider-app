// ignore_for_file: empty_catches

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdateRideRequestParameterCubit extends Cubit<String> {
  UpdateRideRequestParameterCubit() : super("");
  final DatabaseReference _rideRequestsRef =
      FirebaseDatabase.instance.ref().child('ride_requests');

  void updatePaymentStatus(
      {required String rideId, required String paymentStatus}) {
    _rideRequestsRef.child(rideId).update({
      'paymentStatus': paymentStatus,
    }).then((_) {

    }).catchError((error) {

    });
    _rideRequestsRef.child(rideId).remove();
  }
  void removeRideRequest({required String rideId}) {
    _rideRequestsRef.child(rideId).remove().then((_) {

    }).catchError((error) {

    });
  }

  void updatePaymentMehod(
      {required String rideId, required String paymentMethod}) {
    _rideRequestsRef.child(rideId).update({
      'paymentMethod': paymentMethod,
    }).then((_) {

    }).catchError((error) {

    });
  }
  void updatePaymentAmountFirebase(
      {required String rideId, required String totalFare,required String couponApply,required String discountFare}) {
    _rideRequestsRef.child(rideId).update({
      'travelCharges': totalFare,
      'couponApply':couponApply,
      'discountFare':discountFare
    }).then((_) {

    }).catchError((error) {

    });
  }

  Future<void> updateFirebaseUserParameter({
    required Map<String, dynamic> userParameter,
    required String rideId,
  }) async {
    try {
      if (rideId.isNotEmpty) {
        await _rideRequestsRef.child(rideId).update({...userParameter});
      }
    } catch (e) {

    }
  }

  void resetState() {
    emit("");
  }
}


