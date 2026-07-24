
// ignore_for_file: use_build_context_synchronously

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../core/extensions/workspace.dart';
import '../../core/services/data_store.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/general_data.dart';



abstract class GeneralState extends Equatable{
  @override
  List<Object?> get props => [];
}

class GeneralInitial extends GeneralState{}
class GeneralLoading  extends GeneralState{

}
class GeneralSuccess  extends GeneralState{
  final  GeneralDataModel generalDataModel;

  GeneralSuccess(this.generalDataModel,  );
  @override
  List<Object?> get props => [generalDataModel];
}
class GeneralFailed  extends GeneralState{
  final String error;


  GeneralFailed(this.error  );
  @override
  List<Object?> get props => [error, ];

}



class GeneralCubit extends Cubit<GeneralState>{
  final ProfileRepository repositories;
  GeneralCubit(this.repositories):super(GeneralInitial());

  Future<void> fetchGeneralSetting(BuildContext context)async{


    try {
      final response =await repositories.getGeneralData(postData: {});
      if (response['status'] == 200) {
        box.put("generalSettings", response);
        GeneralDataModel generalModel=GeneralDataModel.fromJson(response);
        currency=generalModel.data?.metaData?.generalDefaultCurrency??"";

        box.put("currency", currency);


        context.read<FirebaseUpdateIntervalCubit>().update(generalModel.data?.metaData?.firebaseUpdateInterval??"");
        context.read<LocationAccuracyThresholdCubit>().update(generalModel.data?.metaData?.locationAccuracyThreshold??"3");
        context.read<BackgroundLocationIntervalCubit>().update(generalModel.data?.metaData?.backgroundLocationInterval??"");
        context.read<UseGoogleBeforePickupCubit>().update(generalModel.data?.metaData?.useGoogleBeforePickup??"");
        context.read<DriverSearchIntervalCubit>().update(generalModel.data?.metaData?.driverSearchInterval??"60");
        context.read<UseGoogleAfterPickupCubit>().update(generalModel.data?.metaData?.useGoogleAfterPickup??"");
        context.read<UseGoogleSourceDestination>().update(generalModel.data?.metaData?.useGoogleSourceDestination??"");
        context.read<MinimumHitsTimeToUpdateTime>().update(generalModel.data?.metaData?.minimumHitsTime??"");
        context.read<LastActiveApp>().update(generalModel.data?.metaData?.lastActiveApp ?? "");

        box.put("backgroundUpdatedLocation", context.read<BackgroundLocationIntervalCubit>().state.value);
        box.put("firebaseUpdatedLocation", context.read<FirebaseUpdateIntervalCubit>().state.value);

        debugPrint("FirebaseUpdateIntervalCubit ${context.read<FirebaseUpdateIntervalCubit>().state.value}");
        debugPrint("LocationAccuracyThresholdCubit ${context.read<LocationAccuracyThresholdCubit>().state.value}");
        debugPrint("BackgroundLocationIntervalCubit ${context.read<BackgroundLocationIntervalCubit>().state.value}");
        debugPrint("UseGoogleBeforePickupCubit ${context.read<UseGoogleBeforePickupCubit>().state.value}");
        debugPrint("DriverSearchIntervalCubit ${context.read<DriverSearchIntervalCubit>().state.value}");
        debugPrint("UseGoogleAfterPickupCubit ${context.read<UseGoogleAfterPickupCubit>().state.value}");
        debugPrint("UseGoogleSourceDestination ${context.read<UseGoogleSourceDestination>().state.value}");
        debugPrint("MinimumHitsTimeToUpdateTime ${context.read<MinimumHitsTimeToUpdateTime>().state.value}");

        emit(GeneralSuccess(GeneralDataModel.fromJson(response)));




      }else{
        emit(GeneralFailed(response['error']));

      }
    }   catch (e) {

      GeneralFailed("Something went wrong");
    }





  }





}

abstract class SimpleState<T> extends Equatable {
  final T value;
  const SimpleState(this.value);

  @override
  List<Object?> get props => [value];
}

class SimpleInitial<T> extends SimpleState<T> {
  const SimpleInitial(super.value);
}

class FirebaseUpdateIntervalCubit extends Cubit<SimpleState<String?>> {
  FirebaseUpdateIntervalCubit() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}
class LocationAccuracyThresholdCubit extends Cubit<SimpleState<String?>> {
  LocationAccuracyThresholdCubit() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}
class BackgroundLocationIntervalCubit extends Cubit<SimpleState<String?>> {
  BackgroundLocationIntervalCubit() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}
class DriverSearchIntervalCubit extends Cubit<SimpleState<String?>> {
  DriverSearchIntervalCubit() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}
class UseGoogleBeforePickupCubit extends Cubit<SimpleState<String?>> {
  UseGoogleBeforePickupCubit() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}
class UseGoogleAfterPickupCubit extends Cubit<SimpleState<String?>> {
  UseGoogleAfterPickupCubit() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}

class MinimumHitsTimeToUpdateTime extends Cubit<SimpleState<String?>> {
  MinimumHitsTimeToUpdateTime() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}
class UseGoogleSourceDestination extends Cubit<SimpleState<String?>> {
  UseGoogleSourceDestination() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}
class LastActiveApp extends Cubit<SimpleState<String?>> {
  LastActiveApp() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}
class ServiceTypeId extends Cubit<SimpleState<String?>> {
  ServiceTypeId() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}


