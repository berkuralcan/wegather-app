import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../providers/profile_providers.dart';

/// "My QR Code": the code that says who you are, for whoever at the event needs
/// to know — the desk handing out badges, the door of a session.
///
/// It encodes [profileUri] — the app's own address for a person — rather than
/// the bare id, so a scanner has something it can recognise as a WeGather
/// profile rather than an opaque string.
class ProfileQrScreen extends ConsumerWidget {
  const ProfileQrScreen({super.key});

  /// How a profile is addressed outside the app.
  static Uri profileUri(String profileId) =>
      Uri(scheme: 'wegather', host: 'profile', path: '/$profileId');

  /// Side of the code itself. Large enough to scan across a desk, and capped so
  /// it stays square on a small screen.
  static const double _codeSize = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.profile_menuQrCode),
      body: SafeArea(
        top: false,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) =>
              _CenteredText('${l10n.profile_loadError}\n\n$error'),
          data: (profile) {
            if (profile == null) return _CenteredText(l10n.profile_notFound);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        // Codes are read off a light ground, so the card under
                        // this one is white rather than the app's dark surface.
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: profileUri(profile.id).toString(),
                        size: _codeSize,
                        backgroundColor: Colors.white,
                        // A logo or a scuffed screen can cost part of the code;
                        // the highest correction level survives that.
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    profile.name,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.weGatherMediumHeaderTextStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profile_qrHint,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.weGatherParagraphTextStyle.copyWith(
                      color: AppConfig.colorTertiary,
                    ),
                  ),
                ],
              ),
            );
          },
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
