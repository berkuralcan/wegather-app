import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add this import
import 'package:go_router/go_router.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/providers/auth_providers.dart'; // Add this import
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/reusableWidgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  // Changed from StatefulWidget
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState(); // Changed return type
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Changed extends
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // Add loading state
  String? _errorMessage; // Add error state

  // Recognizer for the tappable "Terms and Services" link.
  final _termsRecognizer = TapGestureRecognizer();

  // Label shown above each field
  static const TextStyle _fieldLabelStyle = TextStyle(
    fontSize: 14,
    color: Color(0xA3FAFAFA),
  );

  // Shared decoration so both fields look identical
  InputDecoration _fieldDecoration({String? errorText}) {
    return InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      fillColor: AppConfig.loginPageFormBgColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide(color: AppConfig.loginPageFormBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide(color: AppConfig.loginPageFormBorderColor),
      ),
      errorText: errorText,
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppConfig.appLogo, height: 200),
                  SizedBox(height: 24),
                  FocusTraversalGroup(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 25),
                            Text(
                              AppLocalizations.of(context)!.login_emailAddress,
                              style: _fieldLabelStyle,
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _userNameController,
                              style: AppTextStyles.weGatherPrimaryTextStyle
                                  .copyWith(color: Colors.white),
                              cursorColor: Colors.white,
                              decoration: _fieldDecoration(
                                errorText: _errorMessage,
                              ),
                              keyboardType: TextInputType
                                  .emailAddress, // Add email keyboard
                              enabled: !_isLoading, // Disable when loading
                            ),
                            SizedBox(height: 25),
                            Text(
                              AppLocalizations.of(context)!.login_password,
                              style: _fieldLabelStyle,
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              controller: _passwordController,
                              style: AppTextStyles.weGatherPrimaryTextStyle
                                  .copyWith(color: Colors.white),
                              cursorColor: Colors.white,
                              decoration: _fieldDecoration(),
                              enabled: !_isLoading, // Disable when loading
                            ),
                            SizedBox(height: 24), // Add some spacing
                            _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(),
                                  ) // Show loading indicator
                                : SizedBox(
                                    width: double.infinity,
                                    child: PrimaryButton(
                                      label: AppLocalizations.of(
                                        context,
                                      )!.login_login,
                                      onPressed:
                                          _signIn, // Add the sign in method
                                    ),
                                  ),
                            SizedBox(height: 24),
                            Center(
                              child: GestureDetector(
                                onTap: () => context.push('/reset-password'),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.login_forgotPassword,
                                  style: AppTextStyles.weGatherTextButtonStyle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: AppLocalizations.of(context)!.login_terms_prefix,
                      style: AppTextStyles.weGatherTextButtonStyle,
                    ),
                    TextSpan(
                      text: AppLocalizations.of(context)!.login_terms_link,
                      style: AppTextStyles.weGatherColoredTextButtonStyle
                          .copyWith(decoration: TextDecoration.underline),
                      recognizer: _termsRecognizer
                        ..onTap = () => context.push('/terms'),
                    ),
                    TextSpan(
                      text: AppLocalizations.of(context)!.login_terms_suffix,
                      style: AppTextStyles.weGatherTextButtonStyle,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method to handle sign in
  Future<void> _signIn() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Basic validation
    if (_userNameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the auth service from Riverpod
      final authService = ref.read(authServiceProvider);

      // Call your existing signIn method
      await authService.signIn(
        email: _userNameController.text.trim(),
        password: _passwordController.text,
      );

      // Success! The authStateProvider will automatically detect this change
      // and your app will navigate to the appropriate screen
    } catch (e) {
      // Handle errors
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      // Hide loading
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to convert Firebase errors to user-friendly messages
  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email address';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (error.contains('user-disabled')) {
      return 'This account has been disabled';
    } else {
      return 'Login failed. Please try again.';
    }
  }
}
