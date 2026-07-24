// ignore_for_file: depend_on_referenced_packages

import 'package:ride_on/domain/entities/check_email.dart';
import 'package:ride_on/data/repositories/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

abstract class ChangeEmailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChangeEmailInitial extends ChangeEmailState {}

class ChangeEmailLoading extends ChangeEmailState {}

class ChangeEmailSuccess extends ChangeEmailState {
  final CheckEmail checkEmail;

  ChangeEmailSuccess(this.checkEmail);

  @override
  List<Object?> get props => [checkEmail];
}

class ChangeEmailFailure extends ChangeEmailState {
  final String error;

  ChangeEmailFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class ChangeEmailCubits extends Cubit<ChangeEmailState> {
  final AuthRepository repository;
  ChangeEmailCubits(this.repository) : super(ChangeEmailInitial());
  Future<void> changeEmail(String email) async {
    try {
      emit(ChangeEmailLoading());
      final response = await repository.changeEmail(email: email);
      if (response['status'] == 200) {
        emit(ChangeEmailSuccess(CheckEmail.fromJson(response)));
      } else {
        emit(ChangeEmailFailure(response['error']));
      }
    } catch (e) {
      emit(ChangeEmailFailure("Something went wrong"));
    }
  }
}


