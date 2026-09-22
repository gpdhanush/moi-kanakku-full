import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final primary = Theme.of(context).colorScheme.primary;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: MoiAppHeader(
            title: languageProvider.tr('menu.contactUs').toTitleCase(),
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   languageProvider.tr('contacts.title'),
                //   style: AppTypography.label.copyWith(
                //     color: Theme.of(context).brightness == Brightness.dark
                //         ? AppColors.darkTextPrimary
                //         : AppColors.textPrimary,
                //     fontSize: 14,
                //     fontWeight: FontWeight.w700,
                //   ),
                // ),
                const SizedBox(height: AppSpacing.sm),
                _ContactTile(
                  primary: primary,
                  icon: HugeIcons.strokeRoundedCall,
                  title: languageProvider.tr('contacts.mobileNumber'),
                  subtitle: '(+91) 7845456609',
                  actionIcon: HugeIcons.strokeRoundedCall,
                  onTap: clickPhoneButton,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ContactTile(
                  primary: primary,
                  icon: HugeIcons.strokeRoundedWhatsapp,
                  title: languageProvider.tr('contacts.whatsapp'),
                  subtitle: '(+91) 7845456609',
                  actionIcon: HugeIcons.strokeRoundedSent,
                  onTap: clickWhatsAppButton,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ContactTile(
                  primary: primary,
                  icon: HugeIcons.strokeRoundedMail01,
                  title: languageProvider.tr('contacts.email'),
                  subtitle: 'agprakash406@gmail.com',
                  actionIcon: HugeIcons.strokeRoundedSent,
                  onTap: clickEmailButton,
                ),
                const SizedBox(height: AppSpacing.lg),
                _WorkingHoursCard(
                  primary: primary,
                  title: languageProvider.tr('contacts.workingHours'),
                  days: languageProvider.tr('contacts.mondayToFriday'),
                  hours: languageProvider.tr('contacts.morningToNight'),
                  hint: languageProvider.tr('contacts.workingHoursHint'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void clickEmailButton() async {
    final email = Uri(scheme: 'mailto', path: 'agprakash406@gmail.com');
    await launchUrl(email);
  }

  void clickPhoneButton() async {
    final call = Uri(scheme: 'tel', path: '+917845456609');
    await launchUrl(call);
  }

  void clickWhatsAppButton() async {
    const contact = '+917845456609';
    final msg = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).tr('contacts.whatsappMessage');
    final whatsappUrl = 'whatsapp://send?phone=$contact&text=$msg';
    try {
      await launchUrl(Uri.parse(whatsappUrl));
    } catch (e) {
      final toastMsg = Provider.of<LanguageProvider>(
        // ignore: use_build_context_synchronously
        context,
        listen: false,
      ).tr('contacts.whatsappNotInstalled');
      AlertServices().toast(toastMsg);
    }
  }
}

class _ContactTile extends StatelessWidget {
  final Color primary;
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final List<List<dynamic>> actionIcon;
  final VoidCallback onTap;

  const _ContactTile({
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: icon,
                  color: primary,
                  size: 18,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.label.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: actionIcon,
                  color: isDark ? AppColors.charcoal : Colors.white,
                  size: 16,
                  strokeWidth: 1.9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkingHoursCard extends StatelessWidget {
  final Color primary;
  final String title;
  final String days;
  final String hours;
  final String hint;

  const _WorkingHoursCard({
    required this.primary,
    required this.title,
    required this.days,
    required this.hours,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final pillBg = isDark
        ? AppColors.darkMoiReceivedSoft
        : const Color(0xFFE8F7EC);
    final primaryGreen = isDark ? AppColors.accent : const Color(0xFF16A34A);
    final darkGreen = isDark ? AppColors.accent : const Color(0xFF087443);
    final titleColor = isDark ? Colors.white : const Color(0xFF102A2A);
    final hoursColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8E5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedClock01,
                color: darkGreen,
                size: 26,
                strokeWidth: 2.0,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle.copyWith(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  color: primaryGreen,
                  size: 20,
                  strokeWidth: 2.0,
                ),
                const SizedBox(width: 8),
                Text(
                  days,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: isDark ? AppColors.accent : primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hours,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: hoursColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8E5),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedIdea01,
                    color: primaryGreen,
                    size: 20,
                    strokeWidth: 2.0,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: darkGreen,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
