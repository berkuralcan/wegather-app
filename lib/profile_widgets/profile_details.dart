import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../functions/global_functions.dart';
import '../global_widgets/wg_info_row.dart';
import '../l10n/app_localizations.dart';
import '../models/profile_model.dart';
import 'profile_card.dart';

/// Everything a profile holds beyond the card at the top of it: who the person
/// is, how to reach them, and where to find them online.
///
/// Every row is optional on the model, so each collapses entirely — rather than
/// showing a placeholder — when unset, and the social section takes its heading
/// and divider with it when there is no link at all. The same list serves
/// somebody else's profile (under the About tab) and your own "My Personal
/// Information" screen, since it is the same set of facts either way.
class ProfileDetails extends StatelessWidget {
  const ProfileDetails({super.key, required this.profile, this.emptyText});

  final ProfileModel profile;

  /// What to show instead of the list when the profile carries none of these
  /// fields. Null renders nothing at all, which is what the About tab wants —
  /// it already sits under a card that says who the person is.
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final socials = profile.socialMedia;
    final name = profileValueOrNull(profile.name);
    final title = profileValueOrNull(profile.title);
    final company = profileValueOrNull(profile.company);
    final email = profileValueOrNull(profile.email);
    final phone = profileValueOrNull(profile.phone);
    final linkedIn = profileValueOrNull(socials.linkedIn);
    final instagram = profileValueOrNull(socials.instagram);
    final portfolio = profileValueOrNull(socials.portfolio);
    final website = profileValueOrNull(socials.website);

    final hasPersonal =
        name != null ||
        title != null ||
        company != null ||
        email != null ||
        phone != null;
    final hasSocials =
        linkedIn != null ||
        instagram != null ||
        portfolio != null ||
        website != null;

    if (!hasPersonal && !hasSocials && emptyText != null) {
      return Text(
        emptyText!,
        style: AppTextStyles.weGatherParagraphTextStyle.copyWith(
          color: AppConfig.colorTertiary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profile_personalInfo,
          style: AppTextStyles.weGatherHeaderTextStyle,
        ),
        if (name != null) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: l10n.profile_fullName, information: name),
        ],
        if (title != null) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: l10n.profile_jobTitle, information: title),
        ],
        if (company != null) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: l10n.profile_company, information: company),
        ],
        if (email != null) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: l10n.profile_emailAddress, information: email),
        ],
        if (phone != null) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: l10n.profile_phone, information: phone),
        ],
        // The whole section — divider, heading and rows alike — collapses when
        // the user has no link at all.
        if (hasSocials) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppConfig.dividerNonOpaqueColor),
          const SizedBox(height: 16),
          Text(
            l10n.profile_socialProfiles,
            style: AppTextStyles.weGatherHeaderTextStyle,
          ),
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
