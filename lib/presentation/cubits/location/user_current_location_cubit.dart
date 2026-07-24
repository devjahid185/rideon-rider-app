import 'dart:async';
import 'dart:convert';
 import 'package:ride_on/domain/entities/catrgory.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
 import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

import '../../../core/services/config.dart';

abstract class LocationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationSucess extends LocationState {
  final LatLng? currentLocation;

  LocationSucess({
    this.currentLocation,
  });

  @override
  List<Object?> get props => [currentLocation];
}

// ignore: must_be_immutable
class LocationFailure extends LocationState {
  String? error;
  LocationFailure({this.error});
  @override
  List<Object?> get props => [error];
}

class LocationUserCubit extends Cubit<LocationState> {
  LocationUserCubit() : super(LocationInitial());
  late StreamSubscription<Position> positionStreamSubscription;
  var markers = <Marker>{};

  void startLiveLocationTracking({bool? ischeckedLoading}) async {
    try {
      if (ischeckedLoading == true) {
        emit(LocationLoading());
      }

      LocationPermission permission = await _checkPermissions();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {

        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      updateUserLocation(position);


    } catch (e) {
      emit(LocationFailure(error: "$e"));

    }
  }

  Future<LocationPermission> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {

      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

      }
    }

    if (permission == LocationPermission.deniedForever) {

    }

    return permission;
  }

  Timer? _debounceTimer; // Add a timer

  void updateUserLocation(Position position) {
    try {
      if (_debounceTimer?.isActive ?? false) {
        _debounceTimer!.cancel();
      }

      _debounceTimer = Timer(const Duration(seconds: 1), () {
        LatLng currentLocation = LatLng(position.latitude, position.longitude);
        emit(LocationSucess(currentLocation: currentLocation));
      });
    } catch (err) {
      emit(LocationFailure(error: "$err"));
    }
  }

  void removeState() {
    emit(LocationInitial());
  }
}

abstract class UpdateCurrentAddressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateCurrentAddresInitial extends UpdateCurrentAddressState {}

class UpdateCurrentAddressLoading extends UpdateCurrentAddressState {}

class UpdateCurrentAddressFailed extends UpdateCurrentAddressState {}

class UpdateCurrentAddresSuccess extends UpdateCurrentAddressState {
  final String? currentAddress;
  final double? lat;
  final double? lng;
  UpdateCurrentAddresSuccess({this.currentAddress, this.lat, this.lng});

  @override
  List<Object?> get props => [currentAddress, lat, lng];
}

class UpdateCurrentAddressCubit extends Cubit<UpdateCurrentAddressState> {
  UpdateCurrentAddressCubit() : super(UpdateCurrentAddresInitial());

  Future<void> getAddressFromLatLng(
      {double? latitude, double? longitude}) async {
    try {
      emit(UpdateCurrentAddressLoading());

      const String googleApiKey = Config.googleKey;
      if (latitude != null && longitude != null) {
        String url =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$googleApiKey";

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          if (data["status"] == "OK") {
            String address = data["results"][0]["formatted_address"];
            emit(UpdateCurrentAddresSuccess(
                currentAddress: address, lat: latitude, lng: longitude));
          } else {
            emit(UpdateCurrentAddressFailed());

          }
        } else {
          emit(UpdateCurrentAddressFailed());

        }
      }
    } catch (e) {
      emit(UpdateCurrentAddressFailed());

    }
  }

  void removeAddress() {
    emit(UpdateCurrentAddresInitial());
  }
}

abstract class UpdateSearchMapAddressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateSearchMapAddresInitial extends UpdateSearchMapAddressState {}

class UpdateSearchMapAddresSuccess extends UpdateSearchMapAddressState {
  final String? currentAddress;
  final double? lat;
  final double? lng;
  UpdateSearchMapAddresSuccess({this.currentAddress, this.lat, this.lng});

  @override
  List<Object?> get props => [currentAddress, lat, lng];
}

class UpdateSearchMapAddressCubit extends Cubit<UpdateSearchMapAddressState> {
  UpdateSearchMapAddressCubit() : super(UpdateSearchMapAddresInitial());

  Future<void> getAddressFromLatLng(
      {double? latitude, double? longitude}) async {
    try {
      String googleApiKey = Config.googleKey;
      if (latitude != null && longitude != null) {
        String url =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$googleApiKey";

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          if (data["status"] == "OK") {
            String address = data["results"][0]["formatted_address"];
            emit(UpdateSearchMapAddresSuccess(
                currentAddress: address, lat: latitude, lng: longitude));
          } else {

          }
        } else {

        }
      }
    } catch (e) {
       //
    }
  }




  void removeAddress() {
    emit(UpdateSearchMapAddresInitial());
  }
}

class GetSuggestionAddressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetSuggestionAddressSuccess extends GetSuggestionAddressState {
  final List<String>? suggestions;
  GetSuggestionAddressSuccess({this.suggestions});
  @override
  List<Object?> get props => [suggestions];
}

class GetSuggestionAddressCubit extends Cubit<GetSuggestionAddressState> {
  GetSuggestionAddressCubit() : super(GetSuggestionAddressState());

  Future<void> getSuggestions(String query) async {
    if (query.isEmpty) {
      emit(GetSuggestionAddressSuccess(suggestions: const []));
      return;
    }



    const apiKey = Config.googleKey;

    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeQueryComponent(query)}&key=$apiKey");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey("predictions") &&
            jsonResponse["predictions"].isNotEmpty) {
          final List data = jsonResponse["predictions"];
          List<String> suggestions =
              data.map<String>((place) => place["description"]).toList();

          emit(GetSuggestionAddressSuccess(suggestions: suggestions));
        } else {
          emit(GetSuggestionAddressSuccess(suggestions: const []));
        }
      } else {
         emit(GetSuggestionAddressSuccess(suggestions: const []));
      }
    } catch (e) {
       emit(GetSuggestionAddressSuccess(suggestions: const []));
    }
  }


  void removeAddress() {
    emit(GetSuggestionAddressSuccess(suggestions: const []));
  }
}

class GetCordinatesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetCordinatesSuccess extends GetCordinatesState {
  final String? lattiude;
  final String? longitude;
  final String? address;

  GetCordinatesSuccess({this.lattiude, this.longitude, this.address});
  @override
  List<Object?> get props => [lattiude, longitude];
}

class GetCordinatesFailure extends GetCordinatesState {
  final String? error;

  GetCordinatesFailure({
    this.error,
  });
  @override
  List<Object?> get props => [error];
}

class GetCordinatesCubit extends Cubit<GetCordinatesState> {
  GetCordinatesCubit() : super(GetCordinatesState());

  Future<void> getCoordinates(
      {required String address, bool? checkStatus}) async {
    try {
      const String googleApiKey = Config.googleKey;
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final location = data['results'][0]['geometry']['location'];
          final latitude = location['lat'].toString();
          final longitude = location['lng'].toString();


          emit(GetCordinatesSuccess(lattiude: latitude, longitude: longitude));
        } else {
          emit(GetCordinatesFailure(error: data['status']));
        }
      } else {
        emit(GetCordinatesFailure(error: "HTTP error: ${response.statusCode}"));
      }
    } catch (e) {
      emit(GetCordinatesFailure(error: "Exception: $e"));
    }
  }

  void removeCordinates() {
    emit(GetCordinatesSuccess(lattiude: "", longitude: ""));
  }
}

class SelectedAddressState extends Equatable {
  final String selectedPickupAddress;
  final String selectedDropOffAddress;
  final bool isCheckedSelectedPickup;
  final bool isCheckedSelectedDropOff;
  final bool icheckedCrossIconPickup;
  final bool ischeckedCrossIconDropOff;
  final bool ischeckedPickupSuggestion;
  final bool ischekcedDropOffSuggestion;

  const SelectedAddressState(
      {this.selectedPickupAddress = "",
      this.selectedDropOffAddress = "",
      this.ischeckedPickupSuggestion = false,
      this.ischekcedDropOffSuggestion = false,
      this.icheckedCrossIconPickup = false,
      this.ischeckedCrossIconDropOff = false,
      this.isCheckedSelectedDropOff = false,
      this.isCheckedSelectedPickup = false});

  SelectedAddressState copyWith(
      {String? selectedPickupAddress,
      String? selectedDropOffAddress,
      bool? isCheckedSelectedDropOff,
      bool? ischeckedPickupSuggestion,
      bool? ischekcedDropOffSuggestion,
      bool? isCheckedSelectedPickup,
      bool? icheckedCrossIconPickup,
      bool? ischeckedCrossIconDropOff}) {
    return SelectedAddressState(
        ischeckedPickupSuggestion:
            ischeckedPickupSuggestion ?? this.ischeckedPickupSuggestion,
        ischekcedDropOffSuggestion:
            ischekcedDropOffSuggestion ?? this.ischekcedDropOffSuggestion,
        ischeckedCrossIconDropOff:
            ischeckedCrossIconDropOff ?? this.ischeckedCrossIconDropOff,
        icheckedCrossIconPickup:
            icheckedCrossIconPickup ?? this.icheckedCrossIconPickup,
        isCheckedSelectedDropOff:
            isCheckedSelectedDropOff ?? this.isCheckedSelectedDropOff,
        isCheckedSelectedPickup:
            isCheckedSelectedPickup ?? this.isCheckedSelectedPickup,
        selectedPickupAddress:
            selectedPickupAddress ?? this.selectedPickupAddress,
        selectedDropOffAddress:
            selectedDropOffAddress ?? this.selectedDropOffAddress);
  }

  @override
  List<Object?> get props => [
        selectedPickupAddress,
        selectedDropOffAddress,
        isCheckedSelectedDropOff,
        isCheckedSelectedPickup,
        ischeckedCrossIconDropOff,
        icheckedCrossIconPickup,
        ischeckedPickupSuggestion,
        ischekcedDropOffSuggestion
      ];
}

class SelectedAddressCubit extends Cubit<SelectedAddressState> {
  SelectedAddressCubit() : super(const SelectedAddressState());

  final TextEditingController pickupAddressController = TextEditingController();
  final TextEditingController dropOffAddressController =
      TextEditingController();

  void updateSelectePickupdSuggestion({
    bool? ischeckedPickupSuggestion,
  }) {
    emit(state.copyWith(
      ischeckedPickupSuggestion: ischeckedPickupSuggestion,
    ));
  }

  void updateSelecteDropOffdSuggestion({
    bool? ischekcedDropOffSuggestion,
  }) {
    emit(state.copyWith(
      ischekcedDropOffSuggestion: ischekcedDropOffSuggestion,
    ));
  }

  void removeSelectePickupdSuggestion() {
    emit(state.copyWith(ischeckedPickupSuggestion: false));
  }

  void removeSelecteDropOffdSuggestion() {
    emit(state.copyWith(
      ischekcedDropOffSuggestion: false,
    ));
  }

  void updateSelectePickupdAddress({
    String? selectedPickupAddress,
  }) {
    emit(state.copyWith(
      selectedPickupAddress: selectedPickupAddress,
    ));
  }

  void updateSelecteDropOffdAddress({
    String? selectedDropOffAddress,
  }) {
    emit(state.copyWith(
      selectedDropOffAddress: selectedDropOffAddress,
    ));
  }

  void updateIsSelectePickupdAddress({
    bool? isCheckedSelectedPickup,
  }) {
    emit(state.copyWith(
      isCheckedSelectedPickup: isCheckedSelectedPickup,
    ));
  }

  void updateIsSelectedDropOffAddress({
    bool? isCheckedSelectedDropOff,
  }) {
    emit(state.copyWith(
      isCheckedSelectedDropOff: isCheckedSelectedDropOff,
    ));
  }

  void updateIsCrossIconSelectePickup({
    bool? icheckedCrossIconPickup,
  }) {
    emit(state.copyWith(
      icheckedCrossIconPickup: icheckedCrossIconPickup,
    ));
  }

  void updateIsCrossIconSelectedDropOff({
    bool? ischeckedCrossIconDropOff,
  }) {
    emit(state.copyWith(
      ischeckedCrossIconDropOff: ischeckedCrossIconDropOff,
    ));
  }

  void removeIsCrossIconSelectePickupd() {
    emit(const SelectedAddressState(icheckedCrossIconPickup: false));
  }

  void removeIsCrosssIconSelectedDropOff() {
    emit(const SelectedAddressState(ischeckedCrossIconDropOff: false));
  }

  void removeIsSelectePickupdAddress() {
    emit(const SelectedAddressState(isCheckedSelectedPickup: false));
  }

  void removeIsSelectedDropOffAddress() {
    emit(const SelectedAddressState(isCheckedSelectedDropOff: false));
  }

  void removeSelectedPickupAddress() {
    emit(const SelectedAddressState(selectedPickupAddress: ""));
  }

  void removeSelectedDropOffAddress() {
    emit(const SelectedAddressState(selectedDropOffAddress: ""));
  }

  void resetAllParameter() {
    emit(const SelectedAddressState());
  }
}

class SetVehicleCategoryState extends Equatable {
  final List<ItemTypes> itemList;

  const SetVehicleCategoryState({this.itemList = const []});

  SetVehicleCategoryState copyWith({List<ItemTypes>? itemList}) {
    return SetVehicleCategoryState(
      itemList: itemList ?? this.itemList,
    );
  }


  bool shouldRebuild(SetVehicleCategoryState previousState) {
    return itemList != previousState.itemList;
  }

  @override
  List<Object?> get props => [itemList];
}

class SetVehicleCategoryCubit extends Cubit<SetVehicleCategoryState> {
  SetVehicleCategoryCubit() : super(const SetVehicleCategoryState());

  void updateSetVehicleCategoryList(List<ItemTypes>? itemList) {
    emit(state.copyWith(
      itemList: itemList,
    ));
  }

  void resetState() {
    emit(const SetVehicleCategoryState());
  }
}






