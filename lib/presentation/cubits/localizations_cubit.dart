import 'package:ride_on/core/services/data_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LanguageState {}

class LanguageInitial extends LanguageState {}

class LanguageLoader extends LanguageState {
  final dynamic language;
  LanguageLoader(this.language);
}

class LanguageLoadFail extends LanguageState {
  final dynamic error;
  LanguageLoadFail({required this.error});
}

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(LanguageInitial());

  void loadCurrentLanguage() {
    var language = lanBox.get("lCode");
    emit(LanguageLoader(language));
  }

  void changeLanguage(dynamic language) {
    emit(LanguageLoader(language)); // Emit the new language
  }

  // Get the language code
  dynamic currentLanguageCode() {
    return lanBox.get("lCode");
  }
}
class LCodeCubit extends Cubit<String> {
  LCodeCubit() : super(lanBox.get("lCode")??'en'); // default language code

  void changeLanguage(String code) => emit(code);
}


