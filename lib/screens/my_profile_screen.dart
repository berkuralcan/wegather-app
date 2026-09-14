import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../auth_services.dart';
import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../functions/global_functions.dart';
import '../global_widgets/wg_menu_tile.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../models/profile_model.dart';
import '../profile_widgets/profile_card.dart';
import '../providers/profile_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';

/// Your own profile: the card that introduces you, then the sections of the
/// event that are yours — your details, your code, your hotel, your transfers,
/// your flights.
///
/// A different screen from `ProfileScreen`, which is what everybody *else's*
/// profile looks like. Theirs is something to read; yours is something to
/// manage, so it is a menu rather than a set of tabs. The two things you can
/// change from here are the photo (tap it) and the bio (the Edit button under
/// it, which opens the field in place); the pencil in the bar opens the fuller
/// edit screen, where your links live too.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  static const double _padding = 16;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.profile_myProfileTitle,
        // Your own profile is a place you are, not a page you opened, so its
        // title starts at the leading edge rather than sitting centred.
        centerTitle: false,
        // The pencil where a settings gear would sit: on your own profile the
        // thing you came to do is change it.
        trailing: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push('/profile/edit'),
          child: Tooltip(
            message: l10n.profile_editTitle,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.edit_outlined,
                size: 24,
                color: AppConfig.lightIconColor,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) =>
              _CenteredText('${l10n.profile_loadError}\n\n$error'),
          data: (profile) {
            if (profile == null) return _CenteredText(l10n.profile_notFound);
            return _Body(
              profile: profile,
              onChangePhoto: _changePhoto,
              onShare: () => _share(profile),
              onSaveDescription: _saveDescription,
            );
          },
        ),
      ),
    );
  }

  void _showError(String message) {
    showLiquidSnackBar(
      context,
      message,
      icon: Icons.error,
      iconColor: Colors.red,
    );
  }

  /// Writes the bio edited in place on the card, and reports whether it landed
  /// so the card knows to close the field or keep it open.
  Future<bool> _saveDescription(String description) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(profileServiceProvider)
          .updateOwnProfile(description: description);
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        showLiquidSnackBar(
          context,
          l10n.profile_saved,
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
      return true;
    } catch (_) {
      if (mounted) _showError(l10n.profile_saveError);
      return false;
    }
  }

  /// Hands the profile to the platform's share sheet as the text of it — the
  /// name, what the person does, their bio and their links — since a profile
  /// inside the app is not an address anybody outside it could open.
  Future<void> _share(ProfileModel profile) async {
    final l10n = AppLocalizations.of(context)!;
    final socials = profile.socialMedia;
    final linkedIn = profileValueOrNull(socials.linkedIn);
    final instagram = profileValueOrNull(socials.instagram);

    final lines = <String?>[
      profile.name,
      profileValueOrNull(profile.title),
      profileValueOrNull(profile.description),
      profileValueOrNull(profile.email),
      // Handles are shared as the addresses they stand for, so what lands in
      // the message is something the person reading it can open.
      if (linkedIn != null) socialMediaUrl('linkedin', linkedIn),
      if (instagram != null) socialMediaUrl('instagram', instagram),
      profileValueOrNull(socials.website),
      profileValueOrNull(socials.portfolio),
    ].nonNulls.toList(growable: false);

    try {
      await SharePlus.instance.share(ShareParams(text: lines.join('\n')));
    } catch (_) {
      if (mounted) _showError(l10n.profile_shareError);
    }
  }

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      // The sheet paints its own surface over the app's background gradient.
      backgroundColor: Colors.transparent,
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (source == null || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    try {
      final imageFile = await ImagePicker().pickImage(source: source);
      if (imageFile == null || !mounted) return;

      showLiquidSnackBar(
        context,
        l10n.profile_photoUploading,
        icon: Icons.cloud_upload,
        iconColor: Colors.blue,
      );

      await ref
          .read(profileServiceProvider)
          .uploadProfileImage(File(imageFile.path));
      ref.invalidate(currentProfileProvider);

      if (mounted) {
        showLiquidSnackBar(
          context,
          l10n.profile_photoUpdated,
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } catch (_) {
      if (mounted) _showError(l10n.profile_photoError);
    }
  }
}

/// The page under the bar: the card, then the menu.
class _Body extends StatelessWidget {
  const _Body({
    required this.profile,
    required this.onChangePhoto,
    required this.onShare,
    required this.onSaveDescription,
  });

  final ProfileModel profile;
  final VoidCallback onChangePhoto;
  final VoidCallback onShare;
  final Future<bool> Function(String description) onSaveDescription;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Every row goes to a screen of its own, so the menu is a list of routes
    // paired with the icon that names each one.
    final sections = <_Section>[
      _Section(
        icon: 'assets/icons/user-information.svg',
        label: l10n.profile_menuInformation,
        route: '/profile/information',
      ),
      _Section(
        icon: 'assets/icons/qr-code.svg',
        label: l10n.profile_menuQrCode,
        route: '/profile/qr',
      ),
      _Section(
        icon: 'assets/icons/profile-hotel.svg',
        label: l10n.profile_menuAccommodation,
        route: '/profile/accommodation',
      ),
      _Section(
        icon: 'assets/icons/profile-transportation.svg',
        label: l10n.profile_menuTransportation,
        route: '/profile/transportation',
      ),
      _Section(
        icon: 'assets/icons/profile-flights.svg',
        label: l10n.profile_menuFlights,
        route: '/profile/flights',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        _MyProfileScreenState._padding,
        8,
        _MyProfileScreenState._padding,
        24,
      ),
      children: [
        ProfileCard(
          profile: profile,
          onChangePhoto: onChangePhoto,
          onShare: onShare,
          onSaveDescription: onSaveDescription,
        ),
        const SizedBox(height: 24),
        for (final section in sections) ...[
          WgMenuTile(
            icon: SvgPicture.asset(
              section.icon,
              width: WgMenuTile.iconSize,
              height: WgMenuTile.iconSize,
            ),
            label: section.label,
            onTap: () => context.push(section.route),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        // TODO - Temporary: signing out belongs in a settings screen.
        TextButton.icon(
          onPressed: () => AuthService().signOut(),
          icon: const Icon(Icons.logout),
          label: Text(l10n.profile_signOut),
        ),
      ],
    );
  }
}

/// One row of the profile menu.
class _Section {
  const _Section({
    required this.icon,
    required this.label,
    required this.route,
  });

  final String icon;
  final String label;
  final String route;
}

/// Asks where a new profile photo should come from.
class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.profile_change_profile_photo,
              style: AppTextStyles.smallTitleTextStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            _PhotoSourceOption(
              icon: Icons.photo_camera,
              title: l10n.profile_take_photo,
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _PhotoSourceOption(
              icon: Icons.photo_library,
              title: l10n.profile_choose_from_gallery,
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PhotoSourceOption extends StatelessWidget {
  const _PhotoSourceOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: AppTextStyles.lightButtonTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
