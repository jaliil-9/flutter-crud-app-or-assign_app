import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth;

  static final Map<String, dynamic> _webConfirmationStore = <String, dynamic>{};

  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  Future<String> sendOTP(String phoneNumber) async {
    try {
      if (kIsWeb) {
        final confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
        );

        final token = DateTime.now().millisecondsSinceEpoch.toString();
        _webConfirmationStore[token] = confirmationResult;

        return token;
      } else {
        final Completer<String> verificationCompleter = Completer<String>();

        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {},
          verificationFailed: (FirebaseAuthException e) {
            if (!verificationCompleter.isCompleted) {
              verificationCompleter.completeError(
                AuthException(_getAuthErrorMessage(e)),
              );
            }
          },
          codeSent: (String verId, int? resendTokenValue) {
            if (!verificationCompleter.isCompleted) {
              verificationCompleter.complete(verId);
            }
          },
          codeAutoRetrievalTimeout: (String verId) {
            if (!verificationCompleter.isCompleted) {
              verificationCompleter.complete(verId);
            }
          },
        );

        try {
          final String verificationId = await verificationCompleter.future
              .timeout(
                const Duration(seconds: 90),
                onTimeout: () {
                  throw const AuthException(
                    'Request timed out. Please try again.',
                  );
                },
              );

          return verificationId;
        } catch (e) {
          if (e is AuthException) {
            rethrow;
          }
          throw AuthException('Failed to send OTP: ${e.toString()}');
        }
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      throw AuthException('Failed to send OTP: $e');
    }
  }

  Future<app_user.User> verifyOTP(String verificationId, String otp) async {
    try {
      if (kIsWeb) {
        final confirmationResult = _webConfirmationStore.remove(verificationId);
        if (confirmationResult == null) {
          throw const AuthException(
            'Verification session expired. Please try again.',
          );
        }

        final userCredential = await confirmationResult.confirm(otp);

        if (userCredential.user == null) {
          throw const AuthException('Authentication failed. Please try again.');
        }

        final user = app_user.User.fromFirebaseUser(userCredential.user!);
        return user;
      } else {
        final PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otp,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        if (userCredential.user == null) {
          throw const AuthException('Authentication failed. Please try again.');
        }

        final user = app_user.User.fromFirebaseUser(userCredential.user!);
        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Failed to verify OTP: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();

      if (kIsWeb && _webConfirmationStore.isNotEmpty) {
        _webConfirmationStore.clear();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  app_user.User? getCurrentUser() {
    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      final user = app_user.User.fromFirebaseUser(firebaseUser);
      return user;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  bool get isAuthenticated => _auth.currentUser != null;

  Stream<app_user.User?> get authStateChanges {
    return _auth.authStateChanges().map((User? firebaseUser) {
      if (firebaseUser == null) {
        return null;
      }

      final user = app_user.User.fromFirebaseUser(firebaseUser);
      return user;
    });
  }

  Stream<bool> get isAuthenticatedStream {
    return _auth.authStateChanges().map((User? user) => user != null);
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      throw AuthException('Failed to reload user: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw const AuthException('No user is currently signed in');
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid. Please enter a valid phone number.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'invalid-verification-code':
        return 'The verification code is invalid. Please check and try again.';
      case 'invalid-verification-id':
        return 'The verification session has expired. Please request a new code.';
      case 'session-expired':
        return 'The verification session has expired. Please request a new code.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'missing-phone-number':
        return 'Phone number is required.';
      case 'missing-verification-code':
        return 'Verification code is required.';
      case 'missing-verification-id':
        return 'Verification ID is missing. Please request a new code.';
      case 'credential-already-in-use':
        return 'This phone number is already associated with another account.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this phone number.';
      case 'network-request-failed':
        return 'Network error occurred. Please check your internet connection.';
      case 'internal-error':
        return 'An internal error occurred. Please try again.';
      case 'app-not-authorized':
        return 'App is not authorized to use Firebase Authentication.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'web-context-already-presented':
        return 'Authentication is already in progress.';
      case 'web-context-cancelled':
        return 'Authentication was cancelled by the user.';
      default:
        return e.message ??
            'An authentication error occurred. Please try again.';
    }
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
