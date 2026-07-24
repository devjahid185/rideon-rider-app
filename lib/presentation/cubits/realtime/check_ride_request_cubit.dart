import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CheckRideStatusState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckRideInitial extends CheckRideStatusState {}

class CheckRideLoading extends CheckRideStatusState {}

class CheckRideSuccess extends CheckRideStatusState {
  final String status, paymentStatus;

  CheckRideSuccess(this.status, this.paymentStatus);
}

class CheckRideSuccessDriver extends CheckRideStatusState {
  final String status, paymentStatus, bookingId;

  CheckRideSuccessDriver(this.status, this.paymentStatus, this.bookingId);
}

class CheckRideFailed extends CheckRideStatusState {
  final String error;

  CheckRideFailed(this.error);
}

class CheckRideFailedDriver extends CheckRideStatusState {
  final String error;

  CheckRideFailedDriver(this.error);
}



class CheckStatusCubit extends Cubit<CheckRideStatusState> {
  CheckStatusCubit() : super(CheckRideInitial());

  Future<void> checkStatus(String rideId) async {
    try {
      emit(CheckRideLoading());

      final ref = FirebaseDatabase.instance.ref("ride_requests/$rideId");
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final rawData = snapshot.value;


        final Map<String, dynamic> data =
            (rawData is Map<Object?, Object?>) ? convertMap(rawData) : {};

        final String status = data["status"]?.toString() ?? "";
        final String paymentStatus = data["paymentStatus"]?.toString() ?? "";

        emit(CheckRideSuccess(status, paymentStatus));

      } else {
        emit(CheckRideFailed("Ride not found."));

      }
    } catch (e) {
      emit(CheckRideFailed("Error fetching ride data."));

    }
  }

  Map<String, dynamic> convertMap(Map<Object?, Object?> original) {
    return original.map((key, value) {
      return MapEntry(
        key.toString(),
        value is Map<Object?, Object?> ? convertMap(value) : value,
      );
    });
  }
}


