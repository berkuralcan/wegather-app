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
                Image.asset(AppConfig.noProfileImage, width: 178, height: 178), // TODO: Display a profile image if there is one.
                Positioned(
                  bottom: 5,
                  right: 25,
                  child: Image.asset(AppConfig.cameraIcon, width: 45, height: 45),
                ),
              ],
            ),
            SizedBox(height: 23.54),
            Text(
              profile!.name.toUpperCase(),
              style: AppTextStyles.smallTitleTextStyle,
            ),
            SizedBox(height: 6.46),
            Text(profile!.title, style: AppTextStyles.smallDescriptionTextStyle),
            SizedBox(height: 32),
            Center(
              child: buildSocialMediaButtons(profile?.socialMedia),
            ),
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
                    child: Text("Bilgiler", textAlign: TextAlign.center, style: AppTextStyles.lightButtonTextStyle),
                  ),
                ),
                Expanded(
                  child: LiquidButton(
                    isActive: selectedIndex == 1,
                    padding: EdgeInsets.fromLTRB(2, 11, 2, 11),
                    onTap: () {
                      onTapProfileDisplayButton(1);
                    },
                    child: Text("Etiketlenenler", textAlign: TextAlign.center, style: AppTextStyles.lightButtonTextStyle),
                  ),
                ),
                Expanded(
                  child: LiquidButton(
                    isActive: selectedIndex == 2,
                    padding: EdgeInsets.fromLTRB(2, 11, 2, 11),
                    onTap: () {
                      onTapProfileDisplayButton(2);
                    },
                    child: Text("Paylaşılanlar", textAlign: TextAlign.center, style: AppTextStyles.lightButtonTextStyle),
                  ),
                ),
              ]
            ),
            SizedBox(height: 15),
            selectedIndex == 0 ? buildProfileInformation(profile) : selectedIndex == 1 ? buildTaggedPhotos(profile) : buildSharedPhotos(profile),
            SizedBox(height: 30), // Bottom padding for scroll
          ],
        ),
      ),
    );
  }
}
