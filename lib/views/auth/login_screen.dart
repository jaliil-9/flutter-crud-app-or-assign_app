import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../services/logging_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

/// Login screen with phone number input and OTP sending functionality
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      _buildLoginForm(),
                      SizedBox(height: AppConstants.largeSpacing),
                      _buildLoginButton(),
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

  /// Build the header section with app title and description
  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.phone_android,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: AppConstants.mediumSpacing),
        Text(
          'Welcome',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppConstants.smallSpacing),
        Text(
          'Enter your phone number to get started',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build the phone number input form
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Number',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppConstants.smallSpacing),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[+\d\s\-\(\)]')),
            ],
            decoration: InputDecoration(
              hintText: '+1234567890',
              prefixIcon: Icon(Icons.phone),
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
            validator: Validators.validatePhoneNumber,
            onFieldSubmitted: (_) => _handleSendOTP(),
          ),
          SizedBox(height: AppConstants.smallSpacing),
          Text(
            'Include country code (e.g., +1 for US)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the send OTP button with loading state
  Widget _buildLoginButton() {
    return Obx(() {
      final isLoading = _authController.isLoading;

      return SizedBox(
        height: AppConstants.buttonHeight,
        child: ElevatedButton(
          onPressed: isLoading ? null : _handleSendOTP,
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
                  'Send Verification Code',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
        ),
      );
    });
  }

  /// Build help text section
  Widget _buildHelpText() {
    return Column(
      children: [
        Text(
          'We\'ll send you a verification code via SMS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppConstants.smallSpacing),
        TextButton(
          onPressed: _showHelpDialog,
          child: Text(
            'Need help?',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }

  /// Handle send OTP button press
  void _handleSendOTP() {
    LoggingService.info(
      '📞 User initiated OTP send',
      tag: 'LoginScreen',
      data: {
        'phoneNumberLength': _phoneController.text.trim().length,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (_formKey.currentState?.validate() ?? false) {
      final phoneNumber = Validators.formatPhoneNumber(
        _phoneController.text.trim(),
      );

      LoggingService.info(
        '✅ Phone number validation passed',
        tag: 'LoginScreen',
        data: {
          'formattedPhoneNumber': phoneNumber,
          'originalInput': _phoneController.text.trim(),
        },
      );

      _authController.sendOTP(phoneNumber);
    } else {
      LoggingService.warning(
        '❌ Phone number validation failed',
        tag: 'LoginScreen',
        data: {'phoneNumberInput': _phoneController.text.trim()},
      );
    }
  }

  /// Show help dialog with instructions
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Phone Number Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please enter your phone number with country code:'),
            SizedBox(height: AppConstants.smallSpacing),
            Text('• US: +1234567890'),
            Text('• UK: +441234567890'),
            Text('• India: +911234567890'),
            SizedBox(height: AppConstants.smallSpacing),
            Text(
              'Make sure your phone can receive SMS messages.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}
