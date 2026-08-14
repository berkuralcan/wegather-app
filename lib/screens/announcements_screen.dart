import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/announcement_model.dart';
import 'package:wegather_app/providers/announcements_providers.dart';
import 'package:wegather_app/screens/announcement_detail_screen.dart';

/// The announcements of the current event as a flat list — the same layout as
/// the "Important Tips" screen (icon + title + chevron), tapping through to the
/// [AnnouncementDetailScreen]. Every row shows the same announcement icon used
/// on the home menu.
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final announcements = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.announcements_title),
      body: SafeArea(
        top: false,
        child: announcements.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) =>
              _CenteredText('${l10n.announcements_loadError}\n\n$error'),
          data: (list) {
            if (list.isEmpty) return _CenteredText(l10n.announcements_empty);
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _AnnouncementTile(announcement: list[index]),
            );
          },
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.announcement});

  final AnnouncementModel announcement;

  /// The announcement icon used on the home menu — reused here so every row
  /// carries the same glyph.
  static const String _iconPath =
      'assets/icons/default/modules/announcements.png';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: announcement),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConfig.tipColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConfig.loginPageFormBorderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Image.asset(_iconPath, width: 24, height: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: AppTextStyles.weGatherLabelTextStyle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppConfig.emphasisColor,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredText extends StatelessWidget {
  const _CenteredText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.weGatherParagraphTextStyle,
        ),
      ),
    );
  }
}
