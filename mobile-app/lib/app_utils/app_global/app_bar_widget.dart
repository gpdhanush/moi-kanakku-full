import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_themes/index.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> action;

  const AppBarWidget({super.key, required this.title, required this.action});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: colors.background,
      automaticallyImplyLeading: true,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.charcoal.withValues(alpha: 0.08),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      actions: action.isEmpty
          ? null
          : [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(mainAxisSize: MainAxisSize.min, children: action),
              ),
            ],
      iconTheme: IconThemeData(color: colors.textPrimary, size: 24),
      leadingWidth: 56,
      toolbarHeight: kToolbarHeight,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border(
            bottom: BorderSide(color: colors.border.withValues(alpha: 0.8)),
          ),
        ),
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: colors.surface,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
