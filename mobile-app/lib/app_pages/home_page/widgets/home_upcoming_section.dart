import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/upcoming_functions/models/upcoming_function_model.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/moi_network_image.dart';
import 'package:provider/provider.dart';

class HomeUpcomingSection extends StatelessWidget {
  final List<UpcomingFunction> items;
  final bool isLoading;
  final String Function(String? date) formatDate;
  final VoidCallback onViewAll;
  final ValueChanged<UpcomingFunction> onItemTap;

  const HomeUpcomingSection({
    super.key,
    required this.items,
    required this.isLoading,
    required this.formatDate,
    required this.onViewAll,
    required this.onItemTap,
  });

  String _resolveImageUrl(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '$appImageUrl/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final preview = items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                languageProvider.tr('home.upcomingFunctions'),
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
        const SizedBox(height: AppSpacing.sm),
        if (isLoading && preview.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          )
        else if (preview.isEmpty)
          _EmptyUpcoming(
            message: languageProvider.tr('home.noUpcomingFunctions'),
            onAdd: onViewAll,
          )
        else
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = preview[index];
                return _UpcomingCard(
                  title: item.title,
                  date: formatDate(item.functionDate),
                  location: item.location,
                  imageUrl: _resolveImageUrl(item.invitationUrl),
                  onTap: () => onItemTap(item),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EmptyUpcoming extends StatelessWidget {
  final String message;
  final VoidCallback onAdd;

  const _EmptyUpcoming({required this.message, required this.onAdd});

  static final BorderRadius _radius = BorderRadius.circular(5);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: _radius,
      child: InkWell(
        onTap: onAdd,
        borderRadius: _radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: _radius,
            color: colorScheme.primary.withValues(alpha: 0.06),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: colorScheme.primary,
                  size: 16,
                  strokeWidth: 1.8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final String imageUrl;
  final VoidCallback onTap;

  const _UpcomingCard({
    required this.title,
    required this.date,
    required this.location,
    required this.imageUrl,
    required this.onTap,
  });

  static final BorderRadius _radius = BorderRadius.circular(10);

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    return SizedBox(
      width: 232,
      child: Material(
        color: Colors.transparent,
        borderRadius: _radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: _radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: _radius,
              color: colorScheme.surface,
              border: Border.all(
                color: primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: AppShadows.soft,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Opacity(
                    opacity: 0.2,
                    child: MoiNetworkImage(
                      url: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                if (hasImage)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.1),
                          colorScheme.surface.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface,
                          primary.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        date,
                        style: AppTypography.body.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.isEmpty ? '—' : location,
                        style: AppTypography.body.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
