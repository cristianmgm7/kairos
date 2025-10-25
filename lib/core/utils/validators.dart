class Validators {
  Validators._();

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 8 && password.length <= 128;
  }

  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s-()]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute;
    } catch (e) {
      return false;
    }
  }
}
