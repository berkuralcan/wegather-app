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
        "iconPath": "assets/icons/default/modules/announcements.png",
        "title": AppLocalizations.of(context)!.homeIcon_announcements,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          // The event's announcements, managed from the admin panel.
          context.push('/announcements');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/information.png",
        "title": AppLocalizations.of(context)!.homeIcon_information,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          // The event's "Important Tips", managed from the admin panel.
          context.push('/tips');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/rules.png",
        "title": AppLocalizations.of(context)!.homeIcon_rules,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          context.push('/user/${user?.uid ?? 'test-id'}');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/hotel.png",
        "title": AppLocalizations.of(context)!.homeIcon_hotel,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          context.push('/user/${user?.uid ?? 'test-id'}');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/flights.png",
        "title": AppLocalizations.of(context)!.homeIcon_flights,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          // Travel to and from the event city — the participant tells the
          // organisers what they need, and their tickets come back here.
          context.push('/flights');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/transportation.png",
        "title": AppLocalizations.of(context)!.homeIcon_transportation,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          // The event's transfers, scheduled in the admin panel — the one
          // module where a user books something for themselves.
          context.push('/transportation');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/gallery.png",
        "title": AppLocalizations.of(context)!.homeIcon_gallery,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          // The event's shared gallery — the one module attendees add to.
          context.push('/gallery');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/documents.png",
        "title": AppLocalizations.of(context)!.homeIcon_documents,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          // The event's documents, managed from the admin panel.
          context.push('/documents');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/security.png",
        "title": AppLocalizations.of(context)!.homeIcon_security,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          context.push('/user/${user?.uid ?? 'test-id'}');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/shake-to-win.png",
        "title": AppLocalizations.of(context)!.homeIcon_shake_to_win,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          context.push('/user/${user?.uid ?? 'test-id'}');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/contests.png",
        "title": AppLocalizations.of(context)!.homeIcon_contests,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          context.push('/user/${user?.uid ?? 'test-id'}');
        },
      },
      {
        "iconPath": "assets/icons/default/modules/contact.png",
        "title": AppLocalizations.of(context)!.homeIcon_contact,
        "iconSize": Size(41.25, 41.25),
        "onTap": () {
          // The user's own support requests, and the conversations they hold —
          // the one module where an attendee talks directly to the organizers.
          context.push('/support');
        },
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 65),
          Image.asset(AppConfig.appLogo),
          SizedBox(height: 48),
          Expanded(
            child: GridView.builder(
              physics:
                  NeverScrollableScrollPhysics(), // TODO - Remove this when we have more items.
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 17,
                mainAxisSpacing: 18,
                // 60 icon + 8 gap + 16 label: a fixed extent keeps the tiles
                // the right height on every screen width.
                mainAxisExtent: 84,
              ),
              padding: EdgeInsets.only(left: 53.17, right: 53.17),
              shrinkWrap: true,
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return WgMenuIcon(
                  iconPath: item["iconPath"],
                  title: item["title"],
                  iconSize: item["iconSize"],
                  onTap: item["onTap"],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
