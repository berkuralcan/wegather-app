import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/providers/auth_providers.dart';
import 'package:wegather_app/containers/wg_menu_icon.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    final List<Map<String, dynamic>> menuItems = [
      {
        "iconPath": "assets/icons/profile.png",
        "title": AppLocalizations.of(context)!.homeIcon_my_profile,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
            context.push('/profile/${user?.uid ?? 'test-id'}');
        },
      },
      {
        "iconPath": "assets/icons/qr.png",
        "title": AppLocalizations.of(context)!.homeIcon_my_qr_code,
        "iconSize": Size(50.42, 50.42),
        "onTap": () {
          context.push('/liquid');
        },
      },
      {
        "iconPath": "assets/icons/calendar-2.png",
        "title": AppLocalizations.of(context)!.homeIcon_event_program,
        "iconSize": Size(36.67, 41.25),
        "onTap": () {},
      },
      {
        "iconPath": "assets/icons/plane.png",
        "title": AppLocalizations.of(context)!.homeIcon_flight_info,
        "iconSize": Size(39.1, 39.08),
        "onTap": () {},
      },
      {
        "iconPath": "assets/icons/transport.png",
        "title": AppLocalizations.of(context)!.homeIcon_transportation,
        "iconSize": Size(36.67, 43.54),
        "onTap": () {},
      },
      {
        "iconPath": "assets/icons/stay.png",
        "title": AppLocalizations.of(context)!.homeIcon_stay_info,
        "iconSize": Size(50.42, 34.38),
        "onTap": () {},
      },
      {
        "iconPath": "assets/icons/documents.png",
        "title": AppLocalizations.of(context)!.homeIcon_documents,
        "iconSize": Size(36.67, 45.83),
        "onTap": () {},
      },
      {
        "iconPath": "assets/icons/bell.png",
        "title": AppLocalizations.of(context)!.homeIcon_announcements,
        "iconSize": Size(40.97, 49.99),
        "onTap": () {},
      },
      {
        "iconPath": "assets/icons/support.png",
        "title": AppLocalizations.of(context)!.homeIcon_support,
        "iconSize": Size(39.29, 47.14),
        "onTap": () {},
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 92),
          Image.asset(AppConfig.appLogo),
          SizedBox(height: 100),
          Expanded(
            child: GridView.count(
              physics: NeverScrollableScrollPhysics(), // TODO - Remove this when we have more items.
              crossAxisCount: 3,
              crossAxisSpacing: 17,
              mainAxisSpacing: 18,
              padding: EdgeInsets.only(left: 12, right: 12),
              shrinkWrap: true,
              children: menuItems
                  .map(
                    (item) => WgMenuIcon(
                      iconPath: item["iconPath"],
                      title: item["title"],
                      iconSize: item["iconSize"],
                      onTap: item["onTap"],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
