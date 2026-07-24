// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:ride_on/core/services/data_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

import '../../../core/extensions/workspace.dart';
import '../../../core/services/config.dart';
import '../general_cubit.dart';

abstract class DriverNearByState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverNearByState {}

class DriverLoading extends DriverNearByState {}

class DriverUpdated extends DriverNearByState {
  final List<Map<String, dynamic>>? nearbyDrivers;
  final bool? checkRestart;

  DriverUpdated({this.nearbyDrivers, this.checkRestart});

  @override
  List<Object?> get props => [nearbyDrivers];
}

class DriverUpdatedRestart extends DriverNearByState {
  final List<Map<String, dynamic>> nearbyDrivers;

  DriverUpdatedRestart(this.nearbyDrivers);

  @override
  List<Object?> get props => [nearbyDrivers];
}

class DriverError extends DriverNearByState {
  final String error;
  DriverError(this.error);

  @override
  List<Object?> get props => [error];
}

class DriverNearByCubit extends Cubit<DriverNearByState> {
  DriverNearByCubit() : super(DriverInitial());

  final FirebaseFirestore firestore = FirebaseFirestore.instance;


  Future<void> getNearbyDrivers(
      {double? pickupLat,
        double? pickupLng,
        String? vehicleTypeId,
        double? distance,
        bool? checkRestart}) async {
    emit(DriverLoading());
    final rideId = box.get("rideId");
 



    try {

      double degreesToRadians(double degrees) {
        return degrees * pi / 180;
      }
      double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        const double earthRadius = 6371.0; // Earth radius in kilometers

        final double dLat = degreesToRadians(lat2 - lat1);
        final double dLon = degreesToRadians(lon2 - lon1);

        final double a = sin(dLat / 2) * sin(dLat / 2) +
            cos(degreesToRadians(lat1)) *
                cos(degreesToRadians(lat2)) *
                sin(dLon / 2) *
                sin(dLon / 2);

        final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

        return earthRadius * c;
      }


      final collectionRef = firestore.collection('drivers');
      final center = GeoFirePoint(GeoPoint(
        pickupLat ?? 0.0,
        pickupLng ?? 0.0,
      ));



      final geoCollection = GeoCollectionReference(collectionRef);


      final docs = await geoCollection.fetchWithin(
        center: center,
        radiusInKm: distance ?? 15.0,
        field: 'geo',
        geopointFrom: (data) {
          final geo = data['geo'] as Map<String, dynamic>?;
          return geo?['geopoint'] as GeoPoint;
        },
        strictMode: true,
      );




     
      final nearbyDrivers = docs.map((doc) {
        final data = doc.data();
        if (data == null) return null;

        // Keep filtering in app layer so Firestore composite index is not mandatory.
        final driverStatus = (data['driverStatus'] ?? '').toString().trim().toLowerCase();
        final docApprovedStatus = (data['docApprovedStatus'] ?? '').toString().trim().toLowerCase();
        final rideStatus = (data['rideStatus'] ?? '').toString().trim().toLowerCase();
        final driverItemTypeId = (data['itemTypeId'] ?? '').toString();
        final requestedItemTypeId = (vehicleTypeId ?? '').toString();
        if (driverStatus != 'active' ||
            docApprovedStatus != 'approved' ||
            rideStatus != 'available' ||
            driverItemTypeId != requestedItemTypeId) {
          return null;
        }

        final geoData = data['geo'] as Map<String, dynamic>?;
        final geopoint = geoData?['geopoint'] as GeoPoint?;
        final rejectedRides = data['rejected_rides'] as List<dynamic>? ?? [];
        final timestamp = data['timestamp'];

        if (rejectedRides.contains(rideId)) {
          return null;
        }

        // ðŸ”¥ Check timestamp validity
        final context = navigatorKey.currentContext;
        if (context != null) {
          final lastActiveState = context.read<LastActiveApp>().state.value;

          if (lastActiveState != null && lastActiveState.toString() != "0" && lastActiveState.toString().isNotEmpty) {
            debugPrint('Using Last active: $lastActiveState');

            if (timestamp is Timestamp) {
              final lastUpdate = timestamp.toDate();
              final now = DateTime.now();
              final difference = now.difference(lastUpdate).inMinutes;

              if (difference > 20) {
                debugPrint("Driver ${doc.id} removed: last update $difference min ago");
                return null;
              }
            } else {
              debugPrint("Driver ${doc.id} removed: no valid timestamp found");
              return null;
            }
          } else {
            debugPrint("Driver ${doc.id} skipped: LastActiveApp is empty or 0");
          }
        } else {
          debugPrint("No valid context found â€” skipping driver ${doc.id}");
        }

        if (geopoint != null) {
          final distanceInKm = calculateDistance(
            pickupLat ?? 0.0,
            pickupLng ?? 0.0,
            geopoint.latitude,
            geopoint.longitude,
          );

          return {
            'id': doc.id,
            'latitude': geopoint.latitude,
            'longitude': geopoint.longitude,
            'distance': distanceInKm,
            ...data,
          };
        }

        return null;
      }).whereType<Map<String, dynamic>>().toList();


      nearbyDrivers.sort((a, b) {
        final distanceA = a['distance'] as double;
        final distanceB = b['distance'] as double;
        return distanceA.compareTo(distanceB);
      });
      final nearestDrivers = nearbyDrivers.take(20).toList();

      debugPrint('Nearest 20 Drivers: ${nearestDrivers.length}');
      debugPrint('all nearbyDrivers ${nearbyDrivers.length}');


      if (navigatorKey.currentContext!
          .read<UseGoogleSourceDestination>()
          .state
          .value ==
          "1") {
        List<Map<String, dynamic>> finalFilteredDrivers = [];

        List<List<Map<String, dynamic>>> chunkDrivers(
            List<Map<String, dynamic>> list, int chunkSize) {
          List<List<Map<String, dynamic>>> chunks = [];
          for (var i = 0; i < list.length; i += chunkSize) {
            chunks.add(list.sublist(
                i, i + chunkSize > list.length ? list.length : i + chunkSize));
          }
          return chunks;
        }

        final driverChunks = chunkDrivers(nearestDrivers, 25);


        final String destination = "$pickupLat,$pickupLng";

        final futures = driverChunks.map((chunk) async {
          List<String> originCoords = chunk.map((driver) {
            return "${driver['latitude']},${driver['longitude']}";
          }).toList();

          final String origins = originCoords.join('|');
          final String url =
              "https://maps.googleapis.com/maps/api/distancematrix/json"
              "?origins=$origins"
              "&destinations=$destination"
              "&key=${Config.googleKey}";

          final response = await http.get(Uri.parse(url));


          List<Map<String, dynamic>> filtered = [];

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final rows = data['rows'] as List;

            for (int i = 0; i < rows.length; i++) {
              final element = rows[i]['elements'][0];

              if (element['status'] == "OK") {
                final distanceMeters = element['distance']['value'];
                final distanceKm = distanceMeters / 1000;



                if (distanceKm <= distance) {
                  filtered.add(chunk[i]);
                }
              } else {

              }
            }
          }

          return filtered;
        }).toList();


        final results = await Future.wait(futures);

        for (var list in results) {
          finalFilteredDrivers.addAll(list);
        }

        emit(DriverUpdated(
            nearbyDrivers: finalFilteredDrivers, checkRestart: checkRestart));

        debugPrint(
            "Filtered ${finalFilteredDrivers.length} drivers within $distance km route using Google API");
      } else {
        emit(DriverUpdated(nearbyDrivers: nearestDrivers, checkRestart: checkRestart));
        debugPrint(
            "Filtered ${nearestDrivers.length} drivers within $distance km route using geoLocation");
      }


    } catch (e) {
      emit(DriverError(e.toString()));
      debugPrint("Error fetching nearby drivers (once): $e");
    }
  }


  resetNearByDriverState() {
    emit(DriverInitial());
  }
}

// Driver States
abstract class DriverMapState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DriverMapInitial extends DriverMapState {}

class DriverMapLoading extends DriverMapState {
  final Set<Marker> markers;
  DriverMapLoading(this.markers);

  @override
  List<Object?> get props => [markers];
}

class DriverMapUpdated extends DriverMapState {
  final Set<Marker> markers;
  DriverMapUpdated(this.markers);

  @override
  List<Object?> get props => [markers];
}

class DriverMapError extends DriverMapState {
  final String error;
  DriverMapError(this.error);

  @override
  List<Object?> get props => [error];
}

class DriverMapCubit extends Cubit<DriverMapState> {
  DriverMapCubit() : super(DriverMapInitial());

  Future<void> updateMapWithNearbyDrivers({
    required BuildContext context,
    required double sourcelat,
    required double sourcelng,
    required double destinationlat,
    required double destinationlng,
    required String pickupImage,
    required String dropOffImage,
    required List<Map<String, dynamic>> nearbyDrivers,
  }) async {

    try {
      final Uint8List markerIconDropOff =
          await getBytesFromAsset(dropOffImage, 15);
      final Uint8List markerIconPickUp =
          await getBytesFromAsset(pickupImage, 15);

      Set<Marker> markers = {};
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(sourcelat, sourcelng),
        icon: BitmapDescriptor.bytes(markerIconPickUp),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ));

      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(destinationlat, destinationlng),
        icon: BitmapDescriptor.bytes(markerIconDropOff),
        infoWindow: const InfoWindow(title: 'Dropoff Location'),
      ));

      emit(DriverMapUpdated(markers));
    } catch (e) {

      emit(DriverMapError(e.toString()));
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void resetState() {
    emit(DriverMapInitial());
  }
}

abstract class GetPolylineState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetPolylineInitial extends GetPolylineState {}

class GetPolylineLoading extends GetPolylineState {
  final Set<Polyline> polylines;
  GetPolylineLoading(this.polylines);

  @override
  List<Object?> get props => [polylines];
}

class GetPolylineUpdated extends GetPolylineState {
  final Set<Polyline>? polylines;
  GetPolylineUpdated({this.polylines});

  @override
  List<Object?> get props => [polylines];
}

class GetPolylineUpdatedError extends GetPolylineState {
  final String error;
  GetPolylineUpdatedError(this.error);

  @override
  List<Object?> get props => [error];
}

class GetPolylineCubit extends Cubit<GetPolylineState> {
  GetPolylineCubit() : super(GetPolylineInitial());

  final Map<PolylineId, Polyline> _polylines = {};
  final PolylinePoints _polylinePoints = PolylinePoints();

  Future<void> getPolyline({
    required double sourcelat,
    required double sourcelng,
    required double destinationlat,
    required double destinationlng,
    required bool isPickupRoute, // true for pickup, false for dropoff
  }) async {
    try {
      if (sourcelat == 0.0 ||
          sourcelng == 0.0 ||
          destinationlat == 0.0 ||
          destinationlng == 0.0) {
        emit(GetPolylineUpdatedError("Invalid coordinates"));
        return;
      }

      emit(GetPolylineLoading(_polylines.values.toSet()));

      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: Config.googleKey,
        request: PolylineRequest(
          origin: PointLatLng(sourcelat, sourcelng),
          destination: PointLatLng(destinationlat, destinationlng),
          mode: TravelMode.driving,
        ),
      );

      if (result.status == 'OK') {
        final polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        final PolylineId polylineId = isPickupRoute
            ? const PolylineId("DriverPickupToUser")
            : const PolylineId("DriverDropoffToUser");

        // Remove the polyline of the opposite route type
        final PolylineId oppositePolylineId = isPickupRoute
            ? const PolylineId("DriverDropoffToUser")
            : const PolylineId("DriverPickupToUser");
        _polylines.remove(oppositePolylineId);

        // Remove the current polyline (if any) for the same route type
        _polylines.remove(polylineId);

        _addPolyLine(
          coordinates: polylineCoordinates,
          id: polylineId,
          color: isPickupRoute ? Colors.blue : Colors.green,
        );

        emit(GetPolylineUpdated(polylines: _polylines.values.toSet()));
      } else {
        emit(GetPolylineUpdatedError(
            result.errorMessage ?? "Failed to get polyline"));
      }
    } catch (e) {
      emit(GetPolylineUpdatedError("Exception: $e"));
    }
  }
  

  void _addPolyLine({
    required List<LatLng> coordinates,
    required PolylineId id,
    required Color color,
  }) {
    final polyline = Polyline(
      polylineId: id,
      color: color,
      width: 5,
      points: coordinates,
    );
    _polylines[id] = polyline;
  }

  Set<Polyline> get currentPolylines => _polylines.values.toSet();

  void resetPolylines() {
    _polylines.clear();
    emit(GetPolylineInitial());
  }
}


