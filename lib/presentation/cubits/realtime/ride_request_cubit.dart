import 'dart:async';
import 'package:ride_on/core/services/data_store.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RideRequestState extends Equatable {
  final bool isSubmitting;
  final bool progressIndicator;
  final List<Map<String, dynamic>> nearbyDrivers;
  final String itemId;
  final String rideId;
  final String? itemTypeId;
  final String selectedDriverId;
  final String fireStoreToken;
  final String distanceInKm;
  final String farePrice;
  final double acceptedDriverLat;
  final double acceptedDriverLng;
  final String acceptedDriverName;
  final String acceptedDriverImageUrl;
  final String acceptedDriverVechileNumber;
  final String acceptedDriverVechileName;
  final String driverRating;
  final String accepteDriverPhoneNumber;
  final String acceptedDriverPhoneCountryCode;
  final String acceptedDriverVehicleMake;
  final String acceptedDriverVehicleModel;
  final String vehicleMake;
  final String vehicleModel;
  final String rideMessage;
  final String pickupAddress;
  final String dropOffAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;

  const RideRequestState({
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    this.dropoffLat = 0.0,
    this.dropoffLng = 0.0,
    this.itemTypeId = "",
    this.pickupAddress = "",
    this.dropOffAddress = "",
    this.farePrice = "",
    this.distanceInKm = "",
    this.nearbyDrivers = const [],
    this.vehicleMake = "",
    this.vehicleModel = "",
    this.acceptedDriverVehicleMake = "",
    this.acceptedDriverVehicleModel = "",
    this.accepteDriverPhoneNumber = "",
    this.acceptedDriverPhoneCountryCode = "",
    this.driverRating = "",
    this.acceptedDriverImageUrl = "",
    this.acceptedDriverName = "",
    this.acceptedDriverVechileNumber = "",
    this.acceptedDriverVechileName = "",
    this.itemId = "",
    this.rideMessage = "",
    this.selectedDriverId = '',
    this.fireStoreToken = '',
    this.rideId = "",
    this.isSubmitting = false,
    this.progressIndicator = false,
    this.acceptedDriverLat = 0.0,
    this.acceptedDriverLng = 0.0,
  });

  RideRequestState copyWith({
    List<Map<String, dynamic>>? nearbyDrivers,
    String? distanceInKm,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? pickupAddress,
    String? dropOffAddress,
    String? farePrice,
    String? vehicleMake,
    String? vehicleModel,
    String? acceptedDriverVehicleMake,
    String? acceptedDriverVehicleModel,
    String? accepteDriverPhoneNumber,
    String? acceptedDriverPhoneCountryCode,
    String? driverRating,
    String? acceptedDriverName,
    String? acceptedDriverImageUrl,
    String? acceptedDriverVechileNumber,
    String? acceptedDriverVechileName,
    String? rideMessage,
    String? selectedDriverId,
    String? fireStoreToken,
    String? itemId,
    String? rideId,
    String? itemTypeId,
    bool? isSubmitting,
    bool? progressIndicator,
    double? acceptedDriverLat,
    double? acceptedDriverLng,
  }) {
    return RideRequestState(
        pickupLat: pickupLat ?? this.pickupLat,
        pickupLng: pickupLng ?? this.pickupLng,
        dropoffLng: dropoffLng ?? this.dropoffLng,
        dropoffLat: dropoffLat ?? this.dropoffLat,
        itemTypeId: itemTypeId ?? this.itemTypeId,
        pickupAddress: pickupAddress ?? this.pickupAddress,
        dropOffAddress: dropOffAddress ?? this.dropOffAddress,
        farePrice: farePrice ?? this.farePrice,
        distanceInKm: distanceInKm ?? this.distanceInKm,
        nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
        vehicleMake: vehicleMake ?? this.vehicleMake,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        acceptedDriverVehicleMake:
            acceptedDriverVehicleMake ?? this.acceptedDriverVehicleMake,
        acceptedDriverVehicleModel:
            acceptedDriverVehicleModel ?? this.acceptedDriverVehicleModel,
        accepteDriverPhoneNumber:
            accepteDriverPhoneNumber ?? this.accepteDriverPhoneNumber,
        acceptedDriverPhoneCountryCode: acceptedDriverPhoneCountryCode ??
            this.acceptedDriverPhoneCountryCode,
        driverRating: driverRating ?? this.driverRating,
        acceptedDriverImageUrl:
            acceptedDriverImageUrl ?? this.acceptedDriverImageUrl,
        acceptedDriverName: acceptedDriverName ?? this.acceptedDriverName,
        acceptedDriverVechileName:
            acceptedDriverVechileName ?? this.acceptedDriverVechileName,
        acceptedDriverVechileNumber:
            acceptedDriverVechileNumber ?? this.acceptedDriverVechileNumber,
        itemId: itemId ?? this.itemId,
        rideMessage: rideMessage ?? this.rideMessage,
        selectedDriverId: selectedDriverId ?? this.selectedDriverId,
        fireStoreToken: fireStoreToken ?? this.fireStoreToken,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        progressIndicator: progressIndicator ?? this.progressIndicator,
        rideId: rideId ?? this.rideId,
        acceptedDriverLat: acceptedDriverLat ?? this.acceptedDriverLat,
        acceptedDriverLng: acceptedDriverLng ?? this.acceptedDriverLng);
  }

  @override
  List<Object?> get props => [
        pickupLat,
        pickupLng,
        dropoffLng,
        dropoffLat,
        itemTypeId,
        pickupAddress,
        dropOffAddress,
        farePrice,
        distanceInKm,
        nearbyDrivers,
        vehicleMake,
        vehicleModel,
        acceptedDriverVehicleMake,
        acceptedDriverVehicleModel,
        accepteDriverPhoneNumber,
        acceptedDriverPhoneCountryCode,
        driverRating,
        acceptedDriverImageUrl,
        acceptedDriverVechileName,
        acceptedDriverVechileNumber,
        acceptedDriverName,
        itemId,
        rideId,
        isSubmitting,
        progressIndicator,
        acceptedDriverLat,
        acceptedDriverLng,
        selectedDriverId,
        fireStoreToken,
        rideMessage
      ];
}

class RideRequestInitial extends RideRequestState {}

class RideRequestCubit extends Cubit<RideRequestState> {
  RideRequestCubit() : super(const RideRequestState());

  void updateNearByDrivers({List<Map<String, dynamic>>? nearbyDrivers}) {
    emit(state.copyWith(nearbyDrivers: nearbyDrivers));
  }

  void updateFareAndDistanceOfSelectedType({String? distanceInKm}) {
    emit(state.copyWith(distanceInKm: distanceInKm));
  }

  void removeFareAndDistanceOfSelectedType() {
    emit(state.copyWith(distanceInKm: ""));
  }

  void removeNearByDrivers() {
    emit(state.copyWith(nearbyDrivers: []));
  }

  void removeRideMessage() {
    emit(state.copyWith(rideMessage: ""));
  }

  void removeProgressIndicator() {
    emit(state.copyWith(progressIndicator: false));
  }

  void removeIsSubmitting() {
    emit(state.copyWith(isSubmitting: false));
  }

  Future<void> createDriverData({
    required String rideId,
    bool? checkRestart,
    required BuildContext context,
    required List<Map<String, dynamic>> nearbyDrivers,
    required String userId,
    required String userName,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required int durationForSearch,
    required double dropoffLat,
    required double dropoffLng,
    required String userPhoneNumber,
    String? userImageUrl,
    required String dropoffAddress,
    required String travelCharges,
    required String routeStatus,
    required String routeDistance,
    required String totalTime,
  }) async {
    box.delete("rideId");
    isManuallyCancelled = false;
    final currentRequestId = DateTime.now().millisecondsSinceEpoch.toString();
    activeRideRequestId = currentRequestId;
    final Map<String, dynamic>? parcelData =
        box.get('current_parcel_data') as Map<String, dynamic>?;
    String name = "";
    String weight = "";
    String receiverName = "";
    String receiverPhone = "";
    String pickupInstructions = "";
    if (parcelData != null) {
      name = parcelData['name'] ?? '';
      weight = parcelData['weight'] ?? '';
      receiverName = parcelData['receiverName'] ?? '';
      receiverPhone = parcelData['receiverPhone'] ?? '';
      pickupInstructions = parcelData['pickupInstructions'] ?? '';
    }

    if (checkRestart == false) {
      createRealTimeInstance(
          dropoffAddress: dropoffAddress,
          dropoffLat: dropoffLat,
          dropoffLng: dropoffLng,
          pickupAddress: pickupAddress,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          userId: userId,
          routeDistance: routeDistance,
          userPhoneNumber: userPhoneNumber,
          rideId: rideId,
          userName: userName,
          userImageUrl: userImageUrl,
          travelCharges: travelCharges,
          totalTime: totalTime,
          routeStatus: 'pending');
    }

    final rideRequestData = {
      'pickupLocation': pickupAddress,
      'dropoffLocation': dropoffAddress,
      'rideId': rideId,
      'userId': userId,
      'customer': {
        'userName': userName,
        'userPhone': userPhoneNumber,
        'userPhoto': userImageUrl,
        'userRating': loginModel?.data?.userRating ?? "",
      },
      'parcelData': {
        'name': name,
        'weight': weight,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'pickupInstructions': pickupInstructions,
      },
      'travelCharges': travelCharges,
      'status': 'pending',
      "playerId": "${oneSignalPlayerId??""}",
      'travelDistance': routeDistance,
      "travelTime": totalTime.toString(),
      "requestTime": DateTime.now()
    };
    box.put("rideId", rideId);
    box.put('ride_data', {
      'rideId': rideId,
      'itemId': "",
      'selectedDriverId': "",
      'acceptedDriverLat': 0.0,
      'acceptedDriverLng': 0.0,
      'driverName': "",
      'driverImage': "",
      'driverNumber': "",
      'vehicleNumber': "",
      'rating': "",
      'parcelData': {
        'name': name,
        'weight': weight,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'pickupInstructions': pickupInstructions,
      },
      'pickAddress': pickupAddress,
      'dropAddress': dropoffAddress,
      'pickLat': pickupLat,
      'dropLat': dropoffLat,
      'pickLng': pickupLng,
      'dropLng': dropoffLng,
      'playerId': '${oneSignalPlayerId??""}',
      "itemTypeId": ""
    });

    await box.put('activeRide', rideRequestData);
    await box.put('activeRide', rideRequestData);
    await box.put('activeRide', rideRequestData);
    final driverIds = <String>[];

    for (var driver in nearbyDrivers) {
      final fireStoreToken = driver['id']?.toString() ?? '';

      if (fireStoreToken.isEmpty) {
        debugPrint(
            '[RideDispatchDebug] skipped driver due to empty firestore id | driver=$driver');
        continue;
      }

      final driverData = {
        "rideStatus": "assigned",
        'ride_request': rideRequestData,
      };

      try {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(fireStoreToken)
            .set(driverData, SetOptions(merge: true));
        driverIds.add(fireStoreToken);
      } catch (e) {
        debugPrint(
            '[RideDispatchDebug] failed to write ride_request | driverDoc=$fireStoreToken | error=$e');
      }
    }
    debugPrint(
        '[RideDispatchDebug] ride request dispatched | rideId=$rideId | nearby=${nearbyDrivers.length} | written=${driverIds.length}');
    if (driverIds.isEmpty) {
      emit(state.copyWith(
        rideId: rideId,
        isSubmitting: false,
        progressIndicator: false,
        rideMessage:
            "No nearby drivers available right now. Please try again in a moment.",
      ));
      return;
    }
    box.put("driverIds", driverIds);
    box.put("nearbyDrivers", nearbyDrivers);
    // ignore_for_file: use_build_context_synchronously

    listenForDriverResponses(
      currentRequestId: currentRequestId,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      pickupLat: pickupLat,
      dropoffLat: dropoffLat,
      pickupLng: pickupLng,
      dropoffLng: dropoffLng,
      durationForSearch: durationForSearch,
      driverIds: driverIds,
      rideId: rideId,
      context: context,
      rideRequestData: rideRequestData,
      nearbyDrivers: nearbyDrivers,
    );
  }

  Future<void> listenForDriverResponses({
    required String currentRequestId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required int durationForSearch,
    required List<String> driverIds,
    required String rideId,
    required BuildContext context,
    required Map<String, dynamic> rideRequestData,
    required List<Map<String, dynamic>> nearbyDrivers,
  }) async {
    bool hasAccepted = false;
    final List<StreamSubscription> driverListeners = [];

    emit(state.copyWith(
      rideId: rideId,
      isSubmitting: false,
      progressIndicator: true,
    ));

    Future.delayed(Duration(seconds: durationForSearch), () async {
      if (!hasAccepted &&
          activeRideRequestId == currentRequestId &&
          !isManuallyCancelled) {
        for (final driverId in driverIds) {
          try {
            await FirebaseFirestore.instance
                .collection('drivers')
                .doc(driverId)
                .update({
              'ride_request': {},
              'rideStatus': 'available',
            });
          } catch (_) {}
        }

        for (final sub in driverListeners) {
          await sub.cancel();
        }

        emit(state.copyWith(
          progressIndicator: false,
        ));
      }
    });

    for (final driverFireStoreId in driverIds) {
      final subscription = FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverFireStoreId)
          .snapshots()
          .listen((snapshot) async {
        if (!snapshot.exists || snapshot.data() == null || hasAccepted) return;

        final data = snapshot.data()!;
        final rideRequestRaw = data['ride_request'];
        final Map<String, dynamic>? rideRequest =
            rideRequestRaw is Map<String, dynamic>
                ? rideRequestRaw
                : (rideRequestRaw is Map
                    ? Map<String, dynamic>.from(rideRequestRaw)
                    : null);

        if (rideRequest == null) return;

        final remoteRideId = rideRequest['rideId']?.toString() ?? '';
        final remoteStatus =
            (rideRequest['status'] ?? '').toString().trim().toLowerCase();

        if (remoteRideId == rideId && remoteStatus == 'accepted') {
          debugPrint(
              '[RideDispatchDebug] accepted detected | rideId=$rideId | driverDoc=$driverFireStoreId');
          hasAccepted = true;

          for (final sub in driverListeners) {
            await sub.cancel();
          }

          try {
            await FirebaseFirestore.instance
                .collection('drivers')
                .doc(driverFireStoreId)
                .update({'rideStatus': 'busy'});
          } catch (_) {}

          final customer =
              rideRequestData['customer'] as Map<dynamic, dynamic>? ?? {};

          try {
            await _createAcceptedRideRequestInRealTime(
              pickupLat: pickupLat,
              pickupLng: pickupLng,
              dropoffLat: dropoffLat,
              dropoffLng: dropoffLng,
              fireStoreToken: driverFireStoreId,
              driverIds: driverIds,
              context: context,
              driverId: (data['driverId'] ??
                      data['api_user_id'] ??
                      data['userId'] ??
                      '')
                  .toString(),
              rideId: rideId,
              nearbyDrivers: nearbyDrivers,
              userId: rideRequestData['userId'] ?? '',
              userName: customer['userName'] ?? '',
              pickupAddress: pickupAddress,
              dropoffAddress: dropoffAddress,
              userPhoneNumber: customer['userPhone'] ?? '',
              userImageUrl: customer['userPhoto'] ?? '',
              travelCharges: rideRequestData['travelCharges'] ?? '',
              routeStatus: 'accepted',
              routeDistance: rideRequestData['travelDistance'] ?? '',
            );
          } catch (e) {
            hasAccepted = false;
            debugPrint(
                '[RideDispatchDebug] failed after accept detection | rideId=$rideId | driverDoc=$driverFireStoreId | error=$e');
            return;
          }

          for (final otherDriverId in driverIds) {
            if (otherDriverId != driverFireStoreId) {
              try {
                await FirebaseFirestore.instance
                    .collection('drivers')
                    .doc(otherDriverId)
                    .update({
                  'ride_request': {},
                  'rideStatus': 'available',
                });
              } catch (_) {}
            }
          }

          emit(state.copyWith(progressIndicator: false));
        }
      }, onError: (e) {
        debugPrint(
            '[RideDispatchDebug] driver listener error | driverDoc=$driverFireStoreId | error=$e');
      });

      driverListeners.add(subscription);
    }
  }

  Future<void> _createAcceptedRideRequestInRealTime({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required BuildContext context,
    required String driverId,
    required List<String> driverIds,
    required String fireStoreToken,
    required String rideId,
    required List<Map<String, dynamic>> nearbyDrivers,
    required dynamic userId,
    required dynamic userName,
    required dynamic pickupAddress,
    required dynamic userPhoneNumber,
    String? userImageUrl,
    required dynamic dropoffAddress,
    required dynamic travelCharges,
    required dynamic routeStatus,
    required dynamic routeDistance,
  }) async {
    final rideRequestRef =
        FirebaseDatabase.instance.ref().child("ride_requests");

    dynamic driverName = '';
    dynamic driverPhone = '';
    dynamic driverPhoto = '';
    dynamic driverRating = '';
    dynamic itemId = '';
    dynamic vehicleNumber = '';
    dynamic itemTypeName = '';
    dynamic vehicleMake = '';
    dynamic vehicleModel = '';
    double driverLat = 0.0;
    double driverLng = 0.0;
    String itemTypeId = "";

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(fireStoreToken)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          if (driverId.trim().isEmpty) {
            driverId = (data['driverId'] ?? data['api_user_id'] ?? data['userId'] ?? '')
                .toString();
          }
          driverName = data['driverName'] ?? '';
          driverPhone = "${data['driverNumber']} ";
          driverPhoto = data['driverImageUrl'] ?? '';
          driverRating = data['driverRating']?.toString() ?? '';
          itemId = data['itemId'] ?? '';

          vehicleNumber = data['vehicleNumber'] ?? '';
          itemTypeName = data['itemTypeName'] ?? '';

          vehicleMake = data['vehicleMake'].toString();
          vehicleModel = data['vehicleModel'].toString();
          itemTypeId = data["itemTypeId"] ?? "";

          final geo = data['geo'] as Map<String, dynamic>?;
          final GeoPoint? geoPoint = geo?['geopoint'];

          if (geoPoint != null) {
            driverLat = geoPoint.latitude;
            driverLng = geoPoint.longitude;
          }
        } else {
          throw Exception('Driver data is null');
        }
      } else {
        throw Exception('Driver document not found');
      }

      final rideData = {
        'selectedDriverId': driverId,
        'status': routeStatus,
        'userId': userId,
        'driverLocation': {'lat': driverLat, 'lng': driverLng},
        'driver': {
          'driverName': driverName,
          'driverPhone': '$driverPhone',
          'driverPhoto': driverPhoto,
          'driverRating': driverRating,
        },
        'vehicleDetails': {
          'itemId': itemId,
          'itemTypeName': itemTypeName,
          'vehicleNumber': vehicleNumber,
          'vehicleMake': vehicleMake,
          'vehicleModel': vehicleModel,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      await rideRequestRef.child(rideId).update(rideData);

      emit(state.copyWith(
        pickupAddress: "$pickupAddress",
        dropOffAddress: "$dropoffAddress",
        isSubmitting: true,
        progressIndicator: false,
        driverRating: "$driverRating",
        vehicleMake: vehicleMake.toString(),
        vehicleModel: vehicleModel.toString(),
        accepteDriverPhoneNumber: driverPhone ?? "",
        acceptedDriverImageUrl: driverPhoto,
        acceptedDriverName: driverName ?? "",
        acceptedDriverVechileName: '$vehicleMake $vehicleModel',
        acceptedDriverVechileNumber: "$vehicleNumber",
        itemId: itemId.toString(),
        rideId: rideId,
        selectedDriverId: driverId,
        acceptedDriverLat: driverLat,
        acceptedDriverLng: driverLng,
      ));

      box.put('ride_data', {
        'rideId': rideId,
        'itemId': itemId,
        'selectedDriverId': driverId,
        'acceptedDriverLat': driverLat,
        'acceptedDriverLng': driverLng,
        'driverName': driverName,
        'driverImage': driverPhoto,
        'driverNumber': driverPhone,
        'vehicleNumber': vehicleNumber,
        'rating': driverRating,
        'pickAddress': pickupAddress,
        'dropAddress': dropoffAddress,
        'pickLat': pickupLat,
        'dropLat': dropoffLat,
        'pickLng': pickupLng,
        'dropLng': dropoffLng,
        "itemTypeId": itemTypeId
      });
    } catch (e) {
      emit(state.copyWith(
        rideId: rideId,
        isSubmitting: false,
        progressIndicator: false,
        rideMessage:
            "No driver accepted the ride request. Please try again with another vehicle.",
      ));
    }
  }

  Future<void> createRealTimeInstance({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String routeStatus,
    required String userId,
    required String userName,
    required String userPhoneNumber,
    required String travelCharges,
    required String routeDistance,
    required String totalTime,
    required String rideId,
    String? userImageUrl,
  }) async {
    try {
      final rideRequestRef =
          FirebaseDatabase.instance.ref().child("ride_requests");
      final Map<String, dynamic>? parcelData =
          box.get('current_parcel_data') as Map<String, dynamic>?;
      String name = "";
      String weight = "";
      String receiverName = "";
      String receiverPhone = "";
      String pickupInstructions = "";
      if (parcelData != null) {
        name = parcelData['name'] ?? '';
        weight = parcelData['weight'] ?? '';
        receiverName = parcelData['receiverName'] ?? '';
        receiverPhone = parcelData['receiverPhone'] ?? '';
        pickupInstructions = parcelData['pickupInstructions'] ?? '';
      }
      final rideData = {
        "OTP": '',
        'adminCommission': '',
        'rideId': rideId,
        'bookingId': '',
        'selectedDriverId': "",
        'rideStatusLabel': '',
        'pickupLocation': {
          'lat': pickupLat,
          'lng': pickupLng,
          'pickupAddress': pickupAddress,
        },
        'dropoffLocation': {
          'lat': dropoffLat,
          'lng': dropoffLng,
          'dropoffAddress': dropoffAddress,
        },
        'status': routeStatus,
        'userId': userId,
        'customer': {
          'userName': userName,
          'userPhone': userPhoneNumber,
          'userPhoto': userImageUrl ?? "defaultImageUrl",
          'userRating': loginModel?.data?.userRating ?? "",
          'userPhoneCountry': loginModel?.data?.phoneCountry ?? "",
        },
        'driverLocation': {'lat': "", 'lng': ""},
        'driver': {
          'driverName': "",
          'driverPhone': '',
          'driverPhoto': '',
          'driverRating': '',
        },
        'driverPayment': '',
        'totalDistance': routeDistance,
        'distanceRemain': '',
        'totalTime': totalTime,
        'timeRemain': '',
        'tax': '',
        'paymentStatus': '',
        'paymentMethod': 'cash',
        'travelCharges': travelCharges,
        'vehicleDetails': {
          'itemId': '',
          'itemTypeName': '',
          'vehicleNumber': '',
          'vehicleMake': '',
          'vehicleModel': '',
        },
        'parcelData': {
          'name': name,
          'weight': weight,
          'receiverName': receiverName,
          'receiverPhone': receiverPhone,
          'pickupInstructions': pickupInstructions,
        },
        "customerFeeback": {"rating": "", "review": ""},
        "driverFeeback": {"rating": "", "review": ""},
        "driverConfirmedPayment": "",
        "riderConfirmedPayment": "",
        "playerId": oneSignalPlayerId ?? "",
        'timestamp': DateTime.now().toIso8601String(),
      };

      await rideRequestRef.child(rideId).set(rideData);
    } catch (e) {
      //
    }
  }

  void loadRideFromHive() {
    final rideData = box.get('ride_data');

    if (rideData != null) {
      emit(state.copyWith(
        rideId: rideData['rideId'],
        itemId: rideData['itemId'].toString(),
        selectedDriverId: rideData['selectedDriverId'],
        acceptedDriverLat: rideData['acceptedDriverLat'],
        acceptedDriverLng: rideData['acceptedDriverLng'],
        acceptedDriverName: rideData['driverName'],
        acceptedDriverImageUrl: rideData['driverImage'],
        accepteDriverPhoneNumber: rideData['driverNumber'],
        pickupLat: rideData['pickupLat'],
        pickupLng: rideData['pickupLng'],
        dropoffLat: rideData['dropoffLat'],
        dropoffLng: rideData['dropoffLng'],
        acceptedDriverVechileNumber: rideData['vehicleNumber'],
        driverRating: rideData['rating'],
        pickupAddress: rideData['pickAddress'],
        dropOffAddress: rideData['dropAddress'],
      ));
    }
  }

  void resetState() {
    emit(RideRequestInitial());
    emit(const RideRequestState(
      farePrice: "",
      nearbyDrivers: [],
      distanceInKm: "",
      acceptedDriverImageUrl: "",
      acceptedDriverName: "",
      acceptedDriverVechileName: "",
      acceptedDriverVechileNumber: "",
      acceptedDriverLat: 0.0,
      acceptedDriverLng: 0.0,
      rideId: "",
      isSubmitting: false,
      progressIndicator: false,
      rideMessage: "",
      selectedDriverId: "",
    ));
  }
}


