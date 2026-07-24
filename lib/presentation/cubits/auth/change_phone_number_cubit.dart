import 'package:ride_on/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/check_mobile.dart';

abstract class ChangePhoneState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChangePhoneInitial extends ChangePhoneState {}

class ChangePhoneLoading extends ChangePhoneState {}

class ChangePhoneSuccess extends ChangePhoneState {
  final CheckMobileModel checkMobileModel;

  ChangePhoneSuccess(
    this.checkMobileModel,
  );

  @override
  List<Object?> get props => [
        checkMobileModel,
      ];
}

class ChangePhoneFailure extends ChangePhoneState {
  final String error;

  ChangePhoneFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class ChangePhoneCubits extends Cubit<ChangePhoneState> {
  final AuthRepository repository;
  ChangePhoneCubits(this.repository) : super(ChangePhoneInitial());
  Future<void> changePhone({
    String? phone,
    String? phoneCountry,
    String? defaultCuntry,
  }) async {
    try {
      emit(ChangePhoneLoading());
      final response = await repository.changePhone(
          phone: phone ?? "",
          defaultCode: defaultCuntry ?? "",
          countryCode: phoneCountry ?? "");
      if (response['status'] == 200) {
        emit(ChangePhoneSuccess(CheckMobileModel.fromJson(response)));
      } else {
        emit(ChangePhoneFailure(response['error']));
      }
    } catch (e) {
      emit(ChangePhoneFailure("Something went wrong"));
    }
  }
}


