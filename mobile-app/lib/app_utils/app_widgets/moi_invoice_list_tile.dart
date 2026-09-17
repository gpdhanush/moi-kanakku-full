import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

/// Invoice-style list row matching the modern card design:
/// soft icon tile + title/subtitle + navy amount.
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

  /// Convenience for Moi Received / Given rows.
  factory MoiInvoiceListTile.moiFlow({
    Key? key,
    required String title,
    required String subtitle,
    required String amount,
    required bool isReceived,
    VoidCallback? onTap,
  }) {
    return MoiInvoiceListTile(
      key: key,
      title: title,
      subtitle: subtitle,
      amount: amount,
      onTap: onTap,
      icon: isReceived
          ? HugeIcons.strokeRoundedMoneyReceive01
          : HugeIcons.strokeRoundedMoneySend01,
      iconColor: isReceived ? AppColors.moiReceived : AppColors.moiGiven,
      iconBackground:
          isReceived ? AppColors.moiReceivedSoft : AppColors.moiGivenSoft,
    );
  }

  static const Color _amountNavy = Color(0xff1A237E);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: const Color(0xff09090B).withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withValues(alpha: 0.06),
        highlightColor: iconColor.withValues(alpha: 0.03),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff09090B).withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xff09090B).withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  size: 22,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  amount,
                  style: AppTypography.amountMedium.copyWith(
                    color: amountColor ?? _amountNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
