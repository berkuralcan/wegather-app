import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../models/support_model.dart';
import 'support_status_chip.dart';

/// One request in the participant's list: its subject, where it stands, a
/// preview of whatever was said last, and when.
///
/// The preview is the denormalized [SupportRequest.lastMessageText] rather than
/// a read of the thread, which is what lets this list draw from one query.
class SupportRequestTile extends StatelessWidget {
  const SupportRequestTile({
    super.key,
    required this.request,
    required this.onTap,
  });

  final SupportRequest request;
  final VoidCallback onTap;

  /// "2m" / "3h" / "5d" while that's what the user is reading it as, then a
  /// date. A list of conversations is scanned for how long something has been
  /// sitting, not for the calendar.
  String _formatWhen(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final minutes = DateTime.now().difference(date).inMinutes;
    if (minutes < 1) return '';
    if (minutes < 60) return '${minutes}m';
    if (minutes < 60 * 24) return '${(minutes / 60).round()}h';
    if (minutes < 60 * 24 * 7) return '${(minutes / (60 * 24)).round()}d';
    return MaterialLocalizations.of(context).formatShortDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final when = _formatWhen(context, request.lastMessageAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConfig.tipColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // A thread waiting on the support team is outlined rather than
            // merely chipped, so the queue reads at a glance.
            color: request.isAwaitingSupport
                ? AppConfig.emphasisColor.withValues(alpha: 0.4)
                : AppConfig.loginPageFormBorderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    request.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.weGatherSmallHeaderTextStyle,
                  ),
                ),
                if (when.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(when, style: AppTextStyles.weGatherSmallTextStyle),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Whose words the preview is, so a reply from the team is
                // obvious without opening the thread.
                if (request.lastMessageText.isNotEmpty)
                  Flexible(
                    child: Text(
                      request.lastMessageSenderRole == SupportSenderRole.admin
                          ? '${l10n.support_teamName}: ${request.lastMessageText}'
                          : '${l10n.support_you}: ${request.lastMessageText}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.weGatherSmallTextStyle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SupportStatusChip(request: request),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: AppConfig.emphasisColor,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
