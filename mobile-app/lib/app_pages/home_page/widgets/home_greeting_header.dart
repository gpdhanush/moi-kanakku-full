import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:moi/app_utils/app_widgets/moi_user_avatar.dart';
import 'package:provider/provider.dart';

class HomeGreetingHeader extends StatelessWidget {
  final String Function(String lastLogin) formatLastLogin;
  final VoidCallback? onProfileTap;

  const HomeGreetingHeader({
    super.key,
    required this.formatLastLogin,
    this.onProfileTap,
  });

  String _resolveProfileImageUrl(Map<String, dynamic>? user) {
    if (user == null) return '';
    final profileImagePath =
        (user['profile_image_url'] ?? user['profile_image'])
            ?.toString()
            .trim() ??
        '';
    if (profileImagePath.isEmpty ||
        profileImagePath.toLowerCase() == 'null' ||
        profileImagePath.toLowerCase() == 'undefined') {
      return '';
    }
    if (profileImagePath.startsWith('http://') ||
        profileImagePath.startsWith('https://')) {
      return profileImagePath;
    }

    final normalized = profileImagePath.replaceFirst(RegExp(r'^/+'), '');
    if (appImageUrl.trim().isNotEmpty) {
      return '$appImageUrl/$normalized';
    }
    if (bootstrapApiBaseUri.trim().endsWith('/apis')) {
      final baseWithoutApis = bootstrapApiBaseUri.trim().replaceFirst(
        RegExp(r'/apis$'),
        '',
      );
      return '$baseWithoutApis/$normalized';
    }
    return '$bootstrapApiBaseUri/$normalized';
  }

  String _greetingPrefix(LanguageProvider languageProvider) {
    final hour = DateTime.now().hour;
    if (hour < 12) return languageProvider.tr('home.goodMorning');
    if (hour < 17) return languageProvider.tr('home.goodAfternoon');
    return languageProvider.tr('home.goodEvening');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<UserProvider, LanguageProvider>(
      builder: (context, userProvider, languageProvider, _) {
        final currentUserDetails = userProvider.userDetails;
        final user = currentUserDetails.isNotEmpty
            ? Map<String, dynamic>.from(currentUserDetails[0] as Map)
            : null;
        final userName = user?['name']?.toString().trim();
        final displayName = (userName == null || userName.isEmpty)
            ? 'User'
            : userName;
        final lastLogin = user?['last_login']?.toString() ?? '';
        final profileImageUrl = _resolveProfileImageUrl(user);
        final gender = user?['gender']?.toString();

        return Semantics(
          header: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : primary.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.18)
                      : primary.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greetingPrefix(languageProvider),
                        style: AppTypography.label.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        displayName,
                        style: AppTypography.body.copyWith(
                          fontFamily: 'Arimo',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (lastLogin.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${languageProvider.tr('home.lastLogin')}: ${formatLastLogin(lastLogin)}',
                          style: AppTypography.body.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: onProfileTap,
                  behavior: HitTestBehavior.opaque,
                  child: _Avatar(
                    imageUrl: profileImageUrl,
                    gender: gender,
                    primary: primary,
                    onImageMissing: () {
                      userProvider.clearProfileImage(
                        fromMissingFile: true,
                        missingUrl: profileImageUrl,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final String? gender;
  final Color primary;
  final VoidCallback? onImageMissing;

  const _Avatar({
    required this.imageUrl,
    required this.gender,
    required this.primary,
    this.onImageMissing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primary.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: MoiUserAvatar(
          imageUrl: imageUrl,
          gender: gender,
          size: 48,
          onImageMissing: onImageMissing,
        ),
      ),
    );
  }
}
