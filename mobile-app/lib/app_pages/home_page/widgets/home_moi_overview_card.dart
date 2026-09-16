import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

/// Moi overview hero + received/given tiles (theme colors, no status chip / icons).
class HomeMoiOverviewCard extends StatelessWidget {
  final int netBalance;
  final int receivedAmount;
  final int givenAmount;
  final String Function(int amount) formatAmount;
  final VoidCallback onViewTransactions;
  final VoidCallback onReceivedTap;
  final VoidCallback onGivenTap;

  const HomeMoiOverviewCard({
    super.key,
    required this.netBalance,
    required this.receivedAmount,
    required this.givenAmount,
    required this.formatAmount,
    required this.onViewTransactions,
    required this.onReceivedTap,
    required this.onGivenTap,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = Color.lerp(primary, const Color(0xff0A3D8F), 0.28)!;
    final primarySoft = Color.lerp(primary, Colors.white, 0.22)!;

    return Semantics(
      label:
          // '${languageProvider.tr('home.moiOverview')}. '
          '${languageProvider.tr('home.netBalance')} '
          '₹ ${formatAmount(netBalance.abs())}',
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: AppRadius.xlAll,
            child: InkWell(
              onTap: onViewTransactions,
              borderRadius: AppRadius.xlAll,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.xlAll,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary,
                      primarySoft,
                      primaryDeep,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: primary.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -28,
                      top: -24,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -36,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.tr('home.netBalance'),
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹ ${formatAmount(netBalance.abs())}',
                            style: AppTypography.amountLarge.copyWith(
                              color: Colors.white,
                              fontSize: 34,
                              letterSpacing: -0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  languageProvider.tr('home.viewTransactions'),
                                  style: AppTypography.label.copyWith(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedArrowRight01,
                                  color: Colors.white,
                                  size: 16,
                                  strokeWidth: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _FlowMetricTile(
                  title: languageProvider.tr('moi.moiIn'),
                  amount: '₹ ${formatAmount(receivedAmount)}',
                  accent: AppColors.moiReceived,
                  softTop: AppColors.moiReceivedSoft,
                  softBottom: const Color(0xffD1FAE5),
                  onTap: onReceivedTap,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FlowMetricTile(
                  title: languageProvider.tr('moi.moiOut'),
                  amount: '₹ ${formatAmount(givenAmount)}',
                  accent: AppColors.moiGiven,
                  softTop: AppColors.moiGivenSoft,
                  softBottom: const Color(0xffFFE4E6),
                  onTap: onGivenTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowMetricTile extends StatelessWidget {
  final String title;
  final String amount;
  final Color accent;
  final Color softTop;
  final Color softBottom;
  final VoidCallback onTap;

  const _FlowMetricTile({
    required this.title,
    required this.amount,
    required this.accent,
    required this.softTop,
    required this.softBottom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [softTop, softBottom],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: accent.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  amount,
                  style: AppTypography.amountMedium.copyWith(
                    color: accent,
                    fontSize: 18,
                    letterSpacing: -0.3,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
