import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_global/alert_services.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:provider/provider.dart';

bool isUserEmailVerified(Map<String, dynamic>? user) {
  if (user == null) return false;
  final verified = user['is_verified'];
  if (verified == true || verified == 1 || verified == '1') return true;
  final at = user['email_verified_at']?.toString().trim() ?? '';
  return at.isNotEmpty && at.toLowerCase() != 'null';
}

/// Compact verified badge shown before an email address.
class EmailVerifiedBadge extends StatelessWidget {
  final double size;

  const EmailVerifiedBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: HugeIcons.strokeRoundedCheckmarkBadge01,
      size: size,
      color: AppColors.moiReceived,
      strokeWidth: 1.8,
    );
  }
}

/// Prompt to verify email — hidden when already verified.
class EmailVerifyCard extends StatefulWidget {
  final String? email;
  final EdgeInsetsGeometry? margin;

  const EmailVerifyCard({super.key, this.email, this.margin});

  @override
  State<EmailVerifyCard> createState() => _EmailVerifyCardState();
}

class _EmailVerifyCardState extends State<EmailVerifyCard> {
  final UserServices _userServices = UserServices();
  final AlertServices _alertServices = AlertServices();
  bool _sending = false;

  Future<void> _sendVerification() async {
    if (_sending) return;
    setState(() => _sending = true);
    final language = context.read<LanguageProvider>();
    try {
      final response = await _userServices.sendVerifyEmail();
      if (!mounted) return;
      if (response != null && response['responseType'] == 'S') {
        final message = response['responseValue'] is Map
            ? response['responseValue']['message']?.toString()
            : null;
        _alertServices.successToast(
          message ?? language.tr('emailVerify.sentSuccess'),
        );
      } else {
        final message = response is Map && response['responseValue'] is Map
            ? response['responseValue']['message']?.toString()
            : null;
        _alertServices.errorToast(
          message ?? language.tr('emailVerify.sendFailed'),
        );
      }
    } catch (e) {
      if (mounted) {
        _alertServices.errorToast(language.tr('emailVerify.sendFailed'));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<UserProvider, LanguageProvider>(
      builder: (context, userProvider, languageProvider, _) {
        final user = userProvider.userDetails.isNotEmpty
            ? Map<String, dynamic>.from(userProvider.userDetails[0] as Map)
            : null;
        if (isUserEmailVerified(user)) {
          return const SizedBox.shrink();
        }

        final email = (widget.email ?? user?['email']?.toString() ?? '').trim();

        return Container(
          margin: widget.margin,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.18),
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedMail01,
                      size: 20,
                      color: colorScheme.primary,
                      strokeWidth: 1.7,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.tr('emailVerify.title'),
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
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
                ],
              ),
              const SizedBox(height: 10),
              Text(
                languageProvider.tr('emailVerify.description'),
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _sending ? null : _sendVerification,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(languageProvider.tr('emailVerify.sendButton')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
