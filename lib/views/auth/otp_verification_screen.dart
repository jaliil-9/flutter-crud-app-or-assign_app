import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../services/logging_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

/// OTP verification screen for phone number authentication
class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();

  // Get arguments passed from login screen
  late final String phoneNumber;
  late final String verificationId;

  @override
  void initState() {
    super.initState();

    LoggingService.info(
      '🔐 OTP verification screen initialized',
      tag: 'OTPVerificationScreen',
    );

    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    phoneNumber = args['phoneNumber'] ?? _authController.phoneNumber;
    verificationId = args['verificationId'] ?? _authController.verificationId;

    LoggingService.info(
      '📋 OTP screen arguments received',
      tag: 'OTPVerificationScreen',
      data: {
        'hasPhoneNumber': phoneNumber.isNotEmpty,
        'hasVerificationId': verificationId.isNotEmpty,
        'phoneNumber': phoneNumber,
        'verificationId': verificationId,
      },
    );

    // If no phone number available, go back to login
    if (phoneNumber.isEmpty) {
      LoggingService.warning(
        '❌ No phone number available, redirecting to login',
        tag: 'OTPVerificationScreen',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/login');
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Phone'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen =
                constraints.maxWidth > AppConstants.mobileBreakpoint;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWideScreen ? 400 : double.infinity,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      SizedBox(height: AppConstants.extraLargeSpacing),
                      _buildOTPForm(),
                      SizedBox(height: AppConstants.largeSpacing),
                      _buildVerifyButton(),
                      SizedBox(height: AppConstants.mediumSpacing),
                      _buildResendSection(),
                      SizedBox(height: AppConstants.mediumSpacing),
                      _buildHelpText(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build the header section with verification message
  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.sms, size: 80, color: Theme.of(context).colorScheme.primary),
        SizedBox(height: AppConstants.mediumSpacing),
        Text(
          'Verification Code',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppConstants.smallSpacing),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            children: [
              TextSpan(text: 'We sent a verification code to\n'),
              TextSpan(
                text: phoneNumber,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build the OTP input form
  Widget _buildOTPForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Code',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppConstants.smallSpacing),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: AppConstants.otpLength,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              letterSpacing: 8,
              fontWeight: FontWeight.w600,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(AppConstants.otpLength),
            ],
            decoration: InputDecoration(
              hintText: '000000',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            validator: Validators.validateOTP,
            onChanged: (value) {
              // Auto-submit when 6 digits are entered
              if (value.length == AppConstants.otpLength) {
                LoggingService.info(
                  '🔄 Auto-submitting OTP (6 digits entered)',
                  tag: 'OTPVerificationScreen',
                  data: {'otpLength': value.length},
                );
                _handleVerifyOTP();
              }
            },
            onFieldSubmitted: (_) => _handleVerifyOTP(),
          ),
          SizedBox(height: AppConstants.smallSpacing),
          Text(
            'Enter the 6-digit code sent to your phone',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the verify button with loading state
  Widget _buildVerifyButton() {
    return Obx(() {
      final isLoading = _authController.isLoading;

      return SizedBox(
        height: AppConstants.buttonHeight,
        child: ElevatedButton(
          onPressed: isLoading ? null : _handleVerifyOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            elevation: 2,
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(
                  'Verify Code',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
        ),
      );
    });
  }

  /// Build the resend code section
  Widget _buildResendSection() {
    return Obx(() {
      final isLoading = _authController.isLoading;

      return Column(
        children: [
          Text(
            'Didn\'t receive the code?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppConstants.smallSpacing),
          TextButton(
            onPressed: isLoading ? null : _handleResendOTP,
            child: Text(
              isLoading ? 'Sending...' : 'Resend Code',
              style: TextStyle(
                color: isLoading
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Build help text and change number option
  Widget _buildHelpText() {
    return Column(
      children: [
        Text(
          'Make sure your phone can receive SMS messages',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppConstants.smallSpacing),
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            'Change Phone Number',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }

  /// Handle verify OTP button press
  void _handleVerifyOTP() {
    LoggingService.info(
      '🔐 User initiated OTP verification',
      tag: 'OTPVerificationScreen',
      data: {
        'otpLength': _otpController.text.trim().length,
        'phoneNumber': phoneNumber,
        'verificationId': verificationId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (_formKey.currentState?.validate() ?? false) {
      final otp = _otpController.text.trim();

      LoggingService.info(
        '✅ OTP validation passed',
        tag: 'OTPVerificationScreen',
        data: {'otpLength': otp.length, 'phoneNumber': phoneNumber},
      );

      _authController.verifyOTP(otp);
    } else {
      LoggingService.warning(
        '❌ OTP validation failed',
        tag: 'OTPVerificationScreen',
        data: {
          'otpInput': _otpController.text.trim(),
          'otpLength': _otpController.text.trim().length,
        },
      );
    }
  }

  /// Handle resend OTP button press
  void _handleResendOTP() {
    LoggingService.info(
      '🔄 User requested OTP resend',
      tag: 'OTPVerificationScreen',
      data: {
        'phoneNumber': phoneNumber,
        'verificationId': verificationId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    _authController.resendOTP();

    // Clear the current OTP input
    _otpController.clear();
    LoggingService.info(
      '🧹 Cleared OTP input field',
      tag: 'OTPVerificationScreen',
    );

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification code sent to $phoneNumber'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(AppConstants.defaultPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }
}
