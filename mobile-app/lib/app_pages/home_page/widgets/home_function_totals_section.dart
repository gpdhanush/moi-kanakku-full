import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

/// Function-wise totals using the invoice-style list card design.
class HomeFunctionTotalsSection extends StatelessWidget {
  final List<Map<String, dynamic>> summaries;
  final bool isLoading;
  final String Function(double amount) formatAmount;
  final ValueChanged<Map<String, dynamic>> onItemTap;

  const HomeFunctionTotalsSection({
    super.key,
    required this.summaries,
    required this.isLoading,
    required this.formatAmount,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.tr('home.functionTotals'),
          style: AppTypography.sectionTitle.copyWith(
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          languageProvider.tr('home.functionTotalsHint'),
          style: AppTypography.body.copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isLoading && summaries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          )
        else if (summaries.isEmpty)
          Text(
            languageProvider.tr('home.noFunctionTotals'),
            style: AppTypography.body,
          )
        else
          Column(
            children: [
              for (var i = 0; i < summaries.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _FunctionTotalCard(
                  name: summaries[i]['name']?.toString() ?? '-',
                  date: summaries[i]['date']?.toString() ?? '-',
                  amount: summaries[i]['invest'] as double? ?? 0,
                  formatAmount: formatAmount,
                  onTap: () => onItemTap(summaries[i]),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _FunctionTotalCard extends StatelessWidget {
  final String name;
  final String date;
  final double amount;
  final String Function(double amount) formatAmount;
  final VoidCallback onTap;

  const _FunctionTotalCard({
    required this.name,
    required this.date,
    required this.amount,
    required this.formatAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    final accent = isPositive ? AppColors.moiReceived : AppColors.moiGiven;
    final soft = isPositive
        ? AppColors.moiReceivedSoft
        : AppColors.moiGivenSoft;
    final amountText = isPositive
        ? '₹ ${formatAmount(amount)}'
        : '-₹ ${formatAmount(amount.abs())}';
    // final languageProvider = context.read<LanguageProvider>();
    // final flowLabel = isPositive
    //     ? languageProvider.tr('moi.moiIn')
    //     : languageProvider.tr('moi.moiOut');
    final subtitleParts = <String>[
      if (date.isNotEmpty && date != '-') date,
      // flowLabel,
    ];
    final subtitle = subtitleParts.join(' • ');

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.xlAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.xlAll,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.xlAll,
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedWallet01,
                  color: accent,
                  size: 22,
                  strokeWidth: 1.7,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                amountText,
                style: AppTypography.amountMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
