import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wegather_app/containers/wg_bottom_nav_bar.dart';
import 'package:wegather_app/l10n/app_localizations.dart';

/// Persistent shell that hosts the app's main tabs and renders the shared
/// bottom navigation bar. The [navigationShell] keeps each tab's navigation
/// state alive when switching between them.
class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Re-tapping the active tab returns it to its initial route.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: WgBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: [
          WgNavItem(
            iconPath: 'assets/icons/default/menu/menu-home.svg',
            label: l10n.menu_home,
          ),
          WgNavItem(
            iconPath: 'assets/icons/default/menu/menu-calendar.svg',
            label: l10n.menu_calendar,
          ),
          WgNavItem(
            iconPath: 'assets/icons/default/menu/menu-modules.svg',
            label: l10n.menu_modules,
          ),
          WgNavItem(
            iconPath: 'assets/icons/default/menu/menu-user.svg',
            label: l10n.menu_user,
          ),
        ],
      ),
    );
  }
}
