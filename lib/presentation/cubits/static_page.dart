import 'package:ride_on/domain/entities/static_data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/profile_repository.dart';

abstract class StaticPageState extends Equatable {
  @override
  List<Object?> get props => [];
}

class StaticPageInitial extends StaticPageState {}

class StaticPageLoading extends StaticPageState {}

class StaticPageSuccess extends StaticPageState {
  final StaticModel staticModel;

  StaticPageSuccess(this.staticModel);

  @override
  List<Object?> get props => [staticModel];
}

class StaticPageFailure extends StaticPageState {
  final String error;

  StaticPageFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class StaticPageCubits extends Cubit<StaticPageState> {
  final ProfileRepository repository;
  StaticPageCubits(this.repository) : super(StaticPageInitial());
  Future<void> getStaticData(BuildContext context, {String? data}) async {
    try {
      emit(StaticPageLoading());
      final response = await repository.getStaticPage(context, "$data");
      if (response['status'] == 200) {
        emit(StaticPageSuccess(StaticModel.fromJson(response)));
      } else {
        emit(StaticPageFailure(response['error']));
      }
    } catch (e) {
      emit(StaticPageFailure("Something went wrong"));
    }
  }
}


