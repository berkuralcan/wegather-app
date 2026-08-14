import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';

/// Where a piece of gallery media is about to come from.
enum AddMediaSource {
  /// A photo taken now, with the camera.
  photo,

  /// A video recorded now, with the camera.
  video,

  /// Something already on the device, picked from its library.
  library,
}

/// Asks where the media should come from: take a photo, record a video, or pick
/// something they already have.
///
/// [title] names what it is being added to, and defaults to the gallery — the
/// composer passes its own, since the same three choices add to a post there.
///
/// Resolves to null when they back out — tapping outside the sheet, dragging it
/// down, pressing back, or using the cancel button. That matters more here than
/// it looks: the system picker this sheet leads to is a full-screen activity of
/// the OS's own, so the last chance to change your mind without going through it
/// is *before* it opens.
Future<AddMediaSource?> showAddMediaSheet(
  BuildContext context, {
  String? title,
}) {
  return showModalBottomSheet<AddMediaSource>(
    context: context,
    // The sheet paints its own surface over the app's background gradient.
    backgroundColor: Colors.transparent,
    builder: (context) => _AddMediaSheet(title: title),
  );
}

class _AddMediaSheet extends StatelessWidget {
  const _AddMediaSheet({this.title});

  final String? title;

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
                title ?? l10n.gallery_addTitle,
                style: AppTextStyles.weGatherHeading2TextStyle,
              ),
              const SizedBox(height: _padding),
              _SourceOption(
                icon: Icons.photo_camera,
                label: l10n.gallery_addTakePhoto,
                source: AddMediaSource.photo,
              ),
              const SizedBox(height: 12),
              _SourceOption(
                icon: Icons.videocam,
                label: l10n.gallery_addRecordVideo,
                source: AddMediaSource.video,
              ),
              const SizedBox(height: 12),
              _SourceOption(
                icon: Icons.photo_library,
                label: l10n.gallery_addChooseExisting,
                source: AddMediaSource.library,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.gallery_addCancel,
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

/// One way of adding media: an icon, a label, and the source it closes with.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.source,
  });

  final IconData icon;
  final String label;
  final AddMediaSource source;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(source),
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
              Icon(icon, size: 24, color: AppConfig.menuIconColor),
              const SizedBox(width: 16),
              Text(label, style: AppTextStyles.weGatherLabelTextStyle),
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
