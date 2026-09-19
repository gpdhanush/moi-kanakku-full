import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

/// List row matching Overview person cards:
/// soft icon tile + title/subtitle + trailing amount (middle-aligned).
class MoiInvoiceListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final List<List<dynamic>> icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback? onTap;
  final Color? amountColor;

  const MoiInvoiceListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.onTap,
    this.amountColor,
  });

  /// Moi Received / Given / function transaction rows — Overview list style.
  factory MoiInvoiceListTile.moiFlow({
    Key? key,
    required String title,
    required String subtitle,
    required String amount,
    required bool isReceived,
    VoidCallback? onTap,
  }) {
    final accent = isReceived ? AppColors.moiReceived : AppColors.moiGiven;
    return MoiInvoiceListTile(
      key: key,
      title: title,
      subtitle: subtitle,
      amount: amount,
      onTap: onTap,
      // Same leading icon as Overview; only the accent color differs.
      icon: HugeIcons.strokeRoundedUser,
      iconColor: accent,
      iconBackground: accent.withValues(alpha: 0.1),
      amountColor: accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withValues(alpha: 0.06),
        highlightColor: iconColor.withValues(alpha: 0.03),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: icon,
                  color: iconColor,
                  size: 20,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                amount,
                textAlign: TextAlign.right,
                style: AppTypography.amountMedium.copyWith(
                  color: amountColor ?? AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
