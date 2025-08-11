import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../config/app_config.dart';
import '../layouts/wegather_appbar.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/profile_widgets/social_media.dart';
import 'package:wegather_app/containers/liquid_button.dart';
import 'package:wegather_app/profile_widgets/profile_information.dart';
import 'package:wegather_app/profile_widgets/tagged_photos.dart';
import 'package:wegather_app/profile_widgets/shared_photos.dart';
import 'package:wegather_app/reusableWidgets/liquid_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:wegather_app/containers/liquid_container.dart';

class ProfileScreen extends StatefulWidget {
  final String profileId;

  const ProfileScreen({super.key, required this.profileId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  ProfileModel? profile;
  bool isLoading = true;
  String? error;

  int selectedIndex = 0;

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

  void onTapProfileDisplayButton(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void onChangeProfileImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Make bottom sheet background transparent
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LiquidContainer(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
                      title: AppLocalizations.of(context)!.profile_choose_from_gallery,
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
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
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
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
    return Scaffold(
      appBar: CustomAppBar(title: AppLocalizations.of(context)!.profile_title),
      body: Padding(padding: const EdgeInsets.all(11.0), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    if (profile == null) {
      return const Center(child: Text('Profile not found'));
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 27),
            Stack(
              children: [
                ClipOval(
                  child: profile!.profileImage.isNotEmpty
                      ? Image.network(
                          profile!.profileImage,
                          width: 178,
                          height: 178,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 178,
                              height: 178,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              AppConfig.noProfileImage,
                              width: 178,
                              height: 178,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          AppConfig.noProfileImage,
                          width: 178,
                          height: 178,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  bottom: 2,
                  right: 15,
                  child: GestureDetector(
                    onTap: onChangeProfileImage,
                    child: Image.asset(
                      AppConfig.cameraIcon,
                      width: 45,
                      height: 45,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 23.54),
            Text(
              profile!.name.toUpperCase(),
              style: AppTextStyles.smallTitleTextStyle,
            ),
            SizedBox(height: 6.46),
            Text(
              profile!.title,
              style: AppTextStyles.smallDescriptionTextStyle,
            ),
            SizedBox(height: 32),
            Center(child: buildSocialMediaButtons(profile?.socialMedia)),
            SizedBox(height: 40),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: LiquidButton(
                    isActive: selectedIndex == 0,
                    padding: EdgeInsets.fromLTRB(2, 11, 2, 11),
                    onTap: () {
                      onTapProfileDisplayButton(0);
                    },
                    child: Text(
                      "Bilgiler",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.lightButtonTextStyle,
                    ),
                  ),
                ),
                Expanded(
                  child: LiquidButton(
                    isActive: selectedIndex == 1,
                    padding: EdgeInsets.fromLTRB(2, 11, 2, 11),
                    onTap: () {
                      onTapProfileDisplayButton(1);
                    },
                    child: Text(
                      "Etiketlenenler",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.lightButtonTextStyle,
                    ),
                  ),
                ),
                Expanded(
                  child: LiquidButton(
                    isActive: selectedIndex == 2,
                    padding: EdgeInsets.fromLTRB(2, 11, 2, 11),
                    onTap: () {
                      onTapProfileDisplayButton(2);
                    },
                    child: Text(
                      "Paylaşılanlar",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.lightButtonTextStyle,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            selectedIndex == 0
                ? buildProfileInformation(profile)
                : selectedIndex == 1
                ? buildTaggedPhotos(profile)
                : buildSharedPhotos(profile),
            SizedBox(height: 30), // Bottom padding for scroll
          ],
        ),
      ),
    );
  }
}
