import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class HomeGreetingHeader extends StatelessWidget {
  final String Function(String lastLogin) formatLastLogin;

  const HomeGreetingHeader({super.key, required this.formatLastLogin});

  String _resolveProfileImageUrl(Map<String, dynamic>? user) {
    if (user == null) return '';
    final profileImagePath =
        (user['profile_image_url'] ?? user['profile_image'])
            ?.toString()
            .trim() ??
        '';
    if (profileImagePath.isEmpty) return '';
    if (profileImagePath.startsWith('http://') ||
        profileImagePath.startsWith('https://')) {
      return profileImagePath;
    }
    return '$appImageUrl/${profileImagePath.replaceFirst(RegExp(r'^/+'), '')}';
  }

  String _greetingPrefix(LanguageProvider languageProvider) {
    final hour = DateTime.now().hour;
    if (hour < 12) return languageProvider.tr('home.goodMorning');
    if (hour < 17) return languageProvider.tr('home.goodAfternoon');
    return languageProvider.tr('home.goodEvening');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

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

        return Semantics(
          header: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: primary.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _greetingPrefix(languageProvider),
                          style: AppTypography.body.copyWith(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        displayName,
                        style: AppTypography.greeting.copyWith(
                          fontSize: 22,
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
                _Avatar(imageUrl: profileImageUrl, primary: primary),
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
  final Color primary;

  const _Avatar({required this.imageUrl, required this.primary});

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, Colors.white, 0.25)!],
        ),
      ),
      alignment: Alignment.center,
      child: const HugeIcon(
        icon: HugeIcons.strokeRoundedUser,
        color: Colors.white,
        size: 22,
        strokeWidth: 1.8,
      ),
    );
  }

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
        child: imageUrl.isEmpty
            ? _placeholder()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              ),
      ),
    );
  }
}
