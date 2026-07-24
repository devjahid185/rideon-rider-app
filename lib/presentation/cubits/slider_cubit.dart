import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/domain/entities/Sliders_data.dart';

import '../../../data/repositories/profile_repository.dart';

abstract class SlidersState {}

class SlidersInitial extends SlidersState {}

class SlidersLoading extends SlidersState {}

class SlidersSuccess extends SlidersState {
  final SliderResponse sliderResponse;
  SlidersSuccess(this.sliderResponse);
}

class SlidersFailed extends SlidersState {
  final String error;
  SlidersFailed(this.error);
}

class SlidersCubit extends Cubit<SlidersState> {
  final ProfileRepository userProfileRepository;

  SlidersCubit(this.userProfileRepository) : super(SlidersInitial());

  Future<void> getSlidersList(BuildContext context) async {
    emit(SlidersLoading());
    try {
      final response = await userProfileRepository.getSliders(postData: {});
      debugPrint(
          "[SliderDebug] sliders response status=${response["status"]} keys=${response.keys.toList()}");

      if (response["status"] == 200) {
        // / Fix: send ONLY response["data"] into SlidersData
        SliderResponse sliderResponse = SliderResponse.fromJson(response);
        debugPrint(
            "[SliderDebug] sliders loaded count=${sliderResponse.data?.length ?? 0}");

        emit(SlidersSuccess(sliderResponse));
      } else {
        debugPrint(
            "[SliderDebug] sliders failed response=${response.toString()}");
        emit(SlidersFailed(response["error"] ?? "Something went wrong"));
      }
    } catch (e) {
      debugPrint("[SliderDebug] sliders exception=$e");
      emit(SlidersFailed(e.toString()));
    }
  }
}


