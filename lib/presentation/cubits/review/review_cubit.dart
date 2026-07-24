import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/review_repository.dart';

abstract class ReviewState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewSuceess extends ReviewState {
  @override
  List<Object?> get props => [];
}

class ReviewFailure extends ReviewState {
  final String? paymentMessage;
  ReviewFailure({this.paymentMessage});
  @override
  List<Object?> get props => [];
}

class ReviewCubit extends Cubit<ReviewState> {
  ReviewRepository reviewRepository;
  ReviewCubit(this.reviewRepository) : super(ReviewInitial());

  Future<void> submitReview(
      {required BuildContext context,
      required String bookingId,
      required String rating,
      required String message}) async {
    try {
      emit(ReviewLoading());

      var response = await reviewRepository.submitReview(
          message: message,
          context: context,
          bookingId: bookingId,
          rating: rating);
      if (response["status"] == 200) {
        emit(ReviewSuceess());

      } else {
        emit(ReviewFailure(paymentMessage: response["error"]));
      }
    } catch (err) {
      emit(ReviewFailure(paymentMessage: "$err"));

    }
  }

  void resetState() {
    emit(ReviewInitial());
  }
}


