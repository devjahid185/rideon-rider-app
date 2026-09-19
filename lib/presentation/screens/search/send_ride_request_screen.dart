import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:ride_on/core/services/data_store.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:ride_on/core/utils/translate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/config.dart';
import '../../../core/services/ride_audio_recorder_service.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/book_ride_cubit.dart';
import '../../cubits/general_cubit.dart';
import '../../cubits/location/get_nearby_drivers_cubit.dart';
import '../../cubits/location/set_marker_cubit.dart';
import '../../cubits/realtime/get_ride_request_status_cubit.dart';
import '../../cubits/realtime/ride_request_cubit.dart';
import '../../cubits/vehicle_data/get_vehicle_cetgegory_cubit.dart';
import '../../widgets/sos_widget.dart';
import '../Home/item_home_screen.dart';
import '../payment/rider_payment_screen.dart';

class SendRideRequestScreen extends StatefulWidget {
  final Map<String, dynamic> selectedVehicleData;

  final String statusOfRide;
  final String? pickUpOtp, dropotp, rideId, bookingId, paymentUrl;

  const SendRideRequestScreen({
    super.key,
    required this.selectedVehicleData,
    required this.statusOfRide,
    this.rideId,
    this.pickUpOtp,
    this.dropotp,
    this.bookingId,
    this.paymentUrl,
  });

  @override
  State<SendRideRequestScreen> createState() => _SendRideRequestScreenState();
}

class _SendRideRequestScreenState extends State<SendRideRequestScreen> {
  double dropLat = 0.0;
  double dropLng = 0.0;
  double pickLat = 0.0;
  double pickLng = 0.0;
  double driverLat = 0.0;
  double driverLng = 0.0;
  String fetchDistance = "";
  String fetchDuration = "";
  String otp = "";
  String dropotp = "";
  String rideId = "";
  String bookingId = "";
  String rideStatus = "";
  String paymentUrl = '';

  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  bool isSuccessFirst = false;
  bool isCurrentScreenActive = true;
  List<LatLng> polylineCoordinates = [];
  int currentPolylineIndex = 0;
  Timer? locationUpdateTimer;
  Timer? fetchTimer;

  @override
  void initState() {
    super.initState();

    ScreenTracker.setCurrentScreen("RideTrackingScreen");
    isManuallyCancelled = false;
    isCurrentScreenActive = true;

    context.read<UserMarkerCubit>().clear();
    context.read<GetPolylineCubit>().resetPolylines();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRideByStatus();
    });
  }

  void _handleRideByStatus() {
    final status = widget.statusOfRide;

    if (status.isEmpty) {
      _handleFreshRide();
    } else if (status == "pending") {
      _resumePendingRide();
    } else if (status == "accepted" || status == "pick_up") {
      _handleAcceptedRide();
    } else if (status == "ongoing") {
      _handleOngoingRide();
    }
  }

  void _handleFreshRide() {
    getNearByDrivers();
    box.put('selected_vehicle', jsonEncode(widget.selectedVehicleData));
  }

  void _resumePendingRide() {
    final rawRideRequestData = box.get("activeRide");
    final rawRideData = box.get("ride_data");
    final rawDriverIds = box.get("driverIds");
    final rawNearbyDrivers = box.get("nearbyDrivers");
    context.read<VehicleDataUpdateCubit>().updateVehicleTypeSelectedId(
      widget.selectedVehicleData["id"],
    );

    final Map<String, dynamic>? rideRequestData = rawRideRequestData is Map
        ? Map<String, dynamic>.from(rawRideRequestData)
        : null;

    final Map<String, dynamic>? rideData = rawRideData is Map
        ? Map<String, dynamic>.from(rawRideData)
        : null;

    final List<String> driverIds = rawDriverIds is List
        ? rawDriverIds.whereType<String>().toList()
        : [];

    final List<Map<String, dynamic>> nearbyDrivers = rawNearbyDrivers is List
        ? rawNearbyDrivers
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : [];

    if (rideRequestData == null || rideData == null || driverIds.isEmpty) {
      return;
    }
    context.read<RideRequestCubit>().listenForDriverResponses(
      currentRequestId: widget.rideId ?? "",
      pickupAddress: rideData["pickAddress"] ?? "",
      dropoffAddress: rideData["dropAddress"] ?? "",
      pickupLat: (rideData["pickLat"] ?? 0).toDouble(),
      dropoffLat: (rideData["dropLat"] ?? 0).toDouble(),
      pickupLng: (rideData["pickLng"] ?? 0).toDouble(),
      dropoffLng: (rideData["dropLng"] ?? 0).toDouble(),
      durationForSearch:
          int.tryParse(
            context.read<DriverSearchIntervalCubit>().state.value ?? "60",
          ) ??
          60,
      driverIds: driverIds,
      rideId: widget.rideId ?? "",
      context: context,
      rideRequestData: rideRequestData,
      nearbyDrivers: nearbyDrivers,
    );
  }

  void _handleAcceptedRide() {
    setAllLatLang();
    _handleBookRideSuccess(
      context,
      widget.pickUpOtp.toString(),
      widget.dropotp.toString(),
      widget.rideId.toString(),
      widget.bookingId.toString(),
    );
    paymentUrl = widget.paymentUrl ?? "";
    rideStatus = widget.statusOfRide;
  }

  void _handleOngoingRide() {
    setAllLatLang();
    otp = widget.pickUpOtp.toString();
    dropotp = widget.dropotp.toString();
    rideId = widget.rideId.toString();
    bookingId = widget.bookingId.toString();
    rideStatus = widget.statusOfRide;
    paymentUrl = widget.paymentUrl ?? "";
    context.read<GetRideRequestStatusCubit>().listenToRouteStatus(
      rideId: rideId,
    );
    RideAudioRecorderService.instance.start(
      bookingId: bookingId,
      context: context,
    );
    _handleLiveRideSuccess(context);
  }

  Future<void> getNearByDrivers() async {
    final stateData = context.read<BookRideRealTimeDataBaseCubit>().state;
    await context.read<DriverNearByCubit>().getNearbyDrivers(
      checkRestart: false,
      pickupLat: double.parse(stateData.pickupAddressLatitude),
      pickupLng: double.parse(stateData.pickupAddressLongitude),
      vehicleTypeId: widget.selectedVehicleData["id"].toString(),
      distance: double.parse(
        context.read<LocationAccuracyThresholdCubit>().state.value ?? "3",
      ),
    );
  }

  bool isInilize = false;
  Future<void> _initializeRideRequest({
    required List<Map<String, dynamic>> nearbyDrivers,
    required bool checkRestart,
  }) async {
    final stateData = context.read<BookRideRealTimeDataBaseCubit>().state;
    final rideRequestData = context.read<RideRequestCubit>().state;
    if (checkRestart == true) {
      rideId = rideRequestData.rideId;
    } else {
      if (isInilize) return;
      isInilize = true;
      rideId = FirebaseFirestore.instance.collection('temp').doc().id;
    }
    try {
      await context.read<RideRequestCubit>().createDriverData(
        rideId: rideId,
        checkRestart: checkRestart,
        durationForSearch: int.parse(
          context.read<DriverSearchIntervalCubit>().state.value ?? "60",
        ),
        routeDistance: widget.selectedVehicleData["distance"].toString(),
        context: context,
        nearbyDrivers: nearbyDrivers,
        userId: stateData.userId.toString(),
        userName: stateData.userName,
        pickupLat: double.parse(stateData.pickupAddressLatitude),
        pickupLng: double.parse(stateData.pickupAddressLongitude),
        pickupAddress: stateData.pickupAddress,
        dropoffLat: double.parse(stateData.dropoffAddressLatitude),
        dropoffLng: double.parse(stateData.dropoffAddressLongitude),
        userPhoneNumber: loginModel!.data!.phone!,
        dropoffAddress: stateData.dropoffAddress,
        travelCharges: widget.selectedVehicleData["fare"].toString(),
        routeStatus: "pending",
        userImageUrl: myImage,
        totalTime: widget.selectedVehicleData["duration"].toString(),
      );
      setState(() {
        pickLat = double.parse(stateData.pickupAddressLatitude);
        pickLng = double.parse(stateData.pickupAddressLongitude);
        dropLat = double.parse(stateData.dropoffAddressLatitude);
        dropLng = double.parse(stateData.dropoffAddressLongitude);
        driverLat = stateData.acceptedDriverLat;
        driverLng = stateData.acceptedDriverLng;
      });
    } catch (e) {
      debugPrint("Error initializing ride request: $e");
      showErrorToastMessage("Failed to send ride request.");
    }
  }

  void setAllLatLang() {
    final stateData = context.read<BookRideRealTimeDataBaseCubit>().state;
    setState(() {
      pickLat = double.parse(stateData.pickupAddressLatitude);
      pickLng = double.parse(stateData.pickupAddressLongitude);
      dropLat = double.parse(stateData.dropoffAddressLatitude);
      dropLng = double.parse(stateData.dropoffAddressLongitude);
      driverLat = context.read<RideRequestCubit>().state.acceptedDriverLat;
      driverLng = context.read<RideRequestCubit>().state.acceptedDriverLng;
    });
  }

  Future<void> _updateRide({
    required String updatedRideId,
    required String upDatedBookingId,
  }) async {
    if (updatedRideId.isEmpty || upDatedBookingId.isEmpty) {
      debugPrint("Invalid rideId or bookingId");
      return;
    }

    final rideRequestRef = FirebaseDatabase.instance.ref().child(
      "ride_requests",
    );
    try {
      await rideRequestRef.child(updatedRideId).update({
        'bookingId': upDatedBookingId,
        'status': 'accepted',
      });
      debugPrint("Ride updated successfully.");
    } catch (error) {
      debugPrint("Failed to update ride: $error");
      // showErrorToastMessage("Failed to update ride.");
    }
  }

  Future<void> _fetchDistanceAndTime({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required bool beforePickUp,
  }) async {
    if (fromLat == 0.0 || fromLng == 0.0 || toLat == 0.0 || toLng == 0.0) {
      debugPrint("Invalid coordinates for distance/time fetch");
      return;
    }

    bool useGoogleApi = false;

    if (beforePickUp &&
        context.read<UseGoogleBeforePickupCubit>().state.value.toString() ==
            "1") {
      useGoogleApi = true;
    } else if (!beforePickUp &&
        context.read<UseGoogleAfterPickupCubit>().state.value.toString() ==
            "1") {
      useGoogleApi = true;
    }

    if (useGoogleApi) {
      debugPrint(
        'ðŸ“ Fetching using Google Distance Matrix API (with traffic)',
      );

      final url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?'
          'origins=$fromLat,$fromLng'
          '&destinations=$toLat,$toLng'
          '&departure_time=now'
          '&traffic_model=best_guess'
          '&mode=driving'
          '&key=${Config.googleKey}';

      try {
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['rows']?.isNotEmpty == true &&
              data['rows'][0]['elements'][0]['status'] == 'OK') {
            final element = data['rows'][0]['elements'][0];
            final distanceText = element['distance']?['text'] ?? '';
            final durationText =
                element['duration_in_traffic']?['text'] ??
                element['duration']?['text'] ??
                '';
            setState(() {
              fetchDistance = distanceText;
              fetchDuration = durationText;
            });
            debugPrint(
              'âœ… Distance: $distanceText | Duration (with traffic): $durationText',
            );
          } else {
            debugPrint(
              'âš ï¸ Error: ${data['rows'][0]['elements'][0]['status']}',
            );
          }
        } else {
          debugPrint('âŒ Failed: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('âŒ Exception fetching distance/time: $e');
      }
    } else {
      debugPrint('ðŸ“ Using Geolocator (approximation)');

      final meters = Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
      final pretty = _formatDistanceAndEta(meters, avgSpeedKmph: 40);

      setState(() {
        fetchDistance = pretty['distanceText'] ?? "";
        fetchDuration = pretty['durationText'] ?? "";
      });
    }
  }

  Map<String, String> _formatDistanceAndEta(
    double meters, {
    double avgSpeedKmph = 40,
  }) {
    final km = meters / 1000.0;

    final hours = km / avgSpeedKmph;
    final mins = (hours * 60).round().clamp(1, 999);

    final distanceText = km >= 1
        ? '${km.toStringAsFixed(km < 10 ? 1 : 0)} km'
        : '${meters.toStringAsFixed(0)} m';
    final durationText = mins >= 60
        ? '${(mins ~/ 60)} hr ${mins % 60} min'
        : '$mins min';

    return {'distanceText': distanceText, 'durationText': durationText};
  }

  Timer? _distanceTimer;
  double updatedDriverLat = 0.0;
  double updatedDriverLng = 0.0;

  void startAutoDistanceTimer() {
    _distanceTimer?.cancel();
    _distanceTimer = Timer.periodic(
      Duration(
        seconds: int.parse(
          context.read<MinimumHitsTimeToUpdateTime>().state.value ?? "60",
        ),
      ),
      (timer) {
        if (rideStatus == "ongoing") {
          stopAutoDistanceTimer();
          return;
        }
        _fetchDistanceAndTime(
          fromLat: double.parse(
            context
                .read<BookRideRealTimeDataBaseCubit>()
                .state
                .pickupAddressLatitude,
          ),
          fromLng: double.parse(
            context
                .read<BookRideRealTimeDataBaseCubit>()
                .state
                .pickupAddressLongitude,
          ),
          toLat: updatedDriverLat,
          toLng: updatedDriverLng,
          beforePickUp: true,
        );

        setState(() {});
      },
    );
  }

  void startAutoDistanceTimerForDropOff() {
    _distanceTimer?.cancel();
    _distanceTimer = Timer.periodic(
      Duration(
        seconds: int.parse(
          context.read<MinimumHitsTimeToUpdateTime>().state.value ?? "60",
        ),
      ),
      (timer) {
        if (rideStatus == "complete") {
          stopAutoDistanceTimer();
          return;
        }
        _fetchDistanceAndTime(
          fromLat: updatedDriverLat,
          fromLng: updatedDriverLng,
          toLat: double.parse(
            context
                .read<BookRideRealTimeDataBaseCubit>()
                .state
                .dropoffAddressLatitude,
          ),
          toLng: double.parse(
            context
                .read<BookRideRealTimeDataBaseCubit>()
                .state
                .dropoffAddressLongitude,
          ),
          beforePickUp: false,
        );

        setState(() {});
      },
    );
  }

  void stopAutoDistanceTimer() {
    _distanceTimer?.cancel();
  }

  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  void _addUserMarker() {
    if (pickLat != 0.0 && pickLng != 0.0) {
      context.read<UserMarkerCubit>().addOrUpdateMarker(
        LatLng(pickLat, pickLng),
        'User Location',
        'User_marker',
        'assets/images/pickupmarker.png',
        50,
      );
    } else {
      debugPrint('Invalid pickup coordinates');
    }
  }

  void _addDropMarker() {
    if (dropLat != 0.0 && dropLng != 0.0) {
      context.read<UserMarkerCubit>().addOrUpdateMarker(
        LatLng(dropLat, dropLng),
        'Drop Location',
        'drop_marker',
        "assets/images/dropmarker.png",
        50,
      );
    } else {
      debugPrint('Invalid pickup coordinates');
    }
  }

  void _addDriverMarker() {
    final rideRequestState = context.read<RideRequestCubit>().state;
    final lat = rideRequestState.acceptedDriverLat;
    final lng = rideRequestState.acceptedDriverLng;

    context.read<UserMarkerCubit>().addOrUpdateMarker(
      LatLng(lat, lng),
      'Driver Location',
      'driver_marker',
      context.read<RideRequestCubit>().state.acceptedDriverImageUrl,
      120,
    );
  }

  void _fetchPolylines() {
    final rideRequestState = context.read<RideRequestCubit>().state;
    final sourceLat = rideRequestState.acceptedDriverLat;
    final sourceLng = rideRequestState.acceptedDriverLng;

    if (pickLat != 0.0 && pickLng != 0.0) {
      context.read<GetPolylineCubit>().getPolyline(
        sourcelat: sourceLat,
        sourcelng: sourceLng,
        destinationlat: pickLat,
        destinationlng: pickLng,
        isPickupRoute: true,
      );
    } else {
      debugPrint('Invalid coordinates for polyline');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: notifires.getbgcolor,
        body: Stack(
          children: [
            _buildMapSection(),
            MultiBlocListener(
              listeners: [
                BlocListener<GetRideRequestStatusCubit, String>(
                  listener: (context, status) async {
                    if (status == "rejected") {
                      box.delete("rideId");
                      showDriverCancelledRideDialog(context);
                      return;
                    }
                    setState(() => rideStatus = status);

                    if (rideStatus.toString() == "ongoing") {
                      await RideAudioRecorderService.instance.start(
                        bookingId: bookingId,
                        context: context,
                      );
                      if (!mounted || !context.mounted) return;
                      _handleLiveRideSuccess(context);
                    } else if (status == "completed") {
                      await RideAudioRecorderService.instance.stopAndUpload(
                        bookingId: bookingId,
                        context: context,
                      );
                      if (!mounted || !context.mounted) return;
                      stopAutoDistanceTimer();
                      fetchTimer?.cancel();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiderPaymentScreen(
                            bookingId: bookingId,
                            rideId: rideId,
                            fare: widget.selectedVehicleData["fare"] ?? 00,
                            paymentUrl: paymentUrl,
                          ),
                        ),
                      );
                    }
                  },
                ),
                BlocListener<DriverNearByCubit, DriverNearByState>(
                  listener: (context, state) {
                    if (state is DriverUpdated) {
                      if (state.nearbyDrivers!.isEmpty) {
                        context
                            .read<DriverNearByCubit>()
                            .resetNearByDriverState();
                        return;
                      }

                      context.read<RideRequestCubit>().updateNearByDrivers(
                        nearbyDrivers: state.nearbyDrivers,
                      );
                      _initializeRideRequest(
                        nearbyDrivers: state.nearbyDrivers!,
                        checkRestart: state.checkRestart!,
                      );

                      context
                          .read<DriverNearByCubit>()
                          .resetNearByDriverState();
                    }

                    if (state is DriverError) {}
                  },
                ),
              ],
              child: BlocBuilder<RideRequestCubit, RideRequestState>(
                builder: (context, rideRequestState) {
                  if (rideRequestState.isSubmitting &&
                      // ignore: unrelated_type_equality_checks
                      rideRequestState.selectedDriverId != 0) {
                    _handleRideBooking(context, rideRequestState);
                  }
                  if (rideRequestState.rideMessage.isNotEmpty) {
                    showErrorToastMessage(rideRequestState.rideMessage);
                    context.read<RideRequestCubit>().removeRideMessage();
                  }

                  return BlocBuilder<BookRideUserCubit, BookRideUserState>(
                    builder: (context, bookRideState) {
                      if (bookRideState is BookRideUserSuccess &&
                          bookRideState.pikupOtp != null) {
                        context
                            .read<GetRideRequestStatusCubit>()
                            .listenToRouteStatus(
                              rideId: bookRideState.rideId.toString(),
                            );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          paymentUrl = bookRideState.paymentUrl ?? "";
                          box.put("payment_url", paymentUrl);
                          _handleBookRideSuccess(
                            context,
                            bookRideState.pikupOtp.toString(),
                            bookRideState.dropOtp.toString(),
                            bookRideState.rideId.toString(),
                            bookRideState.bookingId.toString(),
                          );
                        });
                        context.read<BookRideUserCubit>().removeBookRideState();
                      } else if (bookRideState is BookRideUserFailure) {
                        showErrorToastMessage(
                          bookRideState.error ?? "Failed to book ride.",
                        );
                        context.read<BookRideUserCubit>().removeBookRideState();
                        box.delete("ride_data");
                        cancelRideRequest(
                          rideId: context.read<RideRequestCubit>().state.rideId,
                        );
                      }

                      return _buildDraggableSheet(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> cancelRideRequest({required String rideId}) async {
    try {
      if (rideId.isEmpty) {
        throw Exception('Ride ID cannot be empty');
      }

      final DatabaseReference rideRequestsRef = FirebaseDatabase.instance
          .ref()
          .child('ride_requests');
      final rideRef = rideRequestsRef.child(rideId);

      await rideRef.update({'status': 'cancelled'});
      final driversRef = FirebaseFirestore.instance.collection('drivers');
      final driverQuery = driversRef.where(
        'ride_request.rideId',
        isEqualTo: rideId,
      );
      final driverSnapshots = await driverQuery.get();

      final matchingDriverCount = driverSnapshots.docs.length;
      for (var doc in driverSnapshots.docs) {
        final driverId = doc.id;
        try {
          await driversRef.doc(driverId).update({
            'ride_request': {}, // Clear ride_request
            'rideStatus': 'available',
          });

          // ignore: empty_catches
        } catch (e) {}
      }

      await rideRef.remove();

      if (matchingDriverCount == 0) {}
    } catch (e) {
      // throw Exception('Failed to cancel ride request: $e');
    }
  }

  bool isRideBooking = false;

  void _handleRideBooking(BuildContext context, RideRequestState state) {
    if (isRideBooking) return;
    isRideBooking = true;
    final stateData = context.read<BookRideRealTimeDataBaseCubit>().state;
    final selectedItemTypeId = widget.selectedVehicleData["id"];
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    context.read<BookRideUserCubit>().bookRide(
      context: context,
      itemId: state.itemId,
      serviceTypeId: widget.selectedVehicleData["serviceTypeId"].toString(),
      totalFare: widget.selectedVehicleData["fare"].toString(),
      rideId: state.rideId,
      date: formattedDate,
      itemTypeId: selectedItemTypeId,
      estimatedDistance: widget.selectedVehicleData["distance"].toString(),
      pickupAddress: stateData.pickupAddress,
      pickupLat: stateData.pickupAddressLatitude,
      pickupLng: stateData.pickupAddressLongitude,
      dropOffAddress: stateData.dropoffAddress,
      dropOffLat: stateData.dropoffAddressLatitude,
      dropOffLng: stateData.dropoffAddressLongitude,
      driverId: state.selectedDriverId.toString(),
      paymentMethod: "Cash",
    );
  }

  void _handleBookRideSuccess(
    BuildContext context,
    String pikupOtp,
    String dropOtp,
    String rideID,
    String bookingID,
  ) {
    context.read<GetRideRequestStatusCubit>().listenToRouteStatus(
      rideId: rideID.toString(),
    );
    _fetchDriverLocationFromRealtimeDB(rideID);

    if (isSuccessFirst) return;

    isSuccessFirst = true;
    fetchTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchDriverLocationFromRealtimeDB(rideID);
    });
    _updateRide(updatedRideId: rideID, upDatedBookingId: bookingID.toString());

    box.put("PickOtp", pikupOtp);
    box.put("DropOtp", dropOtp);
    box.put("bookingId", bookingID);

    if (widget.statusOfRide == "accepted" || widget.statusOfRide == "pick_up") {
      paymentUrl = box.get("payment_url") ?? "";
    }

    otp = pikupOtp;
    dropotp = dropOtp;
    bookingId = bookingID.toString();
    rideId = rideID.toString();
    _addUserMarker();
    _addDriverMarker();
    _fetchDistanceAndTime(
      fromLat: double.parse(
        context
            .read<BookRideRealTimeDataBaseCubit>()
            .state
            .pickupAddressLatitude,
      ),
      fromLng: double.parse(
        context
            .read<BookRideRealTimeDataBaseCubit>()
            .state
            .pickupAddressLongitude,
      ),
      toLat: context.read<RideRequestCubit>().state.acceptedDriverLat,
      toLng: context.read<RideRequestCubit>().state.acceptedDriverLng,
      beforePickUp: true,
    );
    startAutoDistanceTimer();
    _fetchPolylines();
    getUnreadCount(rideId, loginModel?.data?.id.toString() ?? "");
    setState(() {});
    context.read<BookRideUserCubit>().removeBookRideState();
  }

  bool isLiveRide = false;

  void _handleLiveRideSuccess(BuildContext context) {
    _fetchDriverLocationFromRealtimeDB(rideId);

    if (isLiveRide) return;
    fetchTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchDriverLocationFromRealtimeDB(rideId);
    });
    isLiveRide = true;
    context.read<UserMarkerCubit>().removeMarker("User_marker");
    _addDropMarker();
    _addDriverMarker();
    _fetchDistanceAndTime(
      fromLat: context.read<RideRequestCubit>().state.acceptedDriverLat,
      fromLng: context.read<RideRequestCubit>().state.acceptedDriverLng,
      toLat: double.parse(
        context
            .read<BookRideRealTimeDataBaseCubit>()
            .state
            .dropoffAddressLatitude,
      ),
      toLng: double.parse(
        context
            .read<BookRideRealTimeDataBaseCubit>()
            .state
            .dropoffAddressLongitude,
      ),
      beforePickUp: false,
    );
    context.read<GetPolylineCubit>().resetPolylines();

    context.read<GetPolylineCubit>().getPolyline(
      sourcelat: context.read<RideRequestCubit>().state.acceptedDriverLat,
      sourcelng: context.read<RideRequestCubit>().state.acceptedDriverLng,
      isPickupRoute: false,
      destinationlat: double.parse(
        context
            .read<BookRideRealTimeDataBaseCubit>()
            .state
            .dropoffAddressLatitude,
      ),
      destinationlng: double.parse(
        context
            .read<BookRideRealTimeDataBaseCubit>()
            .state
            .dropoffAddressLongitude,
      ),
    );
    startAutoDistanceTimerForDropOff();
  }

  GoogleMapController? mapController;
  Completer<GoogleMapController> completeController = Completer();
  void zoomIn() {
    mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void zoomOut() {
    mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  Stream<int> getUnreadCount(String rideId, String myId) {
    return FirebaseDatabase.instance
        .ref("ride_requests/$rideId/chat/messages")
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return 0;

          Map data = event.snapshot.value as Map;
          int count = 0;

          data.forEach((key, value) {
            if (value["senderId"] != myId && value["seen"] != true) {
              count++;
            }
          });

          return count;
        });
  }

  void _fetchDriverLocationFromRealtimeDB(String rideId) async {
    try {
      if (rideId.isEmpty) {
        return;
      }

      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('ride_requests')
          .child(rideId)
          .child('driverLocation')
          .once();

      final locationData = snapshot.snapshot.value as Map?;

      if (locationData == null) return;

      final newLat = locationData['lat']?.toDouble();
      final newLng = locationData['lng']?.toDouble();
      updatedDriverLat = newLat;
      updatedDriverLng = newLng;
      if (newLat == null || newLng == null) return;

      if (newLat == driverLat && newLng == driverLng) return;

      final nextPosition = LatLng(newLat, newLng);
      final currentPosition = LatLng(driverLat, driverLng);

      _animateMarkerToNextPosition(currentPosition, nextPosition);
      // ignore: empty_catches
    } catch (e) {}
  }

  void _updateDriverMarkerPosition(double lat, double lng) {
    context.read<UserMarkerCubit>().addOrUpdateMarker(
      LatLng(lat, lng),
      'Driver Location',
      'driver_marker',
      context.read<RideRequestCubit>().state.acceptedDriverImageUrl,
      120,
    );
  }

  @override
  void dispose() {
    fetchTimer?.cancel();
    locationUpdateTimer?.cancel();
    locationUpdateTimer = null;
    fetchTimer = null;
    isCurrentScreenActive = true;
    super.dispose();
  }

  void _animateMarkerToNextPosition(LatLng current, LatLng next) {
    const int animationDurationMs = 1000;
    const int steps = 20;

    final double latStep = (next.latitude - current.latitude) / steps;
    final double lngStep = (next.longitude - current.longitude) / steps;

    int currentStep = 0;
    locationUpdateTimer?.cancel();

    locationUpdateTimer = Timer.periodic(
      const Duration(milliseconds: animationDurationMs ~/ steps),
      (timer) {
        if (currentStep >= steps) {
          timer.cancel();
          setState(() {
            driverLat = next.latitude;
            driverLng = next.longitude;
          });
          _updateDriverMarkerPosition(driverLat, driverLng);

          return;
        }

        final interpolatedLat = current.latitude + latStep * currentStep;
        final interpolatedLng = current.longitude + lngStep * currentStep;

        setState(() {
          driverLat = interpolatedLat;
          driverLng = interpolatedLng;
        });

        _updateDriverMarkerPosition(interpolatedLat, interpolatedLng);
        currentStep++;
      },
    );
  }

  Widget _buildMapSection() {
    final rideState = context.read<BookRideRealTimeDataBaseCubit>().state;

    final double latitude =
        double.tryParse(rideState.pickupAddressLatitude) ?? 28.6139;
    final double longitude =
        double.tryParse(rideState.pickupAddressLongitude) ?? 77.2090;
    return Positioned(
      bottom: 300,
      left: 0,
      right: 0,
      top: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PersistentGoogleMap(
            initialPosition: LatLng(latitude, longitude),
            markers: otp.isEmpty ? {} : markers,
            polylines: otp.isEmpty ? {} : polylines,
            myLocationEnabled: false,
            onMapCreated: (controller) {
              if (!completeController.isCompleted) {
                completeController.complete(controller);
                mapController = controller;
              }
            },
          ),
          if (otp.isEmpty) const PulsingCircle(),
        ],
      ),
    );
  }

  Widget _buildDraggableSheet(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              rideStatus == "ongoing"
                  ? const SosButtonWidget()
                  : const SizedBox(),
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDragHandle(),
                      if (rideStatus == "accepted")
                        _buildDriverInfoSection(context)
                      else if (otp.isEmpty)
                        _buildFindingDriverSection(context)
                      else
                        _buildDriverInfoSection(context),
                      _buildBookingDetails(context),
                      _buildRideDetails(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 50,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildFindingDriverSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Finding your driver...\nWeâ€™re looking for the best match for you!"
              .translate(context),
          textAlign: TextAlign.start,
          style: heading3Grey1(context),
        ),
        const SizedBox(height: 10),
        CountdownSegmentedBar(statusOfRide: widget.statusOfRide),
        const SizedBox(height: 10),
        Divider(color: grey5),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDriverInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rideStatus == ""
                      ? "Driver on the way".translate(context)
                      : rideStatus == "pick_up"
                      ? "Driver has arrived at your pickup point"
                      : rideStatus == "accepted"
                      ? "Driver on the way"
                      : "Reaching".translate(context),
                  style: heading3Grey1(context),
                ),
                Text(
                  fetchDistance.isEmpty
                      ? "Calculating...".translate(context)
                      : "$fetchDistance ${"away".translate(context)}",
                  style: regular(context),
                ),
              ],
            ),
            const Spacer(),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: blackColor,
              ),
              child: Text(
                fetchDuration.isEmpty ? "..." : fetchDuration,
                style: heading2(
                  context,
                ).copyWith(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: grey5),
        if (rideStatus != "ongoing") ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Start your ride with PIN".translate(context),
                style: regular(context).copyWith(fontWeight: FontWeight.bold),
              ),
              Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Row(
                  children: List.generate(otp.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(4),
                      width: 20,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        otp[index],
                        style: regular2(
                          context,
                        ).copyWith(color: grey1, fontSize: 14),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
        if (rideStatus == "ongoing" &&
            box.get("current_parcel_data") != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Share this drop OTP with the driver\nto complete the delivery"
                    .translate(context),
                style: regular(context).copyWith(fontWeight: FontWeight.bold),
              ),
              Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Row(
                  children: List.generate(dropotp.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(4),
                      width: 20,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dropotp[index],
                        style: regular2(
                          context,
                        ).copyWith(color: grey1, fontSize: 14),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
        _buildDriverCard(context),
      ],
    );
  }

  Widget _buildDriverCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: notifires.getBoxColor,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(12),
      child: BlocBuilder<RideRequestCubit, RideRequestState>(
        builder: (context, state) {
          return Row(
            children: [
              state.acceptedDriverImageUrl.isEmpty
                  ? Icon(
                      CupertinoIcons.profile_circled,
                      color: themeColor,
                      size: 50,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: notifires.getBoxColor,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: grey6,
                            blurRadius: 10,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      height: 65,
                      width: 65,
                      child: ClipOval(
                        child: myNetworkImage(state.acceptedDriverImageUrl),
                      ),
                    ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.acceptedDriverName,
                      style: regularBlack(context).copyWith(fontSize: 14),
                    ),
                    Text(
                      "${state.accepteDriverPhoneNumber} ",
                      style: regularBlack(context).copyWith(fontSize: 14),
                    ),
                    Text(
                      state.acceptedDriverVechileNumber,
                      style: regular(context).copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: yelloColor2.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: yelloColor2, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          state.driverRating,
                          style: regularBlack(
                            context,
                          ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          final phone = state.accepteDriverPhoneNumber;
                          final Uri launchUri = Uri(scheme: 'tel', path: phone);

                          if (await canLaunchUrl(launchUri)) {
                            await launchUrl(launchUri);
                          } else {}
                        },
                        child: SvgPicture.asset(
                          "assets/images/call_img.svg",
                          height: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingDetails(BuildContext context) {
    final stateData = context.read<BookRideRealTimeDataBaseCubit>().state;

    final dynamic rawParcel = box.get('current_parcel_data');

    final Map<String, dynamic>? parcelData = rawParcel != null
        ? Map<String, dynamic>.from(rawParcel as Map)
        : null;

    final String name = parcelData?['name']?.toString() ?? '';
    final String weight = parcelData?['weight']?.toString() ?? '';
    final String receiverName = parcelData?['receiverName']?.toString() ?? '';
    final String receiverPhone = parcelData?['receiverPhone']?.toString() ?? '';
    final String pickupInstructions =
        parcelData?['pickupInstructions']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Booking Details".translate(context),
          style: heading3Grey1(context),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: notifires.getBoxColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLocationRow(
                icon: Icons.circle,
                color: Colors.green,
                bgColor: Colors.green.shade100,
                text: stateData.pickupAddress,
                context: context,
              ),
              const SizedBox(height: 10),
              buildLocationRow(
                icon: Icons.location_on_outlined,
                color: Colors.red,
                bgColor: Colors.red.shade100,
                text: stateData.dropoffAddress,
                context: context,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Custom widget (auto hide if required fields empty)
        ParcelInfoWidget(
          name: name,
          weight: weight,
          receiverName: receiverName,
          receiverPhone: receiverPhone,
          pickupInstructions: pickupInstructions,
        ),
      ],
    );
  }

  Widget _buildRideDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          rideStatus == "ongoing"
              ? "Total Fare".translate(context)
              : "Ride Details".translate(context),
          style: heading3Grey1(context),
        ),
        const SizedBox(height: 10),
        if (rideStatus == "ongoing")
          Row(
            children: [
              Image.asset("assets/images/cashIcon.png", height: 50),
              const Spacer(),
              Text(
                "$currency ${widget.selectedVehicleData["fare"]}",
                style: heading2(context).copyWith(color: themeColor),
              ),
            ],
          )
        else
          _buildVehicleDetails(context),
        const SizedBox(height: 20),
        if (rideStatus != "ongoing") _buildCancelRideButton(context),
      ],
    );
  }

  Widget _buildVehicleDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 40,
                child: Image.network(
                  widget.selectedVehicleData["image"] ?? "",
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      SvgPicture.asset("assets/images/car.svg"),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.selectedVehicleData["vehicleName"] ?? "Unknown",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$currency ${widget.selectedVehicleData["fare"] ?? ""}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "${widget.selectedVehicleData["duration"] ?? "00"} (${widget.selectedVehicleData["distance"] ?? "00"} Km)",
                style: TextStyle(fontSize: 13, color: grey2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelRideButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _showCancelRideBottomSheet(context),
          child: Container(
            alignment: Alignment.center,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(
              "Cancel Ride".translate(context),
              style: regular2(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelRideBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: notifires.getbgcolor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, color: themeColor, size: 35),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to cancel your ride?".translate(context),
                style: heading2Grey1(context),
                textAlign: TextAlign.center,
              ),
              Text(
                "If you cancel now, your current ride request will be aborted."
                    .translate(context),
                style: regular(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      isManuallyCancelled = true;
                      box.delete("ride_data");
                      if (bookingId.isNotEmpty) {
                        context
                            .read<UpdateRideStatusInDatabaseCubit>()
                            .updateRideStatus(
                              context: context,
                              bookingId: bookingId,
                              rideStatus: "Cancelled",
                            );
                      }
                      cancelRideRequest(
                        rideId: context.read<RideRequestCubit>().state.rideId,
                      );
                      if (widget.statusOfRide.isEmpty) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ItemHomeScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                        stopAutoDistanceTimer();
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        "Cancel Ride".translate(context),
                        style: regular2(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: notifires.getBoxColor,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        "Keep Ride".translate(context),
                        style: regular2(
                          context,
                        ).copyWith(color: grey1, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

void showDriverCancelledRideDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Column(
        children: [
          const Icon(Icons.car_crash, color: Colors.redAccent, size: 50),
          const SizedBox(height: 10),
          Text(
            "Driver Cancelled Ride".translate(context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: Text(
        "The driver has unexpectedly cancelled the ride.\n\nWe're sorry for the inconvenience.\nYou can go back to the home screen and request another ride."
            .translate(context),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: Colors.black54),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        InkWell(
          onTap: () {
            goBack();
            context.read<RideRequestCubit>().resetState();
            context.read<GetRideRequestStatusCubit>().resetState();
            box.delete("ride_data");
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ItemHomeScreen()),
              (Route<dynamic> route) => false, // Remove all previous routes
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "Go Home".translate(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class CountdownSegmentedBar extends StatefulWidget {
  final String statusOfRide;

  const CountdownSegmentedBar({super.key, required this.statusOfRide});

  @override
  State<CountdownSegmentedBar> createState() => _CountdownSegmentedBarState();
}

class _CountdownSegmentedBarState extends State<CountdownSegmentedBar>
    with WidgetsBindingObserver {
  int totalSeconds = 60;
  int segmentCount = 5;
  late double segmentSeconds; //
  late Timer _timer;
  DateTime? _startTime;

  int get _elapsedSeconds {
    if (_startTime == null) return 0;
    return DateTime.now()
        .difference(_startTime!)
        .inSeconds
        .clamp(0, totalSeconds);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final durationFromCubit = context
        .read<DriverSearchIntervalCubit>()
        .state
        .value;
    totalSeconds = int.tryParse(durationFromCubit ?? "60") ?? 60;
    // Fixed segment count
    segmentCount = 5;
    // Dynamic segment duration
    segmentSeconds = totalSeconds / segmentCount;
    _startCountdown();
  }

  void _startCountdown() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = _elapsedSeconds;

      if (elapsed > totalSeconds) {
        _timer.cancel();
      } else if (elapsed == totalSeconds) {
        setState(() {});
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) showBottomSheetMessage();
        });
        _timer.cancel();
      } else {
        setState(() {});
      }
    });
  }

  void _resetCountdown() {
    _timer.cancel();
    setState(() {
      _startTime = DateTime.now();
    });
    _startCountdown();
  }

  void _stopCountdown() {
    if (_timer.isActive) {
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCountdown();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  int get remainingSeconds =>
      (totalSeconds - _elapsedSeconds).clamp(0, totalSeconds);

  int get filledSegments => (_elapsedSeconds / segmentSeconds).floor();

  double get currentSegmentProgress =>
      (_elapsedSeconds % segmentSeconds) / segmentSeconds;

  void showBottomSheetMessage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: notifires.getbgcolor,
      builder: (context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.maxFinite,
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                "Driver has not accepted your ride.".translate(context),
                textAlign: TextAlign.center,
                style: heading2Grey1(context),
              ),
              const SizedBox(height: 8),
              Text(
                "Try again or choose a different ride. Don't worry, we're here to help!"
                    .translate(context),
                textAlign: TextAlign.center,
                style: heading3Grey1(context),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  box.delete("ride_data");
                  Navigator.pop(context);
                  _resetCountdown(); // Restart timer
                  final state = context
                      .read<BookRideRealTimeDataBaseCubit>()
                      .state;

                  context.read<DriverNearByCubit>().getNearbyDrivers(
                    checkRestart: true,
                    distance: 15,
                    pickupLat: double.parse(state.pickupAddressLatitude),
                    pickupLng: double.parse(state.pickupAddressLongitude),
                    vehicleTypeId: context
                        .read<VehicleDataUpdateCubit>()
                        .state
                        .vehicleSelectedId
                        .toString(),
                  );
                  isManuallyCancelled = false;
                },
                child: Container(
                  height: 40,
                  width: 120,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: notifires.getBoxColor,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    "Retry".translate(context),
                    style: TextStyle(color: grey1, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showNoDriverFoundBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      builder: (context) => PopScope(
        canPop: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_rounded,
                    size: 55,
                    color: Colors.yellow.shade800,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "No nearby drivers found".translate(context),
                  textAlign: TextAlign.center,
                  style: heading2Grey1(context).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "We couldnâ€™t find any drivers around your pickup location. Please try again after a moment."
                      .translate(context),
                  textAlign: TextAlign.center,
                  style: heading3Grey1(
                    context,
                  ).copyWith(color: Colors.grey[600], height: 1.4),
                ),
                const SizedBox(height: 26),
                CustomsButtons(
                  text: "Try again",
                  backgroundColor: themeColor,
                  onPressed: () {
                    Navigator.pop(context);
                    _resetCountdown();

                    final state = context
                        .read<BookRideRealTimeDataBaseCubit>()
                        .state;

                    context.read<DriverNearByCubit>().getNearbyDrivers(
                      checkRestart: false,
                      distance: 15,
                      pickupLat: double.parse(state.pickupAddressLatitude),
                      pickupLng: double.parse(state.pickupAddressLongitude),
                      vehicleTypeId: context
                          .read<VehicleDataUpdateCubit>()
                          .state
                          .vehicleSelectedId
                          .toString(),
                    );
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                CustomsButtons(
                  text: "Cancel Ride",
                  backgroundColor: redColor2,
                  textColor: whiteColor,
                  onPressed: () {
                    isManuallyCancelled = true;
                    if (widget.statusOfRide.isEmpty) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ItemHomeScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverNearByCubit, DriverNearByState>(
      listener: (context, state) {
        if (state is DriverUpdated) {
          if (state.nearbyDrivers!.isEmpty) {
            _stopCountdown();
            showNoDriverFoundBottomSheet();

            context.read<DriverNearByCubit>().resetNearByDriverState();
            return;
          }
        }
      },
      child: Column(
        children: [
          Row(
            children: List.generate(segmentCount, (index) {
              int reversedIndex = segmentCount - 1 - index;
              double progress;

              if (reversedIndex < filledSegments) {
                progress = 0.0;
              } else if (reversedIndex == filledSegments) {
                progress = 1.0 - currentSegmentProgress;
              } else {
                progress = 1.0;
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index != 5 ? 4.0 : 0.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')} ${"min".translate(context)}",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const Spacer(),
              Text("Waiting...".translate(context), style: regular(context)),
            ],
          ),
        ],
      ),
    );
  }
}

class PulsingCircle extends StatefulWidget {
  const PulsingCircle({super.key});

  @override
  State<PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<PulsingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> scaleAnimation;
  late Animation<double> opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: scaleAnimation.value,
                child: Opacity(
                  opacity: opacityAnimation.value,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            },
          ),
          // Inner static dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade700,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class PersistentGoogleMap extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool myLocationEnabled;
  final Function(GoogleMapController) onMapCreated;

  const PersistentGoogleMap({
    super.key,
    required this.initialPosition,
    required this.markers,
    required this.polylines,
    required this.myLocationEnabled,
    required this.onMapCreated,
  });

  @override
  PersistentGoogleMapState createState() => PersistentGoogleMapState();
}

class PersistentGoogleMapState extends State<PersistentGoogleMap> {
  GoogleMapController? _mapController;
  Set<Marker> markers = {};
  Set<Polyline> polyline = {};

  @override
  void initState() {
    super.initState();
    markers = widget.markers;
    polyline = widget.polylines;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetPolylineCubit, GetPolylineState>(
      builder: (context, polylineState) {
        if (polylineState is GetPolylineUpdated) {
          polyline = polylineState.polylines ?? {};
          if (polyline.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _moveCameraToFitPolylineAndMarkers();
            });
          }
          context.read<GetPolylineCubit>().resetPolylines();
        }

        return BlocBuilder<UserMarkerCubit, UserMarkerState>(
          builder: (context, markerState) {
            if (markerState is UserMarkerUpdated) {
              markers = markerState.markers;
            }
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialPosition,
                zoom: 15,
              ),
              myLocationEnabled: widget.myLocationEnabled,
              markers: markers,
              polylines: polyline,
              onMapCreated: (controller) {
                if (_mapController == null) {
                  _mapController = controller;
                  widget.onMapCreated(controller);
                }
              },
            );
          },
        );
      },
    );
  }

  void _moveCameraToFitPolylineAndMarkers() {
    if (_mapController == null || polyline.isEmpty) return;

    LatLngBounds bounds;
    final points = polyline.expand((p) => p.points).toList();

    if (points.isEmpty) return;

    final southwestLat = points
        .map((p) => p.latitude)
        .reduce((a, b) => a < b ? a : b);
    final southwestLng = points
        .map((p) => p.longitude)
        .reduce((a, b) => a < b ? a : b);
    final northeastLat = points
        .map((p) => p.latitude)
        .reduce((a, b) => a > b ? a : b);
    final northeastLng = points
        .map((p) => p.longitude)
        .reduce((a, b) => a > b ? a : b);

    bounds = LatLngBounds(
      southwest: LatLng(southwestLat, southwestLng),
      northeast: LatLng(northeastLat, northeastLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 150), // 150 = padding
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class ScreenTracker {
  static String? currentScreen;

  static void setCurrentScreen(String screenName) {
    currentScreen = screenName;
  }

  static bool isScreenActive(String screenName) {
    return currentScreen == screenName;
  }
}

class ParcelInfoWidget extends StatelessWidget {
  final String name;
  final String weight;
  final String receiverName;
  final String receiverPhone;
  final String pickupInstructions;

  const ParcelInfoWidget({
    super.key,
    required this.name,
    required this.weight,
    required this.receiverName,
    required this.receiverPhone,
    required this.pickupInstructions,
  });

  bool get _shouldHide =>
      name.trim().isEmpty &&
      receiverName.trim().isEmpty &&
      receiverPhone.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    if (_shouldHide) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8B5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Parcel Details".translate(context),
            style: heading2Grey1(context).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.deepOrange,
            ),
          ),

          const SizedBox(height: 10),

          // Grid rows
          Row(
            children: [
              Expanded(
                child: _infoCard("Item", name, Icons.inventory_2_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoCard(
                  "Weight",
                  "$weight ${"kg".translate(context)}",
                  Icons.scale_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _infoCard(
                  "Receiver",
                  receiverName,
                  Icons.person_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoCard("Phone", receiverPhone, Icons.call_outlined),
              ),
            ],
          ),

          if (pickupInstructions.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              "Instruction: $pickupInstructions",
              style: heading3Grey1(
                context,
              ).copyWith(fontSize: 11, color: Colors.brown),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE0C2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.deepOrange),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.translate(navigatorKey.currentContext!),
                  style: heading3Grey1(
                    navigatorKey.currentContext!,
                  ).copyWith(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: heading3Grey1(
                    navigatorKey.currentContext!,
                  ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
