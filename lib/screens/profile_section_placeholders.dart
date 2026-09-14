import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';

/// The three sections of your own profile that are named but not built yet:
/// where you are staying, the transfers you are on, and your flights.
///
/// Each is a real screen rather than a dead row, so tapping through says the
/// section is coming rather than doing nothing at all. They are separate
/// classes so that filling one in later is a matter of replacing its body,
/// leaving its route and its title where they are.
class ProfileAccommodationScreen extends StatelessWidget {
  const ProfileAccommodationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ComingSoon(
      title: AppLocalizations.of(context)!.profile_menuAccommodation,
    );
  }
}

class ProfileTransportationInfoScreen extends StatelessWidget {
  const ProfileTransportationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ComingSoon(
      title: AppLocalizations.of(context)!.profile_menuTransportation,
    );
  }
}

class ProfileFlightsInfoScreen extends StatelessWidget {
  const ProfileFlightsInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ComingSoon(
      title: AppLocalizations.of(context)!.profile_menuFlights,
    );
  }
}

/// A titled, empty screen: the section exists, its contents do not yet.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              AppLocalizations.of(context)!.profile_comingSoon,
              textAlign: TextAlign.center,
              style: AppTextStyles.weGatherParagraphTextStyle.copyWith(
                color: AppConfig.colorTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
