// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:ride_on/domain/entities/get_item_price.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:ride_on/presentation/cubits/general_cubit.dart';
import 'package:ride_on/presentation/cubits/location/user_current_location_cubit.dart';

import '../../../core/services/config.dart';
import '../../../data/repositories/vehicle_repository.dart';

abstract class GetItemPriceState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetItemPriceInitial extends GetItemPriceState {}

class GetItemPriceLoading extends GetItemPriceState {}

// ignore: must_be_immutable
class GetItemPriceUpdated extends GetItemPriceState {
  GetItemPrice? getItemPriceData;

  GetItemPriceUpdated({this.getItemPriceData});

  @override
  List<Object?> get props => [getItemPriceData];
}

class GetItemPriceError extends GetItemPriceState {
  final String? error;
  GetItemPriceError({this.error});

  @override
  List<Object?> get props => [error];
}

class GetItemPriceCubit extends Cubit<GetItemPriceState> {
  final VehicleRepository vehicleRepository;

  GetItemPriceCubit(this.vehicleRepository) : super(GetItemPriceInitial());

  Future<void> getItemPrice({
    required int itemTypeId,
    required double distance,
    required BuildContext context,
  }) async {
    try {
      emit(GetItemPriceLoading());
      final response = await vehicleRepository.getItemPrice(
          context: context, itemTypeId: itemTypeId, distance: distance);
      if (response["status"] == 200) {
        GetItemPrice getItemPrice = GetItemPrice.fromJson(response);

        emit(GetItemPriceUpdated(getItemPriceData: getItemPrice));
      } else {
        emit(GetItemPriceError(error: response["error"]));
      }
    } catch (error) {
      emit(GetItemPriceError(error: "$error"));
    }
  }

  void resetItemPrice() {
    emit(GetItemPriceInitial());
  }
}

class GetDistanceRouteState extends Equatable {
  final List<Map<String, dynamic>> vehicleFares;
  final double? distance;
  final String? error;

  GetDistanceRouteState({
    List<Map<String, dynamic>>? vehicleFares,
    this.distance,
    this.error,
  }) : vehicleFares = vehicleFares ?? [];

  GetDistanceRouteState copyWith({
    List<Map<String, dynamic>>? vehicleFares,
    double? distance,
    String? error,
  }) {
    return GetDistanceRouteState(
      vehicleFares: vehicleFares ?? this.vehicleFares,
      distance: distance ?? this.distance,
      error: error,
    );
  }

  @override
  List<Object?> get props => [vehicleFares, distance, error];
}

class GetDistanceRouteCubit extends Cubit<GetDistanceRouteState> {
  GetDistanceRouteCubit() : super(GetDistanceRouteState());

  Future<void> getDistanceAndFares({
    required BuildContext context,
    required String pickupLat,
    required String pickupLng,
    required String dropOffLat,
    required String dropOffLng,
  }) async {
    try {
      final vehicleCategories =
          context.read<SetVehicleCategoryCubit>().state.itemList;

      final modesNeeded = vehicleCategories
          .map((item) => item.mode?.toLowerCase() ?? 'driving')
          .toSet();

      final Map<String, Map<String, dynamic>> modeDataMap = {};
      final futures = modesNeeded.map((mode) async {
        try {
          final data = await _fetchDistanceAndDuration(
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            dropOffLat: dropOffLat,
            dropOffLng: dropOffLng,
            mode: mode,
          );
          if (data.isNotEmpty) modeDataMap[mode] = data;
        } catch (e) {
          //
        }
      }).toList();

      await Future.wait(futures);

      List<Map<String, dynamic>> vehicleFares = [];
      double maxDistance = 0.0;

      if (modeDataMap.isEmpty) {
        emit(state.copyWith(error: 'Failed to fetch distance data'));
        return;
      }

      for (int i = 0; i < vehicleCategories.length; i++) {
        final category = vehicleCategories[i];
        final mode = category.mode?.toLowerCase() ?? 'driving';
        final data = modeDataMap[mode];

        if (data == null || data.isEmpty) {
          continue;
        }

        final double distanceInKm = data['distance'] ?? 0.0;
        String duration = data['duration'] ?? "";

        int extraMinutes = (i % 2 == 0) ? 2 : 5;

        int originalMinutes = 0;
        final durationParts = duration.split(" ");
        for (int j = 0; j < durationParts.length; j++) {
          if (durationParts[j].contains("min")) {
            originalMinutes = int.tryParse(durationParts[j - 1]) ?? 0;
            break;
          }
        }

        final newMinutes = originalMinutes + extraMinutes;
        if (originalMinutes > 0) {
          duration = duration.replaceFirst(
            RegExp(r'\d+\s*min'),
            '$newMinutes min',
          );
        }

        final farePerKm = double.tryParse(category.farePerKm.toString()) ?? 0.0;
        final fare = (distanceInKm * farePerKm).ceil();

       vehicleFares.add({
          "vehicleName": category.name,
          "fare": fare.toString(),
          "distance": distanceInKm.toStringAsFixed(2),
          "duration": duration,
          "image": category.image,
          "id": category.id,
          // ignore: use_build_context_synchronously
          "serviceTypeId": context
                                  .read<ServiceTypeId>().state.value ?? '',
        });

        maxDistance = maxDistance < distanceInKm ? distanceInKm : maxDistance;
      }

      if (vehicleFares.isEmpty) {
        emit(state.copyWith(error: 'No vehicle fares calculated'));
        return;
      }

      emit(state.copyWith(
          vehicleFares: vehicleFares, distance: maxDistance, error: null));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to calculate fares: $e'));
    }
  }

  Future<Map<String, dynamic>> _fetchDistanceAndDuration({
    required String pickupLat,
    required String pickupLng,
    required String dropOffLat,
    required String dropOffLng,
    required String mode,
  }) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=$pickupLat,$pickupLng'
        '&destination=$dropOffLat,$dropOffLng'
        '&mode=$mode'
        '&alternatives=true'
        '&departure_time=now'
        '&traffic_model=best_guess'
        '&key=${Config.googleKey}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] != 'OK') return {};

      final routes = data['routes'];
      if (routes != null && routes.isNotEmpty) {
        double? shortestDistance;
        Map<String, dynamic>? bestRoute;

        for (var route in routes) {
          final legs = route['legs'];
          if (legs != null && legs.isNotEmpty) {
            
            final durationTrafficValue = legs[0]['duration_in_traffic']
                    ?['value'] ??
                legs[0]['duration']['value'];  

                  
            if (shortestDistance == null ||
                durationTrafficValue < shortestDistance) {
              shortestDistance = durationTrafficValue.toDouble();
              bestRoute = legs[0];
            }
          }
        }

        if (bestRoute != null) {
          final distanceValue = bestRoute['distance']['value'];
          final durationText = bestRoute['duration_in_traffic']?['text'] ??
              bestRoute['duration']['text'];
          final distanceInKm = distanceValue / 1000;

          return {
            "distance": distanceInKm,
            "duration": durationText,
          };
        }
      }
    }

    return {};
  }

  void removeDistanceState() {
    emit(GetDistanceRouteState(vehicleFares: const []));
  }
}


