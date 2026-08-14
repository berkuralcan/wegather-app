import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/functions/global_functions.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/announcement_model.dart';

/// The detail view of a single announcement: the title (in the app bar), the
/// featured image if there is one, the content, and — when set — a link that
/// opens in the browser. Uses the same rounded-image and paragraph styles as the
/// tip displayers.
class AnnouncementDetailScreen extends StatelessWidget {
  const AnnouncementDetailScreen({super.key, required this.announcement});

  final AnnouncementModel announcement;

  /// Matches the tip tiles' corner radius so images read as the same family.
  static const double _imageRadius = 16;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(title: announcement.title),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (announcement.hasFeaturedImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(_imageRadius),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: announcement.featuredImage,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(
                        color: Colors.black12,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: Colors.black12,
                        child: Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                announcement.content,
                style: AppTextStyles.weGatherParagraphTextStyle,
              ),
              if (announcement.hasUrl) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => navigateToUrl(announcement.url),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(
                    l10n.announcement_openLink,
                    style: AppTextStyles.weGatherColoredTextButtonStyle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
