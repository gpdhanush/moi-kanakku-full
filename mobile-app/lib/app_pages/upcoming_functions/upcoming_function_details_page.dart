import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/upcoming_functions/models/upcoming_function_model.dart';
import 'package:moi/app_themes/app_colors.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class UpcomingFunctionDetailsPage extends StatelessWidget {
  final UpcomingFunction function;

  const UpcomingFunctionDetailsPage({super.key, required this.function});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolvedImageUrl(function.invitationUrl);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) => Scaffold(
        appBar: AppBarWidget(
          title: function.title.isEmpty
              ? languageProvider.tr('upcomingFunctions.detailsTitle')
              : function.title,
          action: const [],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl.isEmpty
                    ? Image.asset(
                        AppImages.defaultImage,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        imageUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            AppImages.defaultImage,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 25),
              Text(
                languageProvider.tr('upcomingFunctions.details'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,

                  decoration: TextDecoration.underline,
                  decorationThickness: 2.0,
                ),
              ),
              const SizedBox(height: 16.0),

              _buildDetailCard(
                icon: Icons.celebration_outlined,
                label: languageProvider.tr('upcomingFunctions.functionName'),
                value: function.title.toTitleCase(),
                colorScheme: Theme.of(context).colorScheme,
                isDark: false,
                context: context,
              ),
              const SizedBox(height: 16.0),

              _buildDetailCard(
                icon: Icons.celebration_outlined,
                label: languageProvider.tr('upcomingFunctions.functionDate'),
                value: function.functionDate,
                colorScheme: Theme.of(context).colorScheme,
                isDark: false,
                context: context,
              ),
              const SizedBox(height: 16.0),

              _buildDetailCard(
                icon: Icons.celebration_outlined,
                label: languageProvider.tr('upcomingFunctions.status'),
                value: _statusText(languageProvider, function.status),
                colorScheme: Theme.of(context).colorScheme,
                isDark: false,
                context: context,
              ),
              const SizedBox(height: 16.0),

              _buildDetailCard(
                icon: Icons.celebration_outlined,
                label: languageProvider.tr('upcomingFunctions.location'),
                value: function.location,
                colorScheme: Theme.of(context).colorScheme,
                isDark: false,
                context: context,
              ),
              const SizedBox(height: 16.0),

              _buildDetailCard(
                icon: Icons.celebration_outlined,
                label: languageProvider.tr('upcomingFunctions.notes'),
                value: function.description ?? '',
                colorScheme: Theme.of(context).colorScheme,
                isDark: false,
                context: context,
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
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

  // Create a modern detail card widget
  Widget _buildDetailCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final displayValue = value.trim().isEmpty ? "-" : value;
    final hasValue = value.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey[400] : AppColors.blackLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: hasValue
                        ? colorScheme.primary
                        : (isDark ? Colors.grey[600] : AppColors.fontGrey),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolvedImageUrl(String? invitationUrl) {
    if (invitationUrl == null || invitationUrl.isEmpty) {
      return '';
    }
    if (invitationUrl.startsWith('http')) {
      return invitationUrl;
    }
    return '$appImageUrl/$invitationUrl';
  }
}
