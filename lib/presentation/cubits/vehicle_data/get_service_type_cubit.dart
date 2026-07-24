import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/domain/entities/service_type.dart';

import '../../../data/repositories/vehicle_repository.dart';

abstract class GetServiceTypeDataState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetServiceTypeInitial extends GetServiceTypeDataState {}

class GetServiceTypeLoading extends GetServiceTypeDataState {}

class GetServiceTypeSuccess extends GetServiceTypeDataState {
  final List<ServiceType> itemTypes;
  final String? selectedId;

  GetServiceTypeSuccess(this.itemTypes, {this.selectedId});
  @override
  List<Object?> get props => [itemTypes, selectedId];
}

class GetVehcileFailure extends GetServiceTypeDataState {
  final String error;
  GetVehcileFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class GetServiceTypeDataCubit extends Cubit<GetServiceTypeDataState> {
  final VehicleRepository vehicleRepository;
  GetServiceTypeDataCubit(this.vehicleRepository) : super(GetServiceTypeInitial());

  Future<void> getServiceType() async {
    try {
      emit(GetServiceTypeLoading());
      final response = await vehicleRepository.getServiceType();
      if (response["status"] == 200) {
        ServiceTypeResponse serviceTypeResponse = ServiceTypeResponse.fromJson(response);

        emit(GetServiceTypeSuccess(serviceTypeResponse.data!.serviceTypes!));
      } else {
        emit(GetVehcileFailure(response["error"] ?? "Something went wrong"));
      }
    } catch (e) {
      emit(GetVehcileFailure("Something went wrong $e"));
    }
  }

  void resetState() {
    emit(GetServiceTypeInitial());
  }
}


