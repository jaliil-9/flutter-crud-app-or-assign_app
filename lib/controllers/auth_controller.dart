import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import '../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService;

  final RxBool isAuthenticated = false.obs;
  final RxBool isLoading = false.obs;
  final RxString phoneNumber = ''.obs;
  final Rxn<User> currentUser = Rxn<User>();
  final RxString verificationId = ''.obs;

  final Completer<void> _authReadyCompleter = Completer<void>();

  Future<void> get onAuthReady => _authReadyCompleter.future;

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  @override
  void onInit() {
    super.onInit();
    checkAuthState();
    _listenToAuthStateChanges();
  }

  void _listenToAuthStateChanges() {
    _authService.authStateChanges.listen((User? user) {
      currentUser.value = user;
      isAuthenticated.value = user != null;

      if (user != null) {
        phoneNumber.value = user.phoneNumber;
      }

      if (!_authReadyCompleter.isCompleted) {
        _authReadyCompleter.complete();
      }
    });
  }

  void checkAuthState() {
    try {
      final User? user = _authService.getCurrentUser();
      currentUser.value = user;
      isAuthenticated.value = user != null;

      if (user != null) {
        phoneNumber.value = user.phoneNumber;
      }
    } catch (e) {
      debugPrint('Failed to check authentication state: $e');
      _showError('Failed to check authentication state');
    }
  }

  Future<void> sendOTP(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showError('Please enter a valid phone number');
      return;
    }

    isLoading.value = true;

    try {
      final String verificationId = await _authService.sendOTP(phoneNumber);
      this.verificationId.value = verificationId;
      this.phoneNumber.value = phoneNumber;

      Get.snackbar(
        'Success',
        'OTP sent successfully to $phoneNumber',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      NavigationService.toOTPVerification(
        phoneNumber: phoneNumber,
        verificationId: verificationId,
      );
    } catch (e) {
      debugPrint('Failed to send OTP: $e');
      _showError('Failed to send OTP. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOTP(String otp) async {
    if (otp.isEmpty) {
      _showError('Please enter the verification code');
      return;
    }

    if (verificationId.value.isEmpty) {
      _showError('Verification session expired. Please request a new code.');
      return;
    }

    isLoading.value = true;

    try {
      final User user = await _authService.verifyOTP(verificationId.value, otp);

      currentUser.value = user;
      isAuthenticated.value = true;
      phoneNumber.value = user.phoneNumber;

      Get.snackbar(
        'Success',
        'Authentication successful!',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      NavigationService.offAllNamed(AppRoutes.objectList);
    } catch (e) {
      debugPrint('Failed to verify OTP: $e');
      _showError('Failed to verify OTP. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOTP() async {
    if (phoneNumber.value.isEmpty) {
      _showError('Phone number not found. Please start over.');
      return;
    }

    await sendOTP(phoneNumber.value);
  }

  Future<void> logout() async {
    isLoading.value = true;

    try {
      await _authService.signOut();
      _clearAuthState();

      Get.snackbar(
        'Success',
        'Logged out successfully',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      NavigationService.toLogin();
    } catch (e) {
      debugPrint('Failed to logout: $e');
      _showError('Failed to logout. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void _clearAuthState() {
    isAuthenticated.value = false;
    currentUser.value = null;
    phoneNumber.value = '';
    verificationId.value = '';
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  void updatePhoneNumber(String phoneNumber) {
    this.phoneNumber.value = phoneNumber;
  }

  bool isPhoneNumberValid(String phoneNumber) {
    final RegExp phoneRegex = RegExp(r'^\+[1-9]\d{9,14}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      final User? user = _authService.getCurrentUser();
      currentUser.value = user;
    } catch (e) {
      debugPrint('Failed to reload user information: $e');
      _showError('Failed to reload user information');
    }
  }
}
