import 'dart:async';
import 'package:get/get.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import '../services/feedback_service.dart';
import '../services/logging_service.dart';
import '../utils/error_handler.dart';
import '../app/routes/app_routes.dart';
import '../bindings/controller_binding.dart';

/// Controller for managing authentication state and operations
class AuthController extends BaseController {
  final AuthService _authService;

  // Reactive variables for authentication state
  final RxBool _isAuthenticated = false.obs;
  final RxBool _isLoading = false.obs;
  final RxString _phoneNumber = ''.obs;
  final Rxn<User> _currentUser = Rxn<User>();
  final RxString _verificationId = ''.obs;
  final RxString _errorMessage = ''.obs;

  // Completer to signal when initial auth check is done
  final Completer<void> _authReadyCompleter = Completer<void>();

  // Getters for reactive variables
  bool get isAuthenticated => _isAuthenticated.value;
  bool get isLoading => _isLoading.value;
  String get phoneNumber => _phoneNumber.value;
  User? get currentUser => _currentUser.value;
  String get verificationId => _verificationId.value;
  String get errorMessage => _errorMessage.value;

  // Observable getters for reactive programming
  RxBool get isAuthenticatedObs => _isAuthenticated;
  RxBool get isLoadingObs => _isLoading;
  RxString get phoneNumberObs => _phoneNumber;
  Rxn<User> get currentUserObs => _currentUser;

  /// Future that completes when the initial authentication check is finished
  Future<void> get onAuthReady => _authReadyCompleter.future;

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  /// Initialize authentication and listen for changes
  void _initializeAuth() {
    LoggingService.info(
      '🚀 Initializing authentication controller',
      tag: 'AuthController',
    );
    checkAuthState();
    _listenToAuthStateChanges();
    LoggingService.info(
      '✅ Authentication controller initialization completed',
      tag: 'AuthController',
    );
  }

  /// Listen to authentication state changes from Firebase
  void _listenToAuthStateChanges() {
    LoggingService.info(
      '🔄 Setting up auth state changes listener',
      tag: 'AuthController',
    );

    _authService.authStateChanges.listen((User? user) {
      LoggingService.info(
        '🔄 Auth state change received',
        tag: 'AuthController',
        data: {
          'hasUser': user != null,
          'userId': user?.uid,
          'phoneNumber': user?.phoneNumber,
          'previousAuthState': _isAuthenticated.value,
        },
      );

      _currentUser.value = user;
      _isAuthenticated.value = user != null;

      if (user != null) {
        _phoneNumber.value = user.phoneNumber;
        LoggingService.info(
          '✅ User authenticated via state change',
          tag: 'AuthController',
          data: {'userId': user.uid, 'phoneNumber': user.phoneNumber},
        );
      } else {
        LoggingService.info(
          '🚪 User signed out via state change',
          tag: 'AuthController',
        );
      }

      // Signal that auth check is complete
      if (!_authReadyCompleter.isCompleted) {
        _authReadyCompleter.complete();
        LoggingService.info(
          '✅ Auth ready completer completed',
          tag: 'AuthController',
        );
      }
    });
  }

  /// Check current authentication state on app initialization
  void checkAuthState() {
    LoggingService.info(
      '🔍 Checking current authentication state',
      tag: 'AuthController',
      data: {'timestamp': DateTime.now().toIso8601String()},
    );

    try {
      final User? user = _authService.getCurrentUser();

      LoggingService.info(
        '📋 Auth state check completed',
        tag: 'AuthController',
        data: {
          'hasUser': user != null,
          'userId': user?.uid,
          'phoneNumber': user?.phoneNumber,
        },
      );

      _currentUser.value = user;
      _isAuthenticated.value = user != null;

      if (user != null) {
        _phoneNumber.value = user.phoneNumber;
        LoggingService.info(
          '✅ User is authenticated on startup',
          tag: 'AuthController',
          data: {'userId': user.uid, 'phoneNumber': user.phoneNumber},
        );
      } else {
        LoggingService.info(
          '👤 No authenticated user found on startup',
          tag: 'AuthController',
        );
      }
    } catch (e) {
      LoggingService.error(
        '❌ Failed to check authentication state',
        tag: 'AuthController',
        error: e,
        data: {'errorType': e.runtimeType.toString()},
      );
      _handleError('Failed to check authentication state: $e');
    }
  }

  /// Send OTP to the provided phone number
  Future<void> sendOTP(String phoneNumber) async {
    LoggingService.info(
      '📞 Starting OTP send process',
      tag: 'AuthController',
      data: {
        'phoneNumber': phoneNumber,
        'phoneNumberLength': phoneNumber.length,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (phoneNumber.isEmpty) {
      LoggingService.warning(
        '❌ Empty phone number provided',
        tag: 'AuthController',
      );
      FeedbackService.showValidationError('Please enter a valid phone number');
      return;
    }

    LoggingService.info(
      '🔄 Setting loading state and clearing errors',
      tag: 'AuthController',
    );
    _setLoading(true);
    _clearError();

    try {
      LoggingService.info(
        '📡 Calling auth service to send OTP',
        tag: 'AuthController',
        data: {'phoneNumber': phoneNumber},
      );

      final String verificationId = await _authService.sendOTP(phoneNumber);

      LoggingService.info(
        '✅ OTP sent successfully',
        tag: 'AuthController',
        data: {'verificationId': verificationId, 'phoneNumber': phoneNumber},
      );

      _verificationId.value = verificationId;
      _phoneNumber.value = phoneNumber;

      FeedbackService.showAuthSuccess('OTP sent successfully to $phoneNumber');

      LoggingService.info(
        '🧭 Navigating to OTP verification screen',
        tag: 'AuthController',
        data: {'phoneNumber': phoneNumber, 'verificationId': verificationId},
      );

      // Navigate to OTP verification screen
      NavigationService.toOTPVerification(
        phoneNumber: phoneNumber,
        verificationId: verificationId,
      );
    } on AuthException catch (e) {
      LoggingService.error(
        '❌ Auth exception during OTP send',
        tag: 'AuthController',
        error: e,
        data: {'phoneNumber': phoneNumber, 'authExceptionMessage': e.message},
      );
      ErrorHandler.handleAuthError(e, context: 'Send OTP');
    } catch (e) {
      LoggingService.error(
        '❌ Unexpected error during OTP send',
        tag: 'AuthController',
        error: e,
        data: {
          'phoneNumber': phoneNumber,
          'errorType': e.runtimeType.toString(),
        },
      );
      _handleError('Failed to send OTP. Please try again.');
    } finally {
      LoggingService.info('🔄 Clearing loading state', tag: 'AuthController');
      _setLoading(false);
    }
  }

  /// Verify OTP with the verification ID
  Future<void> verifyOTP(String otp) async {
    LoggingService.info(
      '🔐 Starting OTP verification process',
      tag: 'AuthController',
      data: {
        'otpLength': otp.length,
        'hasVerificationId': _verificationId.value.isNotEmpty,
        'verificationId': _verificationId.value,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (otp.isEmpty) {
      LoggingService.warning('❌ Empty OTP provided', tag: 'AuthController');
      FeedbackService.showValidationError('Please enter the verification code');
      return;
    }

    if (_verificationId.value.isEmpty) {
      LoggingService.error(
        '❌ No verification ID available',
        tag: 'AuthController',
        data: {
          'verificationIdEmpty': _verificationId.value.isEmpty,
          'phoneNumber': _phoneNumber.value,
        },
      );
      FeedbackService.showAuthError(
        'Verification session expired. Please request a new code.',
      );
      return;
    }

    LoggingService.info(
      '🔄 Setting loading state and clearing errors',
      tag: 'AuthController',
    );
    _setLoading(true);
    _clearError();

    try {
      LoggingService.info(
        '📡 Calling auth service to verify OTP',
        tag: 'AuthController',
        data: {
          'verificationId': _verificationId.value,
          'otpLength': otp.length,
        },
      );

      final User user = await _authService.verifyOTP(
        _verificationId.value,
        otp,
      );

      LoggingService.info(
        '✅ OTP verification successful',
        tag: 'AuthController',
        data: {'userId': user.uid, 'phoneNumber': user.phoneNumber},
      );

      _currentUser.value = user;
      _isAuthenticated.value = true;
      _phoneNumber.value = user.phoneNumber;

      FeedbackService.showAuthSuccess('Authentication successful!');

      LoggingService.info(
        '🧭 Navigating to main app screen',
        tag: 'AuthController',
        data: {'route': AppRoutes.objectList, 'userId': user.uid},
      );

      // Navigate to main app screen
      NavigationService.offAllNamed(AppRoutes.objectList);
    } on AuthException catch (e) {
      LoggingService.error(
        '❌ Auth exception during OTP verification',
        tag: 'AuthController',
        error: e,
        data: {
          'verificationId': _verificationId.value,
          'otpLength': otp.length,
          'authExceptionMessage': e.message,
        },
      );
      ErrorHandler.handleAuthError(e, context: 'Verify OTP');
    } catch (e) {
      LoggingService.error(
        '❌ Unexpected error during OTP verification',
        tag: 'AuthController',
        error: e,
        data: {
          'verificationId': _verificationId.value,
          'otpLength': otp.length,
          'errorType': e.runtimeType.toString(),
        },
      );
      _handleError('Failed to verify OTP. Please try again.');
    } finally {
      LoggingService.info('🔄 Clearing loading state', tag: 'AuthController');
      _setLoading(false);
    }
  }

  /// Resend OTP to the current phone number
  Future<void> resendOTP() async {
    LoggingService.info(
      '🔄 Resending OTP',
      tag: 'AuthController',
      data: {
        'phoneNumber': _phoneNumber.value,
        'hasPhoneNumber': _phoneNumber.value.isNotEmpty,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (_phoneNumber.value.isEmpty) {
      LoggingService.error(
        '❌ No phone number available for resend',
        tag: 'AuthController',
      );
      FeedbackService.showAuthError(
        'Phone number not found. Please start over.',
      );
      return;
    }

    LoggingService.info(
      '📞 Calling sendOTP for resend',
      tag: 'AuthController',
      data: {'phoneNumber': _phoneNumber.value},
    );

    await sendOTP(_phoneNumber.value);
  }

  /// Sign out the current user
  Future<void> logout() async {
    LoggingService.info(
      '🚪 Starting logout process',
      tag: 'AuthController',
      data: {
        'hasCurrentUser': _currentUser.value != null,
        'userId': _currentUser.value?.uid,
        'phoneNumber': _currentUser.value?.phoneNumber,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    LoggingService.info(
      '🔄 Setting loading state and clearing errors',
      tag: 'AuthController',
    );
    _setLoading(true);
    _clearError();

    try {
      LoggingService.info(
        '📡 Calling auth service to sign out',
        tag: 'AuthController',
      );
      await _authService.signOut();

      LoggingService.info(
        '🧹 Clearing authentication state',
        tag: 'AuthController',
      );
      _clearAuthState();

      FeedbackService.showAuthSuccess('Logged out successfully');

      LoggingService.info(
        '🧭 Navigating to login screen',
        tag: 'AuthController',
      );
      // Navigate to login screen
      NavigationService.toLogin();

      LoggingService.info(
        '✅ Logout process completed successfully',
        tag: 'AuthController',
      );
    } on AuthException catch (e) {
      LoggingService.error(
        '❌ Auth exception during logout',
        tag: 'AuthController',
        error: e,
        data: {'authExceptionMessage': e.message},
      );
      ErrorHandler.handleAuthError(e, context: 'Logout');
    } catch (e) {
      LoggingService.error(
        '❌ Unexpected error during logout',
        tag: 'AuthController',
        error: e,
        data: {'errorType': e.runtimeType.toString()},
      );
      _handleError('Failed to logout. Please try again.');
    } finally {
      LoggingService.info('🔄 Clearing loading state', tag: 'AuthController');
      _setLoading(false);
    }
  }

  /// Clear all authentication state
  void _clearAuthState() {
    LoggingService.info(
      '🧹 Clearing all authentication state',
      tag: 'AuthController',
      data: {
        'previousAuthState': _isAuthenticated.value,
        'previousUserId': _currentUser.value?.uid,
        'previousPhoneNumber': _phoneNumber.value,
      },
    );

    _isAuthenticated.value = false;
    _currentUser.value = null;
    _phoneNumber.value = '';
    _verificationId.value = '';
    _clearError();

    LoggingService.info(
      '✅ Authentication state cleared',
      tag: 'AuthController',
    );
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  /// Clear error message
  void _clearError() {
    _errorMessage.value = '';
  }

  /// Handle errors and update error state
  void _handleError(String error) {
    LoggingService.error(
      '🚨 Handling authentication error',
      tag: 'AuthController',
      data: {
        'errorMessage': error,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    _errorMessage.value = error;
    FeedbackService.showAuthError(error);
  }

  /// Update phone number (for form binding)
  void updatePhoneNumber(String phoneNumber) {
    _phoneNumber.value = phoneNumber;
  }

  /// Check if phone number is valid (basic validation)
  bool isPhoneNumberValid(String phoneNumber) {
    // Basic phone number validation - should start with + and have at least 10 digits
    final RegExp phoneRegex = RegExp(r'^\+[1-9]\d{9,14}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  /// Reload current user information
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      final User? user = _authService.getCurrentUser();
      _currentUser.value = user;
    } catch (e) {
      _handleError('Failed to reload user information');
    }
  }

  @override
  void onClose() {
    // Clean up any subscriptions or resources
    super.onClose();
  }
}
