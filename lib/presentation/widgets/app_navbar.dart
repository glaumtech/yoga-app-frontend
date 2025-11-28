import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool isTransparent;

  const AppNavbar({
    super.key,
    this.title,
    this.showBackButton = true,
    this.actions,
    this.isTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title ?? AppConstants.appName),
      backgroundColor: isTransparent
          ? Colors.transparent
          : AppTheme.primaryColor,
      elevation: isTransparent ? 0 : 2,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
