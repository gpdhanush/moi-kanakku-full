import 'package:flutter/material.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

class AppNoDataFound extends StatelessWidget {
  final bool showSecond;

  const AppNoDataFound({super.key, required this.showSecond});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withValues(alpha: 0.10),
                    ),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedHourglass, size: 50, color: colorScheme.primary, strokeWidth: 1.8),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    languageProvider.tr('common.noDataFound'),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
