import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/upcoming_functions/models/upcoming_function_model.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/moi_flow_app_header.dart';
import 'package:moi/app_utils/app_widgets/moi_network_image.dart';
import 'package:provider/provider.dart';

class UpcomingFunctionDetailsPage extends StatelessWidget {
  final UpcomingFunction function;

  const UpcomingFunctionDetailsPage({super.key, required this.function});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final imageUrl = _resolvedImageUrl(function.invitationUrl);
    final title = function.title.trim().isEmpty
        ? ''
        : function.title.toUpperCase();

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final statusLabel = _statusText(languageProvider, function.status);
        final statusColor = _statusColor(function.status);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: MoiFlowAppHeader(
            title: title.isEmpty
                ? languageProvider
                      .tr('upcomingFunctions.detailsTitle')
                      .toUpperCase()
                : title,
            subtitle: function.functionDate,
            onBack: () => Navigator.pop(context),
            accent: primary,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroImage(
                  imageUrl: imageUrl,
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                  onTap: () => _showFullImage(context, imageUrl),
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailsSection(
                  primary: primary,
                  sectionTitle: languageProvider.tr(
                    'upcomingFunctions.details',
                  ),
                  nameLabel: languageProvider.tr(
                    'upcomingFunctions.functionName',
                  ),
                  dateLabel: languageProvider.tr(
                    'upcomingFunctions.functionDate',
                  ),
                  statusLabel: languageProvider.tr('upcomingFunctions.status'),
                  locationLabel: languageProvider.tr(
                    'upcomingFunctions.location',
                  ),
                  notesLabel: languageProvider.tr('upcomingFunctions.notes'),
                  name: function.title,
                  date: function.functionDate,
                  status: statusLabel,
                  statusColor: statusColor,
                  location: function.location,
                  notes: function.description ?? '',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusText(LanguageProvider languageProvider, String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return languageProvider.tr('upcomingFunctions.active');
      case 'CANCELLED':
        return languageProvider.tr('upcomingFunctions.cancelled');
      case 'COMPLETED':
        return languageProvider.tr('upcomingFunctions.completed');
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF2E7D32);
      case 'CANCELLED':
        return AppColors.moiGiven;
      case 'COMPLETED':
        return const Color(0xFFE65100);
      default:
        return AppColors.textSecondary;
    }
  }

  String _resolvedImageUrl(String? invitationUrl) {
    if (invitationUrl == null || invitationUrl.isEmpty) return '';
    if (invitationUrl.startsWith('http')) return invitationUrl;
    return '$appImageUrl/${invitationUrl.replaceFirst(RegExp(r'^/+'), '')}';
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: imageUrl.isNotEmpty
                      ? MoiNetworkImage(
                          url: imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(AppImages.defaultImage),
                        )
                      : Image.asset(AppImages.defaultImage),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(dialogContext).top + 8,
                right: 16,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: Colors.white,
                      size: 22,
                      strokeWidth: 1.9,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  const _HeroImage({
    required this.imageUrl,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl.isNotEmpty
                  ? MoiNetworkImage(
                      url: imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        AppImages.defaultImage,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(AppImages.defaultImage, fit: BoxFit.cover),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTypography.label.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedZoomInArea,
                    color: Colors.white,
                    size: 16,
                    strokeWidth: 1.8,
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

class _DetailsSection extends StatelessWidget {
  final Color primary;
  final String sectionTitle;
  final String nameLabel;
  final String dateLabel;
  final String statusLabel;
  final String locationLabel;
  final String notesLabel;
  final String name;
  final String date;
  final String status;
  final Color statusColor;
  final String location;
  final String notes;

  const _DetailsSection({
    required this.primary,
    required this.sectionTitle,
    required this.nameLabel,
    required this.dateLabel,
    required this.statusLabel,
    required this.locationLabel,
    required this.notesLabel,
    required this.name,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.location,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(context);
    final hasNotes = notes.trim().isNotEmpty;
    final rows =
        <
          ({
            List<List<dynamic>> icon,
            String label,
            String value,
            Color? valueColor,
            int maxLines,
          })
        >[
          (
            icon: HugeIcons.strokeRoundedWedding,
            label: nameLabel,
            value: name.trim().isEmpty ? '—' : name.toUpperCase(),
            valueColor: null,
            maxLines: 2,
          ),
          (
            icon: HugeIcons.strokeRoundedCalendar03,
            label: dateLabel,
            value: date.trim().isEmpty ? '—' : date.toUpperCase(),
            valueColor: null,
            maxLines: 2,
          ),
          (
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
            label: statusLabel,
            value: status.toUpperCase(),
            valueColor: statusColor,
            maxLines: 1,
          ),
          (
            icon: HugeIcons.strokeRoundedLocation01,
            label: locationLabel,
            value: location.trim().isEmpty ? '—' : location.toUpperCase(),
            valueColor: null,
            maxLines: 2,
          ),
          if (hasNotes)
            (
              icon: HugeIcons.strokeRoundedNote,
              label: notesLabel,
              value: notes.toUpperCase(),
              valueColor: null,
              maxLines: 6,
            ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: AppTypography.label.copyWith(
            color: isDark ? colors.textPrimary : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? colors.border : AppColors.lightBorder,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppShadows.soft,
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _DetailTile(
                  primary: primary,
                  hugeIcon: rows[i].icon,
                  label: rows[i].label,
                  value: rows[i].value,
                  valueColor: rows[i].valueColor,
                  maxLines: rows[i].maxLines,
                  showDivider: i < rows.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final Color primary;
  final List<List<dynamic>> hugeIcon;
  final String label;
  final String value;
  final Color? valueColor;
  final int maxLines;
  final bool showDivider;

  const _DetailTile({
    required this.primary,
    required this.hugeIcon,
    required this.label,
    required this.value,
    this.valueColor,
    this.maxLines = 2,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (valueColor ?? primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: hugeIcon,
                  color: valueColor ?? primary,
                  size: 17,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color:
                            valueColor ??
                            (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : const Color(0xffF4F4F5),
            ),
          ),
      ],
    );
  }
}
