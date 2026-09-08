import 'package:flutter/material.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_widgets/webview_page.dart';
import 'package:provider/provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'card_widget.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBarWidget(
            title: languageProvider.tr('contacts.title'),
            action: [],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.support_agent_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          languageProvider.tr('contacts.header'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.normal,
                            fontFamily: "tamilFont",
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  CardWidget(
                    leadingIcon: Icons.phone_outlined,
                    title: languageProvider.tr('contacts.mobileNumber'),
                    subTitle: '(+91) 7845456609',
                    trailingIcon: Icons.call_outlined,
                    onPressed: clickPhoneButton,
                  ),
                  const SizedBox(height: 14),

                  CardWidget(
                    leadingIcon: Icons.chat_outlined,
                    title: languageProvider.tr('contacts.whatsapp'),
                    subTitle: '(+91) 7845456609',
                    trailingIcon: Icons.send_outlined,
                    onPressed: clickWhatsAppButton,
                  ),
                  const SizedBox(height: 14),

                  CardWidget(
                    leadingIcon: Icons.email_outlined,
                    title: languageProvider.tr('contacts.email'),
                    subTitle: 'agprakash406@gmail.com',
                    trailingIcon: Icons.send_outlined,
                    onPressed: clickEmailButton,
                  ),
                  // const SizedBox(height: 14),

                  // CardWidget(
                  //   leadingIcon: Icons.language_outlined,
                  //   title: languageProvider.tr('contacts.website'),
                  //   subTitle: 'www.gp.prasowlabs.in/moi',
                  //   trailingIcon: Icons.open_in_browser_outlined,
                  //   onPressed: clickWebsiteButton,
                  // ),
                  const SizedBox(height: 32),

                  /// WORKING HOURS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          languageProvider.tr('contacts.workingHours'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            color: Colors.black87,
                            fontFamily: "englishFont",
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          languageProvider.tr('contacts.mondayToFriday'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          languageProvider.tr('contacts.morningToNight'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void clickEmailButton() async {
    Uri email = Uri(scheme: 'mailto', path: "agprakash406@gmail.com");
    await launchUrl(email);
  }

  void clickPhoneButton() async {
    Uri call = Uri(scheme: 'tel', path: "+917845456609");
    await launchUrl(call);
  }

  void clickWhatsAppButton() async {
    String contact = "+917845456609";
    String msg = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).tr('contacts.whatsappMessage');
    String whatsappUrl = "whatsapp://send?phone=$contact&text=$msg";
    try {
      await launchUrl(Uri.parse(whatsappUrl));
    } catch (e) {
      final msg = Provider.of<LanguageProvider>(
        // ignore: use_build_context_synchronously
        context,
        listen: false,
      ).tr('contacts.whatsappNotInstalled');
      AlertServices().toast(msg);
    }
  }

  void clickWebsiteButton() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebViewPage(
          url: 'https://gp.prasowlabs.in/moi/',
          title: 'மொய் கணக்கு',
        ),
      ),
    );
  }
}
