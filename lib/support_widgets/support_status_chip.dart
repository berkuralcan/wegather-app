import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../models/support_model.dart';

/// Where a request stands, as a small chip.
///
/// Three states, and the colour carries the meaning: waiting on the support team
/// is the emphasis blue (something is owed to you), answered is the plain accent
/// (your turn), resolved is muted (nothing to do). The text is what actually
/// distinguishes them — the chips stay legible without the colour.
class SupportStatusChip extends StatelessWidget {
  const SupportStatusChip({super.key, required this.request});

  final SupportRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (label, color) = switch (request) {
      final r when r.isResolved => (
        l10n.support_statusResolved,
        AppConfig.colorTertiary,
      ),
      final r when r.isAwaitingSupport => (
        l10n.support_statusAwaiting,
        AppConfig.emphasisColor,
      ),
      _ => (l10n.support_statusAnswered, AppConfig.accentColor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.weGatherSmallTextStyle.copyWith(color: color),
      ),
    );
  }
}
