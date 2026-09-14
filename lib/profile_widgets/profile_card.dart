import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../functions/global_functions.dart';
import '../global_widgets/wg_avatar.dart';
import '../l10n/app_localizations.dart';
import '../models/profile_model.dart';
import '../reusableWidgets/primary_button.dart';

/// Who somebody is, as one card: the photo and the identity on the gradient
/// half, the bio underneath.
///
/// The same card heads both profile screens — your own and somebody else's —
/// and what it lets you *do* is what tells them apart. On another person's
/// profile every callback is null and the card is a read-only introduction; on
/// your own, [onChangePhoto] makes the photo replaceable, [onShare] and
/// [onSaveDescription] add the pair of buttons under the bio, and the bio you
/// have not written yet reads as an invitation to write one rather than as
/// nothing at all.
///
/// Editing the bio happens here, in place: [onSaveDescription] turns the
/// paragraph into a field and back, so the one thing on the card that is worth
/// changing does not cost a trip to another screen.
class ProfileCard extends StatefulWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    this.onChangePhoto,
    this.onShare,
    this.onSaveDescription,
  });

  final ProfileModel profile;

  /// Called when the photo is tapped, to replace it — null on somebody else's
  /// profile, where the photo is theirs and not yours to change.
  final VoidCallback? onChangePhoto;

  /// Hands the profile to the platform's share sheet. Null hides the button.
  final VoidCallback? onShare;

  /// Writes an edited bio, resolving to whether the write went through: a
  /// failed one keeps the field open with the text still in it, rather than
  /// closing over changes that were never saved. Null leaves the bio read-only.
  final Future<bool> Function(String description)? onSaveDescription;

  /// Padding inside each half of the card.
  static const double padding = 16;

  /// Corner radius of the card and of its gradient half alike.
  static const double radius = 16;

  /// Diameter of the photo at the top of the card.
  static const double avatarSize = 80;

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  /// The bio being edited, or null when the card is showing it as a paragraph.
  TextEditingController? _editor;

  /// A save is in flight, so the field is frozen rather than closed — the text
  /// stays put if the write fails.
  bool _saving = false;

  @override
  void dispose() {
    _editor?.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _editor = TextEditingController(text: widget.profile.description ?? '');
    });
  }

  void _cancelEditing() {
    setState(() {
      _editor?.dispose();
      _editor = null;
    });
  }

  Future<void> _save() async {
    final editor = _editor;
    final onSave = widget.onSaveDescription;
    if (editor == null || onSave == null || _saving) return;

    setState(() => _saving = true);
    final saved = await onSave(editor.text.trim());
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) {
        editor.dispose();
        _editor = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = profileValueOrNull(widget.profile.description);
    // The invitation to write a bio only makes sense to the person who could
    // write one — somebody else's empty bio is simply left out.
    final isOwn = widget.onSaveDescription != null;
    final editor = _editor;

    return Container(
      decoration: BoxDecoration(
        color: AppConfig.primaryFillColor,
        borderRadius: BorderRadius.circular(ProfileCard.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            profile: widget.profile,
            onChangePhoto: widget.onChangePhoto,
          ),
          if (editor != null)
            Padding(
              padding: const EdgeInsets.all(ProfileCard.padding),
              child: _DescriptionEditor(
                controller: editor,
                saving: _saving,
                onCancel: _cancelEditing,
                onSave: _save,
              ),
            )
          else if (description != null || isOwn)
            Padding(
              padding: const EdgeInsets.all(ProfileCard.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    description ?? l10n.profile_descriptionEmpty,
                    style: AppTextStyles.weGatherParagraphTextStyle.copyWith(
                      // An unwritten bio is a prompt, not the user's words, so
                      // it sits back a shade from one they have written.
                      color: description == null
                          ? AppConfig.colorTertiary
                          : null,
                    ),
                  ),
                  if (isOwn || widget.onShare != null) ...[
                    const SizedBox(height: ProfileCard.padding),
                    _Actions(
                      onShare: widget.onShare,
                      onEdit: isOwn ? _startEditing : null,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The gradient half of the card: the photo, who the user is, and the icons
/// that reach them.
class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.onChangePhoto});

  final ProfileModel profile;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final title = profileValueOrNull(profile.title);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppConfig.fadedBackgroundGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ProfileCard.radius),
          topRight: Radius.circular(ProfileCard.radius),
        ),
      ),
      padding: const EdgeInsets.all(ProfileCard.padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onChangePhoto,
            child: WgAvatar(
              imageUrl: profile.profileImage,
              size: ProfileCard.avatarSize,
            ),
          ),
          const SizedBox(width: ProfileCard.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  profile.name,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.weGatherParagraphTextStyle,
                ),
                if (title != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.weGatherParagraphTextStyle.copyWith(
                      color: AppConfig.colorTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ProfileSocialLinks(profile: profile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The user's ways of being reached, as icons. Each is left out entirely when
/// the profile carries no value for it, so the row shrinks rather than showing
/// a dead icon.
class ProfileSocialLinks extends StatelessWidget {
  const ProfileSocialLinks({super.key, required this.profile});

  final ProfileModel profile;

  /// Side of one icon, and the gap between two of them.
  static const double _iconSize = 20;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    final socials = profile.socialMedia;
    final email = profileValueOrNull(profile.email);
    final website = profileValueOrNull(socials.website);
    final linkedIn = profileValueOrNull(socials.linkedIn);
    final instagram = profileValueOrNull(socials.instagram);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: _gap,
      children: [
        if (email != null)
          _SocialLink(
            asset: 'assets/icons/mail.svg',
            onTap: () => navigateToEmail(email),
          ),
        if (website != null)
          _SocialLink(
            asset: 'assets/icons/website.svg',
            onTap: () => navigateToWebsite(website),
          ),
        // LinkedIn and Instagram are stored as handles rather than addresses,
        // so they go through the helper that builds each network's URL.
        if (linkedIn != null)
          _SocialLink(
            asset: 'assets/icons/linkedin.svg',
            onTap: () => navigateToSocialMedia('linkedin', linkedIn),
          ),
        if (instagram != null)
          _SocialLink(
            asset: 'assets/icons/instagram.svg',
            onTap: () => navigateToSocialMedia('instagram', instagram),
          ),
      ],
    );
  }
}

class _SocialLink extends StatelessWidget {
  const _SocialLink({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SvgPicture.asset(
        asset,
        width: ProfileSocialLinks._iconSize,
        height: ProfileSocialLinks._iconSize,
      ),
    );
  }
}

/// The pair of buttons under your own bio: sharing the profile takes the width
/// it can, editing it stays a compact affordance beside it.
class _Actions extends StatelessWidget {
  const _Actions({required this.onShare, required this.onEdit});

  final VoidCallback? onShare;
  final VoidCallback? onEdit;

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        if (onShare != null)
          Expanded(
            child: PrimaryButton(
              label: l10n.profile_shareProfile,
              icon: SvgPicture.asset(
                'assets/icons/share.svg',
                width: 16,
                height: 16,
              ),
              minHeight: _height,
              onPressed: onShare,
            ),
          ),
        if (onShare != null && onEdit != null) const SizedBox(width: 12),
        if (onEdit != null)
          _EditButton(label: l10n.profile_edit, onPressed: onEdit!),
      ],
    );
  }
}

/// The outlined counterpart to [PrimaryButton] — the quieter of the two
/// actions, so it is drawn as an outline rather than a filled pill.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConfig.emphasisColor,
        side: const BorderSide(color: AppConfig.emphasisColor),
        minimumSize: const Size(0, _Actions._height),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.weGatherPrimaryTextStyle,
      ),
    );
  }
}

/// The bio, open for editing in the card itself.
class _DescriptionEditor extends StatelessWidget {
  const _DescriptionEditor({
    required this.controller,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileTextField(
          controller: controller,
          hint: l10n.profile_descriptionHint,
          enabled: !saving,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: ProfileTextField.descriptionMaxLength,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConfig.colorTertiary,
                  side: const BorderSide(
                    color: AppConfig.loginPageFormBorderColor,
                  ),
                  minimumSize: const Size(0, _Actions._height),
                  shape: const StadiumBorder(),
                  textStyle: AppTextStyles.weGatherPrimaryTextStyle,
                ),
                child: Text(l10n.profile_cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: l10n.profile_save,
                minHeight: _Actions._height,
                // Disabled rather than merely guarded, so a second tap can't
                // start a second write.
                onPressed: saving ? null : onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A filled, rounded text field in the app's form style — the same decoration
/// the support and report sheets use, so every form is shaped alike.
class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final bool enabled;
  final bool autofocus;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  /// A bio is a paragraph, not an essay — long enough to introduce yourself,
  /// short enough that the card stays a card.
  static const int descriptionMaxLength = 500;

  /// A handle or an address; the cap is a guard against a runaway paste.
  static const int linkMaxLength = 200;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppConfig.loginPageFormBorderColor),
    );

    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: AppTextStyles.weGatherPrimaryTextStyle,
      cursorColor: AppConfig.emphasisColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
          color: AppConfig.colorTertiary,
        ),
        // The limit is a guard against a runaway paste, not a word count to
        // watch while typing.
        counterText: '',
        contentPadding: const EdgeInsets.all(12),
        fillColor: AppConfig.loginPageFormBgColor,
        filled: true,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        disabledBorder: border,
      ),
    );
  }
}

/// A profile field the panel may have left as an empty string as readily as
/// omitted — null unless there is something to show.
String? profileValueOrNull(String? value) =>
    value != null && value.trim().isNotEmpty ? value : null;
