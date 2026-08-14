import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wegather_app/auth_services.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/functions/global_functions.dart';
import 'package:wegather_app/global_widgets/wg_avatar.dart';
import 'package:wegather_app/global_widgets/wg_info_row.dart';
import 'package:wegather_app/global_widgets/wg_tab_view.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/profile_model.dart';
import 'package:wegather_app/reusableWidgets/liquid_snackbar.dart';
import 'package:wegather_app/services/profile_service.dart';

/// A user's profile: who they are, how to reach them, and what they have posted.
///
/// Everything sits in one card — the photo and identity on the gradient half,
/// the bio and the tabs below it — laid out like the participant detail screen,
/// which shows the same kind of person from the event's roster instead.
///
/// The same screen serves your own profile and somebody else's — a post's author,
/// reached from the community feed. What you may *do* here is what differs:
/// replacing the photo and signing out are yours alone, so on anyone else's
/// profile the screen is a read-only view of them.
class ProfileScreen extends StatefulWidget {
  final String profileId;

  const ProfileScreen({super.key, required this.profileId});

  /// Padding around the page's content, and inside each half of the card.
  static const double _padding = 16;

  /// Corner radius of the card and of its gradient half alike.
  static const double _radius = 16;

  /// Diameter of the photo at the top of the card.
  static const double _avatarSize = 80;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  ProfileModel? profile;
  bool isLoading = true;
  String? error;

  _ProfileTab _tab = _ProfileTab.about;

  /// Whether this is the signed-in user looking at themselves, which is what
  /// gates every action on the page.
  bool get _isOwnProfile => AuthService().currentUser?.uid == widget.profileId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profileData = await _profileService.getProfile(widget.profileId);
      setState(() {
        profile = profileData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void onChangeProfileImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Make bottom sheet background transparent
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  AppLocalizations.of(context)!.profile_change_profile_photo,
                  style: AppTextStyles.smallTitleTextStyle.copyWith(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                // Custom button for camera
                _buildImagePickerOption(
                  icon: Icons.photo_camera,
                  title: AppLocalizations.of(context)!.profile_take_photo,
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                // Custom button for gallery
                _buildImagePickerOption(
                  icon: Icons.photo_library,
                  title: AppLocalizations.of(
                    context,
                  )!.profile_choose_from_gallery,
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? imageFile = await imagePicker.pickImage(source: source);

      if (imageFile != null) {
        // Show loading indicator while uploading
        if (mounted) {
          showLiquidSnackBar(
            context,
            'Uploading image...',
            icon: Icons.cloud_upload,
            iconColor: Colors.blue,
          );
        }

        final imageUrl = await _profileService.uploadProfileImage(
          File(imageFile.path),
        );

        if (mounted) {
          setState(() {
            profile = profile!.copyWith(profileImage: imageUrl);
          });

          showLiquidSnackBar(
            context,
            'Profile image updated successfully!',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showLiquidSnackBar(
          context,
          'Error updating profile image: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = profile?.name;
    return Scaffold(
      // Somebody else's profile is titled with their name; your own stays
      // "Profile", since you know whose it is.
      appBar: CustomAppBar(
        title: (!_isOwnProfile && name != null && name.trim().isNotEmpty)
            ? name
            : AppLocalizations.of(context)!.profile_title,
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    final profile = this.profile;
    if (profile == null) {
      return const Center(child: Text('Profile not found'));
    }

    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ProfileScreen._padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Card(
            profile: profile,
            onChangePhoto: _isOwnProfile ? onChangeProfileImage : null,
          ),
          const SizedBox(height: 8),
          // The tabs and whichever one is open sit on the page itself, so only
          // the identity and the bio read as a card.
          WgTabView(
            labels: [l10n.profile_tabAbout, l10n.profile_tabPosts],
            selectedIndex: _tab.index,
            onSelected: (index) =>
                setState(() => _tab = _ProfileTab.values[index]),
            child: switch (_tab) {
              _ProfileTab.about => _AboutTab(profile: profile),
              _ProfileTab.posts => const _PostsTab(),
            },
          ),
          if (_isOwnProfile) ...[
            const SizedBox(height: 24),
            // TODO - Temporary: signing out belongs in a settings screen.
            TextButton.icon(
              onPressed: () => AuthService().signOut(),
              icon: const Icon(Icons.logout),
              label: const Text("Çıkış Yap"),
            ),
          ],
        ],
      ),
    );
  }
}

/// Which of the two pages under the tabs is showing.
enum _ProfileTab { about, posts }

/// The profile card: the identity on its gradient half, the bio under it.
class _Card extends StatelessWidget {
  const _Card({required this.profile, required this.onChangePhoto});

  final ProfileModel profile;

  /// Called when the photo is tapped, to replace it — null on somebody else's
  /// profile, where the photo is theirs and not yours to change.
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final description = _set(profile.description);

    return Container(
      decoration: BoxDecoration(
        color: AppConfig.primaryFillColor,
        borderRadius: BorderRadius.circular(ProfileScreen._radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(profile: profile, onChangePhoto: onChangePhoto),
          if (description != null)
            Padding(
              padding: const EdgeInsets.all(ProfileScreen._padding),
              child: Text(
                description,
                style: AppTextStyles.weGatherParagraphTextStyle,
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
    final title = _set(profile.title);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppConfig.fadedBackgroundGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ProfileScreen._radius),
          topRight: Radius.circular(ProfileScreen._radius),
        ),
      ),
      padding: const EdgeInsets.all(ProfileScreen._padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onChangePhoto,
            child: WgAvatar(
              imageUrl: profile.profileImage,
              size: ProfileScreen._avatarSize,
            ),
          ),
          const SizedBox(width: ProfileScreen._padding),
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
                _SocialLinks(profile: profile),
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
class _SocialLinks extends StatelessWidget {
  const _SocialLinks({required this.profile});

  final ProfileModel profile;

  /// Side of one icon, and the gap between two of them.
  static const double _iconSize = 20;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    final socials = profile.socialMedia;
    final email = _set(profile.email);
    final website = _set(socials.website);
    final linkedIn = _set(socials.linkedIn);
    final instagram = _set(socials.instagram);

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
        width: _SocialLinks._iconSize,
        height: _SocialLinks._iconSize,
      ),
    );
  }
}

/// The About tab: who the user is, and where to find them online.
class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.profile});

  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final socials = profile.socialMedia;
    final name = _set(profile.name);
    final title = _set(profile.title);
    final company = _set(profile.company);
    final email = _set(profile.email);
    final phone = _set(profile.phone);
    final linkedIn = _set(socials.linkedIn);
    final instagram = _set(socials.instagram);
    final portfolio = _set(socials.portfolio);
    final website = _set(socials.website);
    final hasSocials =
        linkedIn != null ||
        instagram != null ||
        portfolio != null ||
        website != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Info', style: AppTextStyles.weGatherHeaderTextStyle),
        // Every row below is optional on the model, so each one collapses
        // entirely — rather than showing a placeholder — when unset.
        if (name != null) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: 'Full Name', information: name),
        ],
        if (title != null) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: 'Title', information: title),
        ],
        if (company != null) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: 'Company', information: company),
        ],
        if (email != null) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: 'Email Address', information: email),
        ],
        if (phone != null) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: 'Contact Number', information: phone),
        ],
        // The whole section — divider, heading and rows alike — collapses when
        // the user has no link at all.
        if (hasSocials) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppConfig.dividerNonOpaqueColor),
          const SizedBox(height: 16),
          Text('Social Profiles', style: AppTextStyles.weGatherHeaderTextStyle),
          if (linkedIn != null) ...[
            const SizedBox(height: 16),
            WgInfoRow(
              title: 'LinkedIn',
              information: linkedIn,
              icon: 'linkedin',
              onTap: () => navigateToSocialMedia('linkedin', linkedIn),
            ),
          ],
          if (instagram != null) ...[
            const SizedBox(height: 16),
            WgInfoRow(
              title: 'Instagram',
              information: instagram,
              icon: 'instagram',
              onTap: () => navigateToSocialMedia('instagram', instagram),
            ),
          ],
          if (portfolio != null) ...[
            const SizedBox(height: 16),
            WgInfoRow(
              title: 'Portfolio',
              information: portfolio,
              icon: 'portfolio',
              onTap: () => navigateToWebsite(portfolio),
            ),
          ],
          if (website != null) ...[
            const SizedBox(height: 16),
            WgInfoRow(
              title: 'Website',
              information: website,
              icon: 'website',
              onTap: () => navigateToWebsite(website),
            ),
          ],
        ],
      ],
    );
  }
}

/// The Posts tab, until there are posts to put in it.
class _PostsTab extends StatelessWidget {
  const _PostsTab();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context)!.profile_postsEmpty,
      style: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
        color: AppConfig.colorTertiary,
      ),
    );
  }
}

/// A field the panel may have left as an empty string as readily as omitted —
/// null unless there is something to show.
String? _set(String? value) =>
    value != null && value.trim().isNotEmpty ? value : null;
