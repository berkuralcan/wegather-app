import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../reusableWidgets/primary_button.dart';

/// Asks whether the user really means to report the post they are looking at,
/// and takes an optional note about why.
///
/// The gallery's [showReportMediaSheet] with a post's wording: the two features
/// report to the same admin panel, so they ask the same way.
///
/// Resolves to the note — an empty string when they confirmed without typing
/// one — or to null when they backed out, so a caller can tell "reported with
/// nothing to add" from "changed their mind".
Future<String?> showReportPostSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    // The sheet paints its own surface over the app's background gradient.
    backgroundColor: Colors.transparent,
    // Lets the sheet grow with the keyboard rather than being pinned to half
    // the screen with the field hidden underneath it.
    isScrollControlled: true,
    builder: (_) => const _ReportPostSheet(),
  );
}

class _ReportPostSheet extends StatefulWidget {
  const _ReportPostSheet();

  @override
  State<_ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<_ReportPostSheet> {
  final TextEditingController _reason = TextEditingController();

  static const double _padding = 16;
  static const double _radius = 24;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      // Sits above the keyboard while the note is being typed.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppConfig.appDarkBackgroundGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: _Handle()),
                const SizedBox(height: _padding),
                Text(
                  l10n.community_reportTitle,
                  style: AppTextStyles.weGatherHeading2TextStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.community_reportDescription,
                  style: AppTextStyles.weGatherSmallTextStyle,
                ),
                const SizedBox(height: _padding),
                TextField(
                  controller: _reason,
                  maxLines: 4,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  style: AppTextStyles.weGatherPrimaryTextStyle,
                  decoration: InputDecoration(
                    hintText: l10n.community_reportReasonHint,
                    hintStyle: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
                      color: AppConfig.colorTertiary,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    fillColor: AppConfig.loginPageFormBgColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppConfig.loginPageFormBorderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppConfig.loginPageFormBorderColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _padding),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: l10n.community_reportConfirm,
                    onPressed: () =>
                        Navigator.of(context).pop(_reason.text.trim()),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.community_cancel,
                      style: AppTextStyles.weGatherTextButtonStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
