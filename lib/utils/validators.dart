/// Utility class for input validation
class Validators {
  /// Validates phone number format
  /// Expects format: +[country code][number] (e.g., +1234567890)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any spaces or special characters except +
    final cleanedValue = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it starts with + and has at least 10 digits after country code
    final RegExp phoneRegex = RegExp(r'^\+[1-9]\d{9,14}$');

    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid phone number with country code (e.g., +1234567890)';
    }

    return null;
  }

  /// Validates OTP format (6 digits)
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Verification code is required';
    }

    if (value.length != 6) {
      return 'Verification code must be 6 digits';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Verification code must contain only numbers';
    }

    return null;
  }

  /// Validates required fields
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Formats phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    // Remove any existing formatting
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+')) {
      return cleaned;
    } else if (cleaned.isNotEmpty) {
      return '+$cleaned';
    }

    return phoneNumber;
  }
}
