import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/text_styles.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;

  /// Height of the bar. A value larger than the default [kToolbarHeight]
  /// leaves more space between the top of the screen and the title.
  final double toolbarHeight;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.toolbarHeight = 96,
  });

  @override
  Widget build(BuildContext context) {
    final bool showBack = onBackPressed != null || context.canPop();

    return AppBar(
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: AppTextStyles.appBarTextStyle,
      ),
      leading: showBack
          ? IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: AppConfig.colorTertiary,
                size: 40,
              ),
              onPressed: onBackPressed ?? () => context.pop(),
            )
          : null,
      centerTitle: true,
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
