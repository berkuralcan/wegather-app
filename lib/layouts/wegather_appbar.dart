import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_config.dart';
import '../config/text_styles.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;

  /// Height of the bar. A value larger than the default [kToolbarHeight]
  /// leaves more space between the top of the screen and the title.
  final double toolbarHeight;

  /// An action at the far end of the bar, opposite the back button — the post
  /// button on the composer, for instance. Centred vertically and inset from the
  /// edge by the same 16px the app's content uses.
  final Widget? trailing;

  /// Whether the title sits in the middle of the bar. A screen reached by
  /// pushing it is centred, the way a pushed page's title is everywhere in the
  /// app; a screen that is a tab in its own right — your own profile — sets
  /// this false and starts its title at the leading edge instead.
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.toolbarHeight = 96,
    this.trailing,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool showBack = onBackPressed != null || context.canPop();

    return AppBar(
      title: Text(
        title,
        textAlign: centerTitle ? TextAlign.center : TextAlign.start,
        style: AppTextStyles.appBarTextStyle,
      ),
      leading: showBack
          ? IconButton(
              icon: SvgPicture.asset(
                'assets/icons/back.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppConfig.colorTertiary,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: onBackPressed ?? () => context.pop(),
            )
          : null,
      actions: trailing == null
          ? null
          : [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: trailing),
              ),
            ],
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight,
      // Fully transparent so the app background gradient shows through, even
      // when content scrolls under the bar (Material 3 tints it otherwise).
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}
