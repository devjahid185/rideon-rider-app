import 'package:ride_on/domain/entities/history_data.dart';
import 'package:ride_on/data/repositories/history_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class HistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistorySuccess extends HistoryState {
  final HistoryModel? historyModel;
  final List<Bookings>? bookings;

  HistorySuccess({this.historyModel, this.bookings});

  @override
  List<Object?> get props => [historyModel, bookings];
}

class HistoryError extends HistoryState {
  final String? errorMessage;
  HistoryError({this.errorMessage});
  @override
  List<Object?> get props => [errorMessage];
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryRepository historyRepository;
  HistoryCubit(this.historyRepository) : super(HistoryInitial());

  Future<void> getHistoryData({
    required BuildContext context,
    required Map<String, dynamic> bookingKeyMap,
  }) async {
    // try {
      emit(HistoryLoading());
      var response = await historyRepository.getHistoryData(
          context: context, bookingKeyMap: bookingKeyMap);
      if (response["status"] == 200) {
        HistoryModel historyModel = HistoryModel.fromJson(response);

        emit(HistorySuccess(
            bookings: historyModel.data!.bookings, historyModel: historyModel));
      } else {
        emit(HistoryError(errorMessage: response["error"]));
      }
    // } catch (error) {
     
    //   emit(HistoryError(errorMessage: "$error"));
    // }
  }

  void resetHistoryData() {
    emit(HistoryInitial());
  }
}


