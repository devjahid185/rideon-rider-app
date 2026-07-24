import 'package:flutter/cupertino.dart';

String? validateEmail(String value, BuildContext context) {
  if (value.isEmpty ||
      !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Please enter a valid email';
  }
  return null;
}

bool isValidName(String value) {
  if (value.isEmpty) {
    return false;
  }
  if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value)) {
    return false;
  }
  return true;
}

String? validatePassword(String value, BuildContext context) {

  if (value.isEmpty) {
    return 'Please enter valid Password';
  }

  return null;
}

String? validatesPassword(String? value, BuildContext context) {
  String patternUppercase = r'(?=.*?[A-Z])';
  String patternLowercase = r'(?=.*?[a-z])';
  String patternDigits = r'(?=.*?[0-9])';
  String patternSpecialCharacter = r'(?=.*?[!@#\$&*~])';
  String patternMinLength = r'.{8,}';

  RegExp regexUppercase = RegExp(patternUppercase);
  RegExp regexLowercase = RegExp(patternLowercase);
  RegExp regexDigits = RegExp(patternDigits);
  RegExp regexSpecialCharacter = RegExp(patternSpecialCharacter);
  RegExp regexMinLength = RegExp(patternMinLength);

  String errorMessage = 'Password must have:';
  bool isValid = true;

  if (!regexUppercase.hasMatch(value!)) {
    isValid = false;
    errorMessage += '\n- ' 'At least 1 uppercase letter';
  }
  if (!regexLowercase.hasMatch(value)) {
    isValid = false;
    errorMessage += '\n- ' 'At least 1 lowercase letter';
  }
  if (!regexDigits.hasMatch(value)) {
    isValid = false;
    errorMessage += '\n- ' 'At least 1 number';
  }
  if (!regexSpecialCharacter.hasMatch(value)) {
    isValid = false;
    errorMessage += '\n- ${'At least 1 special character'} (!@#\$&*~)';
  }
  if (!regexMinLength.hasMatch(value)) {
    isValid = false;
    errorMessage += '\n- ' 'Minimum 8 characters';
  }
  return isValid ? null : errorMessage;
}

class ValidationService {
  static bool isNumeric(String value) {
    return double.tryParse(value) != null;
  }

  static bool isNotEmpty(String value) {
    return value.isNotEmpty;
  }

  static void validateAndNavigate(
      {final String? title,
      final String? description,
      final Function(String)? showErrorToastMessage,
      final Function()? navigateToNextScreen,
      BuildContext? context}) {
    if (title.toString() == "") {
      showErrorToastMessage!("The items name field is required");
      return;
    }
    if (description.toString() == "") {
      showErrorToastMessage!("The description field is required");
      return;
    }

    navigateToNextScreen!();
  }
}






