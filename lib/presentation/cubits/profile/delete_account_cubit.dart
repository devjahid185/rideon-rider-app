import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/profile_repository.dart';


abstract class DeleteAccountState {}

class DeleteAccountInitial extends DeleteAccountState {}

class DeleteAccountLoading extends DeleteAccountState {}

class DeleteAccountSuccess extends DeleteAccountState {
  final String message;
  DeleteAccountSuccess(this.message);
}

class DeleteAccountFailed extends DeleteAccountState {
  final String error;
  DeleteAccountFailed(this.error);
}

class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  final ProfileRepository userProfileRepository;

  DeleteAccountCubit(this.userProfileRepository)
      : super(DeleteAccountInitial());

  Future<void> deleteAccount(BuildContext context) async {
    emit(DeleteAccountLoading());
    try {
      final response = await userProfileRepository.deleteAccount();
      if (response["status"] == 200) {
        emit(DeleteAccountSuccess(response["message"] ?? "Account deleted"));
      } else {
        emit(DeleteAccountFailed(response["error"] ?? "Something went wrong"));
      }
    } catch (e) {
      emit(DeleteAccountFailed(e.toString()));
    }
  }
}


