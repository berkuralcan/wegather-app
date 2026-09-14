import 'package:flutter/material.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/global_widgets/wg_tab_view.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/profile_model.dart';
import 'package:wegather_app/profile_widgets/profile_card.dart';
import 'package:wegather_app/profile_widgets/profile_details.dart';
import 'package:wegather_app/screens/my_profile_screen.dart';
import 'package:wegather_app/services/profile_service.dart';

/// Somebody else's profile: who they are, how to reach them, and what they have
/// posted.
///
/// Everything sits in one card — the photo and identity on the gradient half,
/// the bio and the tabs below it — laid out like the participant detail screen,
/// which shows the same kind of person from the event's roster instead.
///
/// This is the outside view, and read-only by design: it is reached by tapping
/// a post's author in the community feed, and nothing on it is yours to change.
/// Your own profile is [MyProfileScreen] instead — a different screen entirely,
/// since what you do there is manage yourself rather than read about somebody.
class ProfileScreen extends StatefulWidget {
  final String profileId;

  const ProfileScreen({super.key, required this.profileId});

  /// Padding around the page's content.
  static const double _padding = 16;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  ProfileModel? profile;
  bool isLoading = true;
  String? error;

  _ProfileTab _tab = _ProfileTab.about;

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

  @override
  Widget build(BuildContext context) {
    final name = profile?.name;
    // The page is titled with whose it is, falling back to "Profile" until the
    // document has loaded.
    return Scaffold(
      appBar: CustomAppBar(
        title: (name != null && name.trim().isNotEmpty)
            ? name
            : AppLocalizations.of(context)!.profile_title,
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('${l10n.profile_loadError}\n\n$error'));
    }

    final profile = this.profile;
    if (profile == null) {
      return Center(child: Text(l10n.profile_notFound));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ProfileScreen._padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileCard(profile: profile),
          const SizedBox(height: 8),
          // The tabs and whichever one is open sit on the page itself, so only
          // the identity and the bio read as a card.
          WgTabView(
            labels: [l10n.profile_tabAbout, l10n.profile_tabPosts],
            selectedIndex: _tab.index,
            onSelected: (index) =>
                setState(() => _tab = _ProfileTab.values[index]),
            child: switch (_tab) {
              _ProfileTab.about => ProfileDetails(profile: profile),
              _ProfileTab.posts => const _PostsTab(),
            },
          ),
        ],
      ),
    );
  }
}

/// Which of the two pages under the tabs is showing.
enum _ProfileTab { about, posts }

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
