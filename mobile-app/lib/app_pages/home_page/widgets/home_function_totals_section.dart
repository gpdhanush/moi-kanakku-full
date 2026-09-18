import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/moi_network_image.dart';
import 'package:provider/provider.dart';

/// Function-wise totals using the invoice-style list card design.
class HomeFunctionTotalsSection extends StatelessWidget {
  final List<Map<String, dynamic>> summaries;
  final bool isLoading;
  final String Function(double amount) formatAmount;
  final ValueChanged<Map<String, dynamic>> onItemTap;
  final VoidCallback onViewAll;

  const HomeFunctionTotalsSection({
    super.key,
    required this.summaries,
    required this.isLoading,
    required this.formatAmount,
    required this.onItemTap,
    required this.onViewAll,
  });

  String _resolveImageUrl(Map<String, dynamic> summary) {
    final function = summary['function'];
    var raw = '';
    if (function is Map) {
      raw = (function['imageUrl'] ?? function['invitationUrl'] ?? '')
          .toString()
          .trim();
    }
    if (raw.isEmpty) {
      raw = (summary['imageUrl'] ?? summary['invitationUrl'] ?? '')
          .toString()
          .trim();
    }
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '$appImageUrl/${raw.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final preview = summaries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                languageProvider.tr('home.functionTotals'),
                style: AppTypography.sectionTitle.copyWith(
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: primary.withValues(alpha: 0.9),
              ),
              child: Text(
                languageProvider.tr('home.viewAll'),
                style: AppTypography.label.copyWith(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
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
        else if (preview.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.08),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      color: primary.withValues(alpha: 0.85),
                      size: 28,
                      strokeWidth: 1.7,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    languageProvider.tr('home.noFunctionTotals'),
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < preview.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _FunctionTotalCard(
                  name: preview[i]['name']?.toString() ?? '-',
                  date: preview[i]['date']?.toString() ?? '-',
                  amount: preview[i]['invest'] as double? ?? 0,
                  imageUrl: _resolveImageUrl(preview[i]),
                  formatAmount: formatAmount,
                  onTap: () => onItemTap(preview[i]),
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
  final String imageUrl;
  final String Function(double amount) formatAmount;
  final VoidCallback onTap;

  const _FunctionTotalCard({
    required this.name,
    required this.date,
    required this.amount,
    required this.imageUrl,
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
    final subtitleParts = <String>[
      if (date.isNotEmpty && date != '-') date,
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
              _FunctionLeading(
                imageUrl: imageUrl,
                accent: accent,
                soft: soft,
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

class _FunctionLeading extends StatelessWidget {
  final String imageUrl;
  final Color accent;
  final Color soft;

  const _FunctionLeading({
    required this.imageUrl,
    required this.accent,
    required this.soft,
  });

  Widget _iconFallback() {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: imageUrl.isEmpty ? soft : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? _iconFallback()
          : MoiNetworkImage(
              url: imageUrl,
              fit: BoxFit.cover,
              width: 44,
              height: 44,
              errorBuilder: (context, error, stackTrace) => _iconFallback(),
            ),
    );
  }
}
