import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/providers/auth_providers.dart';
import 'package:wegather_app/reusableWidgets/primary_button.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Label shown above the field.
  static const TextStyle _fieldLabelStyle = TextStyle(
    fontSize: 14,
    color: Color(0xA3FAFAFA),
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(title: l10n.resetPassword_title),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                l10n.resetPassword_description,
                style: AppTextStyles.weGatherPrimaryTextStyle,
              ),
              const SizedBox(height: 24),
              Text(l10n.login_emailAddress, style: _fieldLabelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                style: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
                  color: Colors.white,
                ),
                cursorColor: Colors.white,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  fillColor: AppConfig.loginPageFormBgColor,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(
                      color: AppConfig.loginPageFormBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(
                      color: AppConfig.loginPageFormBorderColor,
                    ),
                  ),
                  errorText: _errorMessage,
                ),
              ),
              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _successMessage!,
                  style: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
                    color: AppConfig.accentColor,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: l10n.resetPassword_send,
                        onPressed: _sendResetEmail,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (email.isEmpty) {
      setState(() => _errorMessage = l10n.resetPassword_emptyEmail);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      // Firebase only sends the email when an account exists for it; a
      // non-existent account raises a `user-not-found` exception.
      await authService.resetPassword(email: email);

      if (!mounted) return;
      setState(() => _successMessage = l10n.resetPassword_success);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _mapError(e.code, l10n));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = l10n.resetPassword_genericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapError(String code, AppLocalizations l10n) {
    switch (code) {
      case 'user-not-found':
        return l10n.resetPassword_userNotFound;
      case 'invalid-email':
        return l10n.resetPassword_invalidEmail;
      default:
        return l10n.resetPassword_genericError;
    }
  }
}
