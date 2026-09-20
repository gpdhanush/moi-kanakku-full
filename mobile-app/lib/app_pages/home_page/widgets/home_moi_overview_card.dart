import 'package:flutter/material.dart';
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
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroBg = isDark ? const Color(0xFF071B18) : const Color(0xFF0E6A5E);
    final heroFg = isDark ? const Color(0xFFB8FFE8) : AppColors.white;
    final heroMuted = isDark
        ? const Color(0xFF7EE8C7)
        : heroFg.withValues(alpha: 0.78);
    const receivedAccent = Color(0xFF0E8A63);
    const receivedSoft = Color(0xFFEAF7F0);
    const givenAccent = Color(0xFFE38B3D);
    const givenSoft = Color(0xFFF8E6D6);

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
                  color: heroBg,
                  border: isDark
                      ? Border.all(color: const Color(0xFF4AF2B6), width: 1.4)
                      : null,
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
                          color: colors.primaryLight.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: -4,
                      child: Image.asset(
                        'assets/images/home_page/purse.png',
                        width: 150,
                        height: 140,
                        fit: BoxFit.contain,
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
                              color: heroMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text(
                              '₹ ${formatAmount(netBalance.abs())}',
                              style: AppTypography.amountLarge.copyWith(
                                color: heroFg,
                                fontSize: 34,
                                letterSpacing: -0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            height: 1,
                            color: heroFg.withValues(alpha: 0.18),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  languageProvider.tr('home.viewTransactions'),
                                  style: AppTypography.label.copyWith(
                                    color: heroFg,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                  accent: receivedAccent,
                  softTop: receivedSoft,
                  softBottom: receivedSoft,
                  onTap: onReceivedTap,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FlowMetricTile(
                  title: languageProvider.tr('moi.moiOut'),
                  amount: '₹ ${formatAmount(givenAmount)}',
                  accent: givenAccent,
                  softTop: givenSoft,
                  softBottom: givenSoft,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              colors: isDark
                  ? [const Color(0xFF0A1215), const Color(0xFF0A1215)]
                  : [softTop, softBottom],
            ),
            border: Border.all(
              color: isDark
                  ? accent.withValues(alpha: 0.8)
                  : accent.withValues(alpha: 0.2),
              width: isDark ? 1.5 : 1.0,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.26),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
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
