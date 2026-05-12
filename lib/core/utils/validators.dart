import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return AppStrings.invalidEmail;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 8) return AppStrings.passwordTooShort;
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value != original) return AppStrings.passwordsDoNotMatch;
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final urlRegex = RegExp(r'^https?://.+\..+');
    if (!urlRegex.hasMatch(value.trim())) return 'Please enter a valid URL';
    return null;
  }
}
