class Validators {
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phoneNumber = value.trim();

    // Basic phone number validation - should start with + and have at least 10 digits
    final phoneRegex = RegExp(r'^\+[1-9]\d{9,14}$');

    if (!phoneRegex.hasMatch(phoneNumber)) {
      return 'Please enter a valid phone number with country code (e.g., +1234567890)';
    }

    return null;
  }

  static String? validateOTP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Verification code is required';
    }

    final otp = value.trim();

    if (otp.length != 6) {
      return 'Verification code must be 6 digits';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'Verification code must contain only numbers';
    }

    return null;
  }

  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Ensure it starts with +
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    return cleaned;
  }
}
