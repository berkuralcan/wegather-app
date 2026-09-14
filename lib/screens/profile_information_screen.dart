import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../profile_widgets/profile_details.dart';
import '../providers/profile_providers.dart';

/// "My Personal Information": the details the organisers hold about you — your
/// name, title, company and how to reach you — plus the accounts you have added
/// yourself.
///
/// Read-only, since everything above the links comes from the admin panel: the
/// event's roster is the organisers' record, not something a participant edits
/// from their phone. What is yours to change is on the edit screen instead.
class ProfileInformationScreen extends ConsumerWidget {
  const ProfileInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.profile_menuInformation),
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
              child: ProfileDetails(
                profile: profile,
                emptyText: l10n.profile_infoEmpty,
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
