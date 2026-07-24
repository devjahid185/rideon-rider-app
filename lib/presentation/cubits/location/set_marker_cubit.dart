// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui' as ui;
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/utils/common_widget.dart';


abstract class MarkerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MarkerInitial extends MarkerState {}

class MarkerUpdated extends MarkerState {
  final Set<Marker> markers;

  MarkerUpdated({required this.markers});

  @override
  List<Object?> get props => [markers];
}

class MarkerCubit extends Cubit<MarkerState> {
  MarkerCubit() : super(MarkerInitial());

  final Set<Marker> _markers = {};

  void addOrUpdateMarker(LatLng position, String title, String markerId,
      String image, int size) async {
    final Uint8List markerIcon = await getBytesFromAsset(image, size);

    Marker marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      draggable: false,
      zIndex: 2,
      flat: true,
      infoWindow: InfoWindow(title: title),
      icon: BitmapDescriptor.fromBytes(markerIcon),
    );

    _markers.removeWhere((m) => m.markerId.value == markerId);
    _markers.add(marker);

    emit(MarkerUpdated(markers: _markers));
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

  void resetMarker() {
    emit(MarkerInitial());
  }
}

abstract class GetUpdatedLocationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetUpdatedLocationInitial extends GetUpdatedLocationState {}

class GetUpdatedLocationUpdated extends GetUpdatedLocationState {
  final double lat;
  final double lng;

  GetUpdatedLocationUpdated({
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [
        lat,
        lng,
      ];
}

class GetUpdatedLocationCubit extends Cubit<GetUpdatedLocationState> {
  GetUpdatedLocationCubit() : super(GetUpdatedLocationInitial());

  StreamSubscription<DatabaseEvent>? _driverLocationSubscription;

  void updateDriverLocation({int? selectedDriverId}) {
    if (selectedDriverId == null) return;

    final DatabaseReference database = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(selectedDriverId.toString());

    _driverLocationSubscription?.cancel();

    _driverLocationSubscription = database.onValue.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        final driverData = event.snapshot.value as Map;
        final location = driverData['location'];


        if (location != null &&
            location is Map &&
            location['latitude'] != null &&
            location['longitude'] != null) {
          final double lat = double.parse(location['latitude'].toString());
          final double lng = double.parse(location['longitude'].toString());

          emit(GetUpdatedLocationUpdated(
            lat: lat,
            lng: lng,
          ));
        }
      }
    }, onError: (error) {
   //
    });
  }

  void resetLocation() {
    _driverLocationSubscription?.cancel();
    emit(GetUpdatedLocationInitial());
  }

  @override
  Future<void> close() {
    _driverLocationSubscription?.cancel();
    return super.close();
  }
}

abstract class UserMarkerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserMarkerInitial extends UserMarkerState {}

class UserMarkerUpdated extends UserMarkerState {
  final Set<Marker> markers;

  UserMarkerUpdated({required this.markers});

  @override
  List<Object?> get props => [markers];
}



class UserMarkerCubit extends Cubit<UserMarkerState> {
  UserMarkerCubit() : super(UserMarkerInitial());

  final Set<Marker> _markers = {};

  Future<void> addOrUpdateMarker(
    LatLng position,
    String title,
    String markerId,
    String iconPath,
    int size,
  ) async {
    Uint8List markerIcon;

    if (title.toString() == "Driver Location") {
      markerIcon = await createCustomMarkerImage(iconPath);
    } else {
      markerIcon = await getBytesFromAsset(iconPath, size);
    }
    _markers.removeWhere((marker) => marker.markerId.value == markerId);
    _markers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.fromBytes(markerIcon),
      ),
    );
    emit(UserMarkerUpdated(markers: _markers));
  }

  void removeMarker(String markerId) {
    _markers.removeWhere((marker) => marker.markerId.value == markerId);
    emit(UserMarkerUpdated(markers: _markers));
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

  void clear() {
    emit(UserMarkerInitial());
    removeMarker("User_marker");
    removeMarker("drop_marker");
    removeMarker("driver_marker");
  }
}


