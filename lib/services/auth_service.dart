import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_user;
import 'logging_service.dart';

/// Service class for handling Firebase Authentication operations
class AuthService {
  final FirebaseAuth _auth;

  // Store web confirmation results
  static final Map<String, dynamic> _webConfirmationStore = <String, dynamic>{};

  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  void _log(String message, {LogLevel level = LogLevel.debug, dynamic data}) {
    switch (level) {
      case LogLevel.debug:
        LoggingService.debug(message, tag: 'AuthService', data: data);
        break;
      case LogLevel.info:
        LoggingService.info(message, tag: 'AuthService', data: data);
        break;
      case LogLevel.warning:
        LoggingService.warning(message, tag: 'AuthService', data: data);
        break;
      case LogLevel.error:
        LoggingService.error(message, tag: 'AuthService', data: data);
        break;
      case LogLevel.critical:
        LoggingService.critical(message, tag: 'AuthService', data: data);
        break;
    }
  }

  /// Send OTP to the provided phone number
  /// Returns the verification ID needed for OTP verification
  Future<String> sendOTP(String phoneNumber) async {
    _log(
      '🚀 Starting OTP send process',
      level: LogLevel.info,
      data: {
        'phoneNumber': phoneNumber,
        'platform': kIsWeb ? 'Web' : 'Mobile',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    try {
      if (kIsWeb) {
        _log(
          '🌐 Using web implementation for phone authentication',
          level: LogLevel.info,
        );

        _log(
          '📞 Calling Firebase signInWithPhoneNumber for web',
          data: {'phoneNumber': phoneNumber},
        );

        // Web implementation
        final confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
        );

        // Store confirmation result for web
        final token = DateTime.now().millisecondsSinceEpoch.toString();
        _webConfirmationStore[token] = confirmationResult;

        _log(
          '✅ Web confirmation result stored successfully',
          level: LogLevel.info,
          data: {
            'token': token,
            'confirmationResultType': confirmationResult.runtimeType.toString(),
          },
        );

        return token;
      } else {
        _log(
          '📱 Using mobile implementation for phone authentication',
          level: LogLevel.info,
        );

        // Mobile implementation using Completer to handle async callbacks
        final Completer<String> verificationCompleter = Completer<String>();
        int? resendToken;

        _log(
          '📞 Calling Firebase verifyPhoneNumber for mobile',
          data: {'phoneNumber': phoneNumber, 'timeout': '60 seconds'},
        );

        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            _log(
              '🔄 Auto-verification completed (Android only)',
              level: LogLevel.info,
              data: {
                'credentialType': credential.runtimeType.toString(),
                'smsCode': credential.smsCode,
              },
            );
            // Don't auto-sign in to avoid reCAPTCHA issues
            // await _auth.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            _log(
              '❌ Phone verification failed',
              level: LogLevel.error,
              data: {
                'errorCode': e.code,
                'errorMessage': e.message,
                'phoneNumber': phoneNumber,
              },
            );
            if (!verificationCompleter.isCompleted) {
              verificationCompleter.completeError(
                AuthException(_getAuthErrorMessage(e)),
              );
            }
          },
          codeSent: (String verId, int? resendTokenValue) {
            _log(
              '📨 SMS code sent successfully',
              level: LogLevel.info,
              data: {
                'verificationId': verId,
                'resendToken': resendTokenValue,
                'phoneNumber': phoneNumber,
              },
            );
            resendToken = resendTokenValue;
            if (!verificationCompleter.isCompleted) {
              verificationCompleter.complete(verId);
            }
          },
          codeAutoRetrievalTimeout: (String verId) {
            _log(
              '⏰ Code auto-retrieval timeout reached',
              level: LogLevel.warning,
              data: {'verificationId': verId, 'phoneNumber': phoneNumber},
            );
            // If codeSent hasn't been called yet, complete with this verification ID
            if (!verificationCompleter.isCompleted) {
              verificationCompleter.complete(verId);
            }
          },
        );

        // Wait for verification ID with proper timeout
        _log(
          '⏳ Waiting for Firebase Auth callbacks...',
          data: {'timeoutSeconds': 90},
        );

        try {
          final String verificationId = await verificationCompleter.future
              .timeout(
                const Duration(seconds: 90),
                onTimeout: () {
                  _log(
                    '❌ Timeout waiting for Firebase Auth callbacks',
                    level: LogLevel.error,
                    data: {'timeoutSeconds': 90, 'phoneNumber': phoneNumber},
                  );
                  throw const AuthException(
                    'Request timed out. Please try again.',
                  );
                },
              );

          _log(
            '✅ OTP send process completed successfully',
            level: LogLevel.info,
            data: {
              'verificationId': verificationId,
              'resendToken': resendToken,
            },
          );

          return verificationId;
        } catch (e) {
          if (e is AuthException) {
            rethrow;
          }
          _log(
            '❌ Error waiting for verification ID',
            level: LogLevel.error,
            data: {
              'error': e.toString(),
              'errorType': e.runtimeType.toString(),
            },
          );
          throw AuthException('Failed to send OTP: ${e.toString()}');
        }
      }
    } on FirebaseAuthException catch (e) {
      _log(
        '❌ Firebase Auth error during OTP send',
        level: LogLevel.error,
        data: {
          'errorCode': e.code,
          'errorMessage': e.message,
          'phoneNumber': phoneNumber,
          'platform': kIsWeb ? 'Web' : 'Mobile',
        },
      );
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      _log(
        '❌ Unexpected error during OTP send',
        level: LogLevel.error,
        data: {
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
          'phoneNumber': phoneNumber,
        },
      );
      throw AuthException('Failed to send OTP: $e');
    }
  }

  /// Verify the OTP with the verification ID
  /// Returns the authenticated User on success
  Future<app_user.User> verifyOTP(String verificationId, String otp) async {
    _log(
      '🔐 Starting OTP verification process',
      level: LogLevel.info,
      data: {
        'verificationId': verificationId,
        'otpLength': otp.length,
        'platform': kIsWeb ? 'Web' : 'Mobile',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    try {
      if (kIsWeb) {
        _log(
          '🌐 Using web implementation for OTP verification',
          level: LogLevel.info,
        );

        // Web implementation
        _log(
          '🔍 Looking up confirmation result from store',
          data: {
            'verificationId': verificationId,
            'storeSize': _webConfirmationStore.length,
          },
        );

        final confirmationResult = _webConfirmationStore.remove(verificationId);
        if (confirmationResult == null) {
          _log(
            '❌ Confirmation result not found in store',
            level: LogLevel.error,
            data: {
              'verificationId': verificationId,
              'availableKeys': _webConfirmationStore.keys.toList(),
            },
          );
          throw const AuthException(
            'Verification session expired. Please try again.',
          );
        }

        _log(
          '✅ Confirmation result found, attempting to confirm OTP',
          data: {
            'confirmationResultType': confirmationResult.runtimeType.toString(),
          },
        );

        final userCredential = await confirmationResult.confirm(otp);

        _log(
          '📋 OTP confirmation completed',
          data: {
            'hasUser': userCredential.user != null,
            'userId': userCredential.user?.uid,
            'phoneNumber': userCredential.user?.phoneNumber,
          },
        );

        if (userCredential.user == null) {
          _log(
            '❌ User credential is null after confirmation',
            level: LogLevel.error,
          );
          throw const AuthException('Authentication failed. Please try again.');
        }

        final user = app_user.User.fromFirebaseUser(userCredential.user!);
        _log(
          '✅ Web OTP verification successful',
          level: LogLevel.info,
          data: {'userId': user.uid, 'phoneNumber': user.phoneNumber},
        );

        return user;
      } else {
        _log(
          '📱 Using mobile implementation for OTP verification',
          level: LogLevel.info,
        );

        // Mobile implementation
        _log(
          '🔑 Creating phone auth credential',
          data: {'verificationId': verificationId, 'otpLength': otp.length},
        );

        final PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otp,
        );

        _log(
          '🔐 Signing in with phone credential',
          data: {'credentialType': credential.runtimeType.toString()},
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        _log(
          '📋 Sign in with credential completed',
          data: {
            'hasUser': userCredential.user != null,
            'userId': userCredential.user?.uid,
            'phoneNumber': userCredential.user?.phoneNumber,
            'isNewUser': userCredential.additionalUserInfo?.isNewUser,
          },
        );

        if (userCredential.user == null) {
          _log(
            '❌ User credential is null after sign in',
            level: LogLevel.error,
          );
          throw const AuthException('Authentication failed. Please try again.');
        }

        final user = app_user.User.fromFirebaseUser(userCredential.user!);
        _log(
          '✅ Mobile OTP verification successful',
          level: LogLevel.info,
          data: {
            'userId': user.uid,
            'phoneNumber': user.phoneNumber,
            'isNewUser': userCredential.additionalUserInfo?.isNewUser,
          },
        );

        return user;
      }
    } on FirebaseAuthException catch (e) {
      _log(
        '❌ Firebase Auth error during OTP verification',
        level: LogLevel.error,
        data: {
          'errorCode': e.code,
          'errorMessage': e.message,
          'verificationId': verificationId,
          'otpLength': otp.length,
          'platform': kIsWeb ? 'Web' : 'Mobile',
        },
      );
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      if (e is AuthException) {
        _log(
          '❌ Auth exception during OTP verification',
          level: LogLevel.error,
          data: {'authException': e.message, 'verificationId': verificationId},
        );
        rethrow;
      }
      _log(
        '❌ Unexpected error during OTP verification',
        level: LogLevel.error,
        data: {
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
          'verificationId': verificationId,
          'otpLength': otp.length,
        },
      );
      throw AuthException('Failed to verify OTP: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    _log(
      '🚪 Starting sign out process',
      level: LogLevel.info,
      data: {
        'hasCurrentUser': _auth.currentUser != null,
        'currentUserId': _auth.currentUser?.uid,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    try {
      await _auth.signOut();

      _log(
        '✅ Sign out completed successfully',
        level: LogLevel.info,
        data: {'hasCurrentUser': _auth.currentUser != null},
      );

      // Clear web confirmation store on sign out
      if (kIsWeb && _webConfirmationStore.isNotEmpty) {
        _webConfirmationStore.clear();
        _log(
          '🧹 Cleared web confirmation store',
          data: {'storeSize': _webConfirmationStore.length},
        );
      }
    } on FirebaseAuthException catch (e) {
      _log(
        '❌ Firebase Auth error during sign out',
        level: LogLevel.error,
        data: {'errorCode': e.code, 'errorMessage': e.message},
      );
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      _log(
        '❌ Unexpected error during sign out',
        level: LogLevel.error,
        data: {'error': e.toString(), 'errorType': e.runtimeType.toString()},
      );
      throw AuthException('Failed to sign out: $e');
    }
  }

  /// Get the current authenticated user
  /// Returns null if no user is authenticated
  app_user.User? getCurrentUser() {
    _log(
      '👤 Getting current user',
      data: {
        'hasCurrentUser': _auth.currentUser != null,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        _log('👤 No current user found');
        return null;
      }

      final user = app_user.User.fromFirebaseUser(firebaseUser);
      _log(
        '✅ Current user retrieved successfully',
        data: {
          'userId': user.uid,
          'phoneNumber': user.phoneNumber,
          'isEmailVerified': firebaseUser.emailVerified,
          'creationTime': firebaseUser.metadata.creationTime?.toIso8601String(),
          'lastSignInTime': firebaseUser.metadata.lastSignInTime
              ?.toIso8601String(),
        },
      );

      return user;
    } catch (e) {
      _log(
        '❌ Error getting current user',
        level: LogLevel.error,
        data: {'error': e.toString(), 'errorType': e.runtimeType.toString()},
      );
      return null;
    }
  }

  /// Check if a user is currently authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream of authentication state changes
  Stream<app_user.User?> get authStateChanges {
    _log('🔄 Setting up auth state changes stream', level: LogLevel.info);

    return _auth.authStateChanges().map((User? firebaseUser) {
      if (firebaseUser == null) {
        _log('🔄 Auth state changed: User signed out', level: LogLevel.info);
        return null;
      }

      final user = app_user.User.fromFirebaseUser(firebaseUser);
      _log(
        '🔄 Auth state changed: User signed in',
        level: LogLevel.info,
        data: {
          'userId': user.uid,
          'phoneNumber': user.phoneNumber,
          'lastSignInTime': firebaseUser.metadata.lastSignInTime
              ?.toIso8601String(),
        },
      );

      return user;
    });
  }

  /// Get user authentication state stream for reactive programming
  Stream<bool> get isAuthenticatedStream {
    return _auth.authStateChanges().map((User? user) => user != null);
  }

  /// Reload the current user to get updated information
  Future<void> reloadUser() async {
    _log(
      '🔄 Reloading current user',
      level: LogLevel.info,
      data: {
        'hasCurrentUser': _auth.currentUser != null,
        'currentUserId': _auth.currentUser?.uid,
      },
    );

    try {
      await _auth.currentUser?.reload();

      _log(
        '✅ User reload completed successfully',
        level: LogLevel.info,
        data: {
          'userId': _auth.currentUser?.uid,
          'phoneNumber': _auth.currentUser?.phoneNumber,
        },
      );
    } on FirebaseAuthException catch (e) {
      _log(
        '❌ Firebase Auth error during user reload',
        level: LogLevel.error,
        data: {'errorCode': e.code, 'errorMessage': e.message},
      );
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      _log(
        '❌ Unexpected error during user reload',
        level: LogLevel.error,
        data: {'error': e.toString(), 'errorType': e.runtimeType.toString()},
      );
      throw AuthException('Failed to reload user: $e');
    }
  }

  /// Delete the current user account
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

  /// Convert Firebase Auth errors to user-friendly messages
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

/// Custom exception class for authentication-related errors
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
