import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../models/profile_model.dart';
import '../profile_widgets/profile_card.dart';
import '../providers/profile_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';
import '../reusableWidgets/primary_button.dart';

/// The fuller edit of your own profile, opened by the pencil in the bar: the
/// bio at the top, then the accounts other attendees can find you on.
///
/// Only the parts of the document a participant owns are here. Their name,
/// title, company and contact details come from the organisers, so those are
/// shown on "My Personal Information" and are not editable in the app.
///
/// A second section is coming — hence the sections rather than one flat form —
/// but it is not built yet.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  static const double _padding = 16;

  final TextEditingController _description = TextEditingController();
  final TextEditingController _linkedIn = TextEditingController();
  final TextEditingController _instagram = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _portfolio = TextEditingController();

  /// The profile the fields were filled from. Kept so a save writes back the
  /// links the app does not edit — Facebook and Twitter, which predate this
  /// design — rather than dropping them.
  ProfileModel? _loaded;

  bool _saving = false;

  @override
  void dispose() {
    _description.dispose();
    _linkedIn.dispose();
    _instagram.dispose();
    _website.dispose();
    _portfolio.dispose();
    super.dispose();
  }

  /// Fills the fields the first time the profile arrives, and never again — so
  /// a rebuild cannot overwrite what is being typed.
  void _fill(ProfileModel profile) {
    if (_loaded != null) return;
    _loaded = profile;
    _description.text = profile.description ?? '';
    _linkedIn.text = profile.socialMedia.linkedIn ?? '';
    _instagram.text = profile.socialMedia.instagram ?? '';
    _website.text = profile.socialMedia.website ?? '';
    _portfolio.text = profile.socialMedia.portfolio ?? '';
  }

  Future<void> _save() async {
    final loaded = _loaded;
    if (_saving || loaded == null) return;
    final l10n = AppLocalizations.of(context)!;

    /// An emptied field means "I have no such account", so it is written back
    /// as null rather than left at its old value.
    String? entered(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(profileServiceProvider)
          .updateOwnProfile(
            description: _description.text.trim(),
            socialMedia: ProfileSocialMedia(
              linkedIn: entered(_linkedIn),
              instagram: entered(_instagram),
              website: entered(_website),
              portfolio: entered(_portfolio),
              // Not editable here, but carried through so a save doesn't erase
              // whatever the panel put there.
              facebook: loaded.socialMedia.facebook,
              twitter: loaded.socialMedia.twitter,
            ),
          );
      ref.invalidate(currentProfileProvider);

      if (!mounted) return;
      showLiquidSnackBar(
        context,
        l10n.profile_saved,
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showLiquidSnackBar(
        context,
        l10n.profile_saveError,
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.profile_editTitle),
      body: SafeArea(
        top: false,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) => _CenteredText(
            '${l10n.profile_loadError}\n\n$error',
          ),
          data: (profile) {
            if (profile == null) return _CenteredText(l10n.profile_notFound);
            _fill(profile);
            return _Form(
              description: _description,
              linkedIn: _linkedIn,
              instagram: _instagram,
              website: _website,
              portfolio: _portfolio,
              saving: _saving,
              onSave: _save,
            );
          },
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.description,
    required this.linkedIn,
    required this.instagram,
    required this.website,
    required this.portfolio,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController description;
  final TextEditingController linkedIn;
  final TextEditingController instagram;
  final TextEditingController website;
  final TextEditingController portfolio;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        _ProfileEditScreenState._padding,
        0,
        _ProfileEditScreenState._padding,
        24,
      ),
      children: [
        _Label(l10n.profile_descriptionLabel),
        ProfileTextField(
          controller: description,
          hint: l10n.profile_descriptionHint,
          enabled: !saving,
          minLines: 3,
          maxLines: 6,
          maxLength: ProfileTextField.descriptionMaxLength,
        ),
        const SizedBox(height: 24),

        Text(
          l10n.profile_socialMedia,
          style: AppTextStyles.weGatherHeaderTextStyle,
        ),
        const SizedBox(height: 16),
        const _Label('LinkedIn'),
        _LinkField(
          controller: linkedIn,
          hint: l10n.profile_linkedInHint,
          enabled: !saving,
        ),
        const SizedBox(height: 16),
        const _Label('Instagram'),
        _LinkField(
          controller: instagram,
          hint: l10n.profile_instagramHint,
          enabled: !saving,
        ),
        const SizedBox(height: 16),
        const _Label('Website'),
        _LinkField(
          controller: website,
          hint: l10n.profile_websiteHint,
          enabled: !saving,
        ),
        const SizedBox(height: 16),
        const _Label('Portfolio'),
        _LinkField(
          controller: portfolio,
          hint: l10n.profile_portfolioHint,
          enabled: !saving,
          isLast: true,
        ),
        const SizedBox(height: 24),

        PrimaryButton(
          label: l10n.profile_save,
          // Disabled rather than merely guarded, so a second tap can't start a
          // second write.
          onPressed: saving ? null : onSave,
        ),
      ],
    );
  }
}

/// An address or a handle: never capitalised, and typed on the URL keyboard.
class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.controller,
    required this.hint,
    required this.enabled,
    this.isLast = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return ProfileTextField(
      controller: controller,
      hint: hint,
      enabled: enabled,
      maxLength: ProfileTextField.linkMaxLength,
      keyboardType: TextInputType.url,
      textCapitalization: TextCapitalization.none,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.weGatherSmallTextStyle),
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
