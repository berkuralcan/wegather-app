import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/support_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';
import '../reusableWidgets/primary_button.dart';
import '../services/support_service.dart';

/// The form for opening a support request: a subject and a first message.
///
/// A sheet rather than a screen because it is a task the user either finishes or
/// abandons, and the same reason the community composer covers the bottom bar —
/// there is nothing to navigate to halfway through.
///
/// Resolves to the new request's id, or to null when the user backed out, so the
/// caller can push straight into the conversation that was just started.
class NewRequestSheet {
  const NewRequestSheet._();

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      // The sheet paints its own surface over the app's background gradient.
      backgroundColor: Colors.transparent,
      // Lets the sheet grow with the keyboard rather than hiding the fields
      // behind it.
      isScrollControlled: true,
      builder: (_) => const _NewRequestSheet(),
    );
  }
}

class _NewRequestSheet extends ConsumerStatefulWidget {
  const _NewRequestSheet();

  @override
  ConsumerState<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends ConsumerState<_NewRequestSheet> {
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();

  static const double _padding = 16;
  static const double _radius = 24;

  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  void _showError(String message) {
    showLiquidSnackBar(
      context,
      message,
      icon: Icons.error,
      iconColor: Colors.red,
    );
  }

  Future<void> _submit() async {
    if (_sending) return;
    final l10n = AppLocalizations.of(context)!;

    final subject = _subject.text.trim();
    final message = _message.text.trim();
    // Caught here rather than left to the service, so an empty field reads as a
    // prompt rather than as an error.
    if (subject.isEmpty) {
      _showError(l10n.support_subjectRequired);
      return;
    }
    if (message.isEmpty) {
      _showError(l10n.support_messageRequired);
      return;
    }

    final eventId = ref.read(selectedEventIdProvider);
    final user = ref.read(currentUserProvider);
    if (eventId == null || user == null) {
      _showError(l10n.support_createError);
      return;
    }

    setState(() => _sending = true);
    try {
      // The requester's name and photo are stored on the request: a company
      // admin can't read other users' documents, so without them the panel's
      // queue would have no name to show.
      final profile = await ref.read(currentProfileProvider.future);
      final image = profile?.profileImage;

      final requestId = await ref
          .read(supportServiceProvider)
          .openRequest(
            eventId: eventId,
            requesterId: user.uid,
            requesterName: profile?.name ?? user.displayName ?? '',
            requesterImage: (image == null || image.isEmpty) ? null : image,
            subject: subject,
            message: message,
          );

      if (!mounted) return;
      Navigator.of(context).pop(requestId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      _showError(l10n.support_createError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      // Sits above the keyboard while the fields are being typed into.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppConfig.appDarkBackgroundGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(_padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: _Handle()),
                  const SizedBox(height: _padding),
                  Text(
                    l10n.support_newRequest,
                    style: AppTextStyles.weGatherHeading2TextStyle,
                  ),
                  const SizedBox(height: _padding),

                  Text(
                    l10n.support_subjectLabel,
                    style: AppTextStyles.weGatherSmallTextStyle,
                  ),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _subject,
                    hint: l10n.support_subjectHint,
                    enabled: !_sending,
                    maxLength: SupportService.subjectMaxLength,
                    maxLines: 1,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: _padding),

                  Text(
                    l10n.support_messageLabel,
                    style: AppTextStyles.weGatherSmallTextStyle,
                  ),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _message,
                    hint: l10n.support_messageHint,
                    enabled: !_sending,
                    maxLength: SupportService.messageMaxLength,
                    minLines: 3,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: _padding),

                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: l10n.support_sendRequest,
                      // Disabled rather than merely guarded, so a double tap
                      // can't open two requests.
                      onPressed: _sending ? null : _submit,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A filled, rounded text field in the sheet's style — the same decoration the
/// report sheets use, so every form in the app is shaped alike.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.enabled,
    required this.maxLength,
    this.minLines,
    this.maxLines,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final int maxLength;
  final int? minLines;
  final int? maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppConfig.loginPageFormBorderColor),
    );

    return TextField(
      controller: controller,
      enabled: enabled,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      textCapitalization: TextCapitalization.sentences,
      style: AppTextStyles.weGatherPrimaryTextStyle,
      cursorColor: AppConfig.emphasisColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
          color: AppConfig.colorTertiary,
        ),
        // The limit is a guard against a runaway paste, not a word count to
        // watch while typing.
        counterText: '',
        contentPadding: const EdgeInsets.all(12),
        fillColor: AppConfig.loginPageFormBgColor,
        filled: true,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}

/// The grab bar at the top of the sheet.
class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppConfig.colorTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
