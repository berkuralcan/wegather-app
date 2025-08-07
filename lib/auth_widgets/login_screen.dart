import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add this import
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/containers/liquid_container.dart';
import 'package:wegather_app/providers/auth_providers.dart'; // Add this import

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

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Image.asset(AppConfig.appLogo),
          SizedBox(height: 100),
          FocusTraversalGroup(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 46),
              child: Form(
                child: Column(
                  children: [
                    SizedBox(height: 25),
                    LiquidContainer(
                      child: TextFormField(
                        controller: _userNameController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.email,
                            color: Colors.white,
                            size: 27,
                          ),
                          labelText: AppLocalizations.of(
                            context,
                          )!.login_emailAddress,
                          labelStyle: TextStyle(color: Colors.white),
                          border: InputBorder.none,
                          errorText: _errorMessage, // Show error if any
                        ),
                        keyboardType:
                            TextInputType.emailAddress, // Add email keyboard
                        enabled: !_isLoading, // Disable when loading
                      ),
                    ),
                    SizedBox(height: 25),
                    TextFormField(
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      controller: _passwordController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 27,
                        ),
                        labelText: AppLocalizations.of(
                          context,
                        )!.login_password, // Fixed: was using email label
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      enabled: !_isLoading, // Disable when loading
                    ),
                    SizedBox(height: 25), // Add some spacing
                    _isLoading
                        ? CircularProgressIndicator() // Show loading indicator
                        : ElevatedButton(
                            onPressed: _signIn, // Add the sign in method
                            child: Text(
                              AppLocalizations.of(context)!.login_login,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
