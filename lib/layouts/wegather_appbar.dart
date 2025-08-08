import 'package:flutter/material.dart';
import '../config/text_styles.dart';
import 'package:go_router/go_router.dart';
 

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title.toUpperCase(), textAlign: TextAlign.center, style: AppTextStyles.appBarTextStyle),
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 40,),
        onPressed: onBackPressed ?? () => context.pop(),
      ),
      centerTitle: true,
      // You can customize colors, elevation, etc. here
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF213D53),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}