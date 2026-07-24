import 'package:ride_on/domain/entities/catrgory.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/vehicle_repository.dart';

abstract class GetVehicleDataState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetVehicleInitial extends GetVehicleDataState {}

class GetVehicleLoading extends GetVehicleDataState {}

class GetVehicleSuccess extends GetVehicleDataState {
  final List<ItemTypes> itemTypes;
  final String? selectedId;

  GetVehicleSuccess(this.itemTypes, {this.selectedId});
  @override
  List<Object?> get props => [itemTypes, selectedId];
}
class GetItemTypeSuccess extends GetVehicleDataState {
  final List<ItemTypes> itemTypes;
  final String? selectedId;

  GetItemTypeSuccess(this.itemTypes, {this.selectedId});
  @override
  List<Object?> get props => [itemTypes, selectedId];
}

class GetVehcileFailure extends GetVehicleDataState {
  final String error;
  GetVehcileFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class GetVehicleDataCubit extends Cubit<GetVehicleDataState> {
  final VehicleRepository vehicleRepository;
  GetVehicleDataCubit(this.vehicleRepository) : super(GetVehicleInitial());

  Future<void> getAllCategories() async {
    try {
      emit(GetVehicleLoading());
      final response = await vehicleRepository.getCategories();
      if (response["status"] == 200) {
        GetAllCategories getAllCategories = GetAllCategories.fromJson(response);

        emit(GetVehicleSuccess(getAllCategories.data!.itemTypes!));
      } else {
        emit(GetVehcileFailure(response["error"] ?? "Something went wrong"));
      }
    } catch (e) {
      emit(GetVehcileFailure("Something went wrong $e"));
    }
  }
  Future<void> getItemTypesByService(String id) async {
    try {
      emit(GetVehicleLoading());
      final response = await vehicleRepository.getItemTypesByService(id);
      if (response["status"] == 200) {
        ItemTypeResponse itemTypeResponse = ItemTypeResponse.fromJson(response);

        emit(GetItemTypeSuccess(itemTypeResponse.data!.itemTypes!));
      } else {
        emit(GetVehcileFailure(response["error"] ?? "Something went wrong"));
      }
    } catch (e) {
      emit(GetVehcileFailure("Something went wrong $e"));
    }
  }

  void resetState() {
    emit(GetVehicleInitial());
  }
}

class VehicleDataUpdate extends Equatable {
  final int vehicleSelectedId;
  final String selectedDriverId;

  const VehicleDataUpdate({
    this.vehicleSelectedId = 0,
    this.selectedDriverId = "",
  });
  VehicleDataUpdate copyWith({
    int? vehicleSelectedId,
    String? selectedDriverId,
  }) {
    return VehicleDataUpdate(
      selectedDriverId: selectedDriverId ?? this.selectedDriverId,
      vehicleSelectedId: vehicleSelectedId ?? this.vehicleSelectedId,
    );
  }

  @override
  List<Object?> get props => [
        vehicleSelectedId,
        selectedDriverId,
      ];
}

class VehicleDataUpdateCubit extends Cubit<VehicleDataUpdate> {
  VehicleDataUpdateCubit() : super(const VehicleDataUpdate());

  void updateVehicleTypeSelectedId(
    int? vehicleSelectedId,
  ) {
    emit(state.copyWith(
      vehicleSelectedId: vehicleSelectedId,
    ));
  }

  void updateDriverdId({String? selectedDriverID}) {
    emit(state.copyWith(selectedDriverId: selectedDriverID));
  }

  void resetState() {
    emit(const VehicleDataUpdate());
  }
}


