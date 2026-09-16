import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

/// Menu row for [showMoiActionSheet] / [showCustomActionSheet].
class ActionSheetItem {
  final IconData? icon;
  final List<List<dynamic>>? hugeIcon;
  final String title;
  final Color? color;
  final bool isDestructive;
  final bool isCancel;
  final Future<void> Function(BuildContext) onPressed;

  ActionSheetItem({
    this.icon,
    this.hugeIcon,
    required this.title,
    this.color,
    this.isDestructive = false,
    this.isCancel = false,
    required this.onPressed,
  }) : assert(
         isCancel || icon != null || hugeIcon != null,
         'Provide either icon or hugeIcon for non-cancel actions',
       );
}

/// Backward-compatible alias.
Future<void> showCustomActionSheet({
  required BuildContext context,
  String title = '',
  String? subtitle,
  required List<ActionSheetItem> actions,
  Color? titleColor,
}) {
  return showMoiActionSheet(
    context: context,
    title: title,
    subtitle: subtitle,
    actions: actions,
    titleColor: titleColor,
  );
}

/// Modern Tailwind-style action bottom sheet used by list pages.
Future<void> showMoiActionSheet({
  required BuildContext context,
  String title = '',
  String? subtitle,
  required List<ActionSheetItem> actions,
  Color? titleColor,
}) {
  final primary = titleColor ?? Theme.of(context).colorScheme.primary;
  final menuActions = actions.where((a) => !a.isCancel).toList();
  ActionSheetItem? cancelAction;
  for (final action in actions) {
    if (action.isCancel) {
      cancelAction = action;
      break;
    }
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetContext) {
      return _MoiActionSheetShell(
        title: title,
        subtitle: subtitle,
        primary: primary,
        menuActions: menuActions,
        cancelAction: cancelAction,
      );
    },
  );
}

class _MoiActionSheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color primary;
  final List<ActionSheetItem> menuActions;
  final ActionSheetItem? cancelAction;

  const _MoiActionSheetShell({
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.menuActions,
    required this.cancelAction,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 8),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xffE4E4E7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff09090B).withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xffE4E4E7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                if (title.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTypography.sectionTitle.copyWith(
                      color: primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: const Color(0xff71717A),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ...List.generate(menuActions.length, (index) {
                  final item = menuActions[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == menuActions.length - 1 ? 0 : 8,
                    ),
                    child: _MoiActionSheetTile(
                      item: item,
                      primary: primary,
                      onTap: () => item.onPressed(context),
                    ),
                  );
                }),
                if (cancelAction != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: const Color(0xffF4F4F5),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => cancelAction!.onPressed(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            cancelAction!.title,
                            textAlign: TextAlign.center,
                            style: AppTypography.label.copyWith(
                              color: const Color(0xff3F3F46),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoiActionSheetTile extends StatelessWidget {
  final ActionSheetItem item;
  final Color primary;
  final VoidCallback onTap;

  const _MoiActionSheetTile({
    required this.item,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.isDestructive
        ? AppColors.moiGiven
        : (item.color ?? primary);
    final soft = item.isDestructive
        ? AppColors.moiGivenSoft
        : accent.withValues(alpha: 0.1);
    final titleColor = item.isDestructive
        ? AppColors.moiGiven
        : const Color(0xff18181B);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: accent.withValues(alpha: 0.08),
        highlightColor: accent.withValues(alpha: 0.04),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isDestructive
                  ? AppColors.moiGiven.withValues(alpha: 0.22)
                  : const Color(0xffE4E4E7),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: item.hugeIcon != null
                    ? HugeIcon(
                        icon: item.hugeIcon!,
                        color: accent,
                        size: 20,
                        strokeWidth: 1.8,
                      )
                    : Icon(item.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.label.copyWith(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: item.isDestructive
                    ? AppColors.moiGiven.withValues(alpha: 0.55)
                    : const Color(0xffA1A1AA),
                size: 16,
                strokeWidth: 1.9,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern confirmation bottom sheet. Returns `true` / `false` / `null` (dismiss).
Future<bool?> showMoiConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  List<List<dynamic>> icon = HugeIcons.strokeRoundedLogout01,
  bool isDestructive = false,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  final accent = isDestructive ? AppColors.moiGiven : primary;
  final soft = isDestructive
      ? AppColors.moiGivenSoft
      : primary.withValues(alpha: 0.1);

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetContext) {
      final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;

      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 8),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffE4E4E7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff09090B).withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xffE4E4E7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: icon,
                      color: accent,
                      size: 28,
                      strokeWidth: 1.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: const Color(0xff71717A),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: const Color(0xffF4F4F5),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () =>
                                Navigator.of(sheetContext).pop(false),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                cancelLabel,
                                textAlign: TextAlign.center,
                                style: AppTypography.label.copyWith(
                                  color: const Color(0xff3F3F46),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () =>
                                Navigator.of(sheetContext).pop(true),
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDestructive
                                      ? [
                                          AppColors.moiGiven,
                                          Color.lerp(
                                            AppColors.moiGiven,
                                            const Color(0xff9F1239),
                                            0.25,
                                          )!,
                                        ]
                                      : [
                                          primary,
                                          Color.lerp(
                                            primary,
                                            const Color(0xff0A3D8F),
                                            0.28,
                                          )!,
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.28),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Text(
                                  confirmLabel,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.label.copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
