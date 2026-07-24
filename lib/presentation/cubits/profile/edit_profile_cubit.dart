import 'package:ride_on/domain/entities/login_data.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/profile_repository.dart';

abstract class UpdateProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateProfileInitial extends UpdateProfileState {}

class UpdateProfileLoading extends UpdateProfileState {}

class UpdateProfileFailed extends UpdateProfileState {
  final String error;

  UpdateProfileFailed(this.error);
  @override

  List<Object?> get props => [error];
}

class UpdateProfileSuccess extends UpdateProfileState {
  final LoginModel loginModel;

  UpdateProfileSuccess(this.loginModel);
  @override

  List<Object?> get props => [loginModel];
}

class UpdateProfileImageSuccess extends UpdateProfileState {
  final String imageUrl;

  UpdateProfileImageSuccess(this.imageUrl);
  @override

  List<Object?> get props => [imageUrl];
}

class UpdateProfileCubit extends Cubit<UpdateProfileState> {
  final ProfileRepository repository;

  UpdateProfileCubit(this.repository) : super(UpdateProfileInitial());

  Future<void> updateProfileMethod(
      {required Map<String, dynamic> postData}) async {
    try {
      emit(UpdateProfileLoading());
      final response = await repository.editProfile(postData: postData);

      if (response["status"] == 200) {
        LoginModel loginModel = LoginModel.fromJson(response);
        emit(UpdateProfileSuccess(loginModel));
      } else {
        emit(UpdateProfileFailed(response["error"]));
      }
    } catch (e) {
      emit(UpdateProfileFailed("something went wrong"));
    }
  }

  Future<void> uploadProfileImage(
      {required Map<String, dynamic> postData}) async {
    try {
      emit(UpdateProfileLoading());
      final response = await repository.uploadProfileImage(postData: postData);

      if (response["status"] == 200) {
        emit(UpdateProfileImageSuccess(response["data"]["profile_image_url"]));
      } else {
        emit(UpdateProfileFailed(response["error"]));
      }
    } catch (e) {
      emit(UpdateProfileFailed("something went wrong"));
    }
  }

  void clear() {
    emit(UpdateProfileInitial());
  }
}

class NameCubit extends Cubit<String> {
  NameCubit() : super("");

  void updateName(String newName) {
    emit(newName);
  }

  void removeName() {
    emit("");
  }
}

class GenderCubit extends Cubit<String> {
  GenderCubit() : super("");

  void genderUpdate({String? gender}) {
    emit(gender!);
  }

  void genderResetState() {
    emit("");
  }
}

class EmailCubit extends Cubit<String> {
  EmailCubit() : super("");

  void updateEmail(String newEmail) {
    emit(newEmail);
  }

  void emailReset() {
    emit("");
  }
}

class MyImageCubit extends Cubit<String> {
  MyImageCubit() : super("");

  void updateMyImage(String newImage) {
    emit(newImage);
  }

  void imageReset() {
    emit("");
  }
}

class PhoneCubit extends Cubit<String> {
  PhoneCubit() : super("");

  void updatePhone(String newPhone) {
    emit(newPhone);
  }

  void phoneReset() {
    emit("");
  }
}


