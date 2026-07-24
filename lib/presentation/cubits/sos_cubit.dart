import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/domain/entities/sos_data.dart';

import '../../../data/repositories/profile_repository.dart';


abstract class SosState {}

class SosInitial extends SosState {}

class SosLoading extends SosState {}

class SosSuccess extends SosState {
  final SosData sosData;
  SosSuccess(this.sosData);
}

class SosFailed extends SosState {
  final String error;
  SosFailed(this.error);
}

class SosCubit extends Cubit<SosState> {
  final ProfileRepository userProfileRepository;

  SosCubit(this.userProfileRepository) : super(SosInitial());

  Future<void> getSosList(BuildContext context) async {
    emit(SosLoading());
    try {
      final response = await userProfileRepository.getSosData(postData: {});

      if (response["status"] == 200) {

        /// Fix: send ONLY response["data"] into SosData
        SosData sosData = SosData.fromJson(response["data"]);

        emit(SosSuccess(sosData));

      } else {
        emit(SosFailed(response["error"] ?? "Something went wrong"));
      }
    } catch (e) {
      emit(SosFailed(e.toString()));
    }
  }
}


