import 'package:ride_on/domain/entities/booking_sucess.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/vehicle_repository.dart';

class BookRideState extends Equatable {
  final String rideId;
  final int userId;
  final String itemId;
  final int selectedDriverId;

  final String pickupAddress;
  final String pickupAddressLatitude;
  final String pickupAddressLongitude;
  final String dropoffAddress;
  final String dropoffAddressLatitude;
  final String dropoffAddressLongitude;
  final double acceptedDriverLat;
  final double acceptedDriverLng;
  final String rideMessage;
  final bool progressIndicator;
  final String userName;
  final String userImageUrl;
  final String userPhoneNumber;
  final String distance;
  final String travelCharges;
  final String routeStatus;
  final bool isSubmitting;

  const BookRideState({
    this.userImageUrl = "",
    this.itemId = "",
    this.rideId = "",
    this.rideMessage = "",
    this.acceptedDriverLat = 0.0,
    this.progressIndicator = false,
    this.acceptedDriverLng = 0.0,
    this.userId = 0,
    this.selectedDriverId = 0,
    this.pickupAddress = "",
    this.pickupAddressLatitude = "",
    this.pickupAddressLongitude = "",
    this.dropoffAddress = "",
    this.dropoffAddressLatitude = "",
    this.dropoffAddressLongitude = "",
    this.userName = "",
    this.userPhoneNumber = "",
    this.distance = "",
    this.travelCharges = "",
    this.routeStatus = "Pending",
    this.isSubmitting = false,
  });

  BookRideState copyWith({
    String? userImageUrl,
    String? itemId,
    String? rideId,
    bool? progressIndicator,
    double? acceptedDriverLat,
    double? acceptedDriverLng,
    int? userId,
    int? selectedDriverId,
    String? pickupAddress,
    String? pickupAddressLatitude,
    String? rideMessage,
    String? pickupAddressLongitude,
    String? dropoffAddress,
    String? dropoffAddressLatitude,
    String? dropoffAddressLongitude,
    String? userName,
    String? userPhoneNumber,
    String? distance,
    String? travelCharges,
    String? routeStatus,
    bool? isSubmitting,
  }) {
    return BookRideState(
      userImageUrl: userImageUrl ?? this.userImageUrl,
      itemId: itemId ?? this.itemId,
      rideId: rideId ?? this.rideId,
      progressIndicator: progressIndicator ?? this.progressIndicator,
      rideMessage: rideMessage ?? this.rideMessage,
      acceptedDriverLat: acceptedDriverLat ?? this.acceptedDriverLat,
      acceptedDriverLng: acceptedDriverLng ?? this.acceptedDriverLng,
      userId: userId ?? this.userId,
      selectedDriverId: selectedDriverId ?? this.selectedDriverId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupAddressLatitude:
          pickupAddressLatitude ?? this.pickupAddressLatitude,
      pickupAddressLongitude:
          pickupAddressLongitude ?? this.pickupAddressLongitude,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffAddressLatitude:
          dropoffAddressLatitude ?? this.dropoffAddressLatitude,
      dropoffAddressLongitude:
          dropoffAddressLongitude ?? this.dropoffAddressLongitude,
      userName: userName ?? this.userName,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      distance: distance ?? this.distance,
      travelCharges: travelCharges ?? this.travelCharges,
      routeStatus: routeStatus ?? this.routeStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        userImageUrl,
        itemId,
        rideId,
        acceptedDriverLat,
        acceptedDriverLng,
        userId,
        progressIndicator,
        selectedDriverId,
        rideMessage,
        pickupAddress,
        pickupAddressLatitude,
        pickupAddressLongitude,
        dropoffAddress,
        dropoffAddressLatitude,
        dropoffAddressLongitude,
        userName,
        userPhoneNumber,
        distance,
        travelCharges,
        routeStatus,
        isSubmitting,
      ];
}

class BookRideRealTimeDataBaseCubit extends Cubit<BookRideState> {
  BookRideRealTimeDataBaseCubit() : super(const BookRideState());

  void removeUserImageUrl() {
    emit(state.copyWith(
      userImageUrl: "",
    ));
  }

  void updateUserImageUrl({String? userImageUrl}) {
    emit(state.copyWith(
      userImageUrl: userImageUrl,
    ));
  }

  void removeItemId() {
    emit(state.copyWith(
      itemId: "",
    ));
  }

  void updateItemId({String? itemId}) {
    emit(state.copyWith(
      itemId: itemId,
    ));
  }

  void removeRideId() {
    emit(state.copyWith(
      rideId: "",
    ));
  }

  void updateRideId({String? rideId}) {
    emit(state.copyWith(
      rideId: rideId,
    ));
  }

  void removeRideMessage() {
    emit(state.copyWith(rideMessage: ""));
  }

  void removeProgressIndicator() {
    emit(state.copyWith(progressIndicator: false));
  }

  void updatePickupAddress({
    String? pickupAddress,
  }) {
    emit(state.copyWith(
      pickupAddress: pickupAddress,
    ));
  }

  void removePickupAddress() {
    emit(state.copyWith(
      pickupAddress: "",
    ));
  }

  void updatePickupLatAndLng({
    String? pickupAddressLatitude,
    String? pickupAddressLongitude,
  }) {
    emit(state.copyWith(
      pickupAddressLatitude: pickupAddressLatitude,
      pickupAddressLongitude: pickupAddressLongitude,
    ));
  }

  void removePickupLatAndLng() {
    emit(state.copyWith(
      pickupAddressLatitude: "",
      pickupAddressLongitude: "",
    ));
  }

  // Update Addresses
  void updateDropOffAddress({
    String? dropoffAddress,
  }) {
    emit(state.copyWith(
      dropoffAddress: dropoffAddress,
    ));
  }

  void removeDropOffAddress() {
    emit(state.copyWith(
      dropoffAddress: "",
    ));
  }

  // Update Addresses
  void updateDropOffLatAndLng({
    String? dropoffAddressLatitude,
    String? dropoffAddressLongitude,
  }) {
    emit(state.copyWith(
      dropoffAddressLatitude: dropoffAddressLatitude,
      dropoffAddressLongitude: dropoffAddressLongitude,
    ));
  }

  void removeDropoffLatAndLng() {
    emit(state.copyWith(
      dropoffAddressLatitude: "",
      dropoffAddressLongitude: "",
    ));
  }

  // Update User Details
  void updateUserDetails({
    String? userName,
    String? userPhoneNumber,
    int? userId,
  }) {
    emit(state.copyWith(
      userId: userId,
      userName: userName,
      userPhoneNumber: userPhoneNumber,
    ));
  }

  void resetState() {
    emit(const BookRideState());
  }
}

abstract class BookRideUserState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookRideInitial extends BookRideUserState {}

class BookRideUserSuccess extends BookRideUserState {
  final String? pikupOtp;
  final String? dropOtp;
  final int? bookingId;
  final String? rideId;
  final String? paymentUrl;

  BookRideUserSuccess(
      {this.pikupOtp, this.bookingId, this.rideId, this.paymentUrl,this.dropOtp});
  @override
  List<Object?> get props => [pikupOtp, bookingId, rideId, paymentUrl];
}

class BookRideUserFailure extends BookRideUserState {
  final String? error;
  BookRideUserFailure({this.error});
  @override
  List<Object?> get props => [error];
}

class BookRideUserCubit extends Cubit<BookRideUserState> {
  final VehicleRepository vehicleRepository;
  BookRideUserCubit(this.vehicleRepository) : super(BookRideInitial());

   Future<void> bookRide(
      {required String rideId,
      required int itemTypeId,
      required String driverId,
      required String serviceTypeId,
      required String totalFare,
      required BuildContext context,
      required String estimatedDistance,
      required String itemId,
      required String pickupAddress,
      required String dropOffAddress,
      required String date,
      required String pickupLat,
      required String pickupLng,
      required String paymentMethod,
      required String dropOffLat,
      required String dropOffLng}) async {
    try {
      final response = await vehicleRepository.bookRide(
          context: context,
          itemId: itemId,
          rideId: rideId,
          serviceTypeId: serviceTypeId,
          itemTypeId: itemTypeId,
          driverId: driverId,
          totalFare: totalFare,
          estimatedDistance: estimatedDistance,
          pickupAddress: pickupAddress,
          dropOffAddress: dropOffAddress,
          date: date,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          paymentMethod: paymentMethod,
          dropOffLat: dropOffLat,
          dropOffLng: dropOffLng);

      if (response["status"] == 200) {
        BookingSucessModel bookingSucessModel =
            BookingSucessModel.fromJson(response);
        emit(BookRideUserSuccess(
            pikupOtp: bookingSucessModel.data!.pickupOtp ?? "",
            bookingId: response["data"]["booking_id"],
            paymentUrl: response["data"]["payment_url"],
            dropOtp:response["data"]["drop_otp"]??"" ,
            rideId: rideId));
      } else {
        emit(BookRideUserFailure(error: response["error"]));

      }
    } catch (error) {
      emit(BookRideUserFailure(error: "error$error"));

    }
  }

  void removeBookRideState() {
    emit(BookRideInitial());
  }
}

/// for updated ride status
abstract class UpdateRideStatusInDatabaseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RideStatusInitial extends UpdateRideStatusInDatabaseState {}

class RideStatusSuceessUpdated extends UpdateRideStatusInDatabaseState {
  final String? status;
  RideStatusSuceessUpdated({this.status});

  @override
  List<Object?> get props => [status];
}

class UpdateRideStatusInDatabaseCubit
    extends Cubit<UpdateRideStatusInDatabaseState> {
  VehicleRepository realtimeRepository;
  UpdateRideStatusInDatabaseCubit(this.realtimeRepository)
      : super(RideStatusInitial());

  Future<void> updateRideStatus(
      {required BuildContext context,
      required String bookingId,
      required String rideStatus}) async {
    try {
      var response = await realtimeRepository.updateRideStatus(
          context: context, bookingId: bookingId, rideStatus: rideStatus);

      if (response["status"] == 200) {
        emit(RideStatusSuceessUpdated(status: "com"));
      }
    } catch (err) {
   //
    }
  }

  void resetStatus() {
    emit(RideStatusInitial());
  }
}


