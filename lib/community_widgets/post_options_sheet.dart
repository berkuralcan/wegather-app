import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';

/// What the sheet behind a post's ellipsis can be closed with.
///
/// Only reporting for now; the sheet exists so the rest — hiding a post, copying
/// a link, deleting your own — has somewhere to land.
enum PostOption {
  /// Flag the post for the admin panel to moderate.
  report,
}

/// The options behind a post's ellipsis, as a bottom sheet.
///
/// Resolves to null when they back out — tapping outside, dragging it down, the
/// back gesture, or the cancel button. [isReported] dims the report row for a
/// post that has already been flagged: reporting it twice adds nothing for the
/// team reading the reports.
Future<PostOption?> showPostOptionsSheet(
  BuildContext context, {
  bool isReported = false,
}) {
  return showModalBottomSheet<PostOption>(
    context: context,
    // The sheet paints its own surface over the app's background gradient.
    backgroundColor: Colors.transparent,
    builder: (context) => _PostOptionsSheet(isReported: isReported),
  );
}

class _PostOptionsSheet extends StatelessWidget {
  const _PostOptionsSheet({required this.isReported});

  final bool isReported;

  static const double _padding = 16;
  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
                l10n.community_options,
                style: AppTextStyles.weGatherHeading2TextStyle,
              ),
              const SizedBox(height: _padding),
              _OptionRow(
                asset: 'assets/icons/report.svg',
                label: isReported
                    ? l10n.community_reportedAlready
                    : l10n.community_report,
                option: PostOption.report,
                enabled: !isReported,
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
    );
  }
}

/// One option: an icon, a label, and the value it closes the sheet with.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.asset,
    required this.label,
    required this.option,
    this.enabled = true,
  });

  final String asset;
  final String label;
  final PostOption option;

  /// A disabled row is dimmed and inert — the option is shown so it's clear why
  /// it can't be used, rather than disappearing.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppConfig.menuIconColor : AppConfig.colorTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => Navigator.of(context).pop(option) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: AppConfig.loginPageFormBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppConfig.loginPageFormBorderColor),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                asset,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: AppTextStyles.weGatherLabelTextStyle.copyWith(
                  color: color,
                ),
              ),
            ],
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
