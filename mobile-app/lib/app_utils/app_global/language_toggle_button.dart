import 'package:flutter/material.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class LanguageToggleButton extends StatelessWidget {
  final Color? iconColor;
  final double? iconSize;

  const LanguageToggleButton({super.key, this.iconColor, this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isEnglish = languageProvider.isEnglish;

        return IconButton(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              isEnglish ? 'A' : languageProvider.currentLanguage.toUpperCase(),
              style: TextStyle(
                color: iconColor ?? Colors.white,
                fontSize: iconSize ?? 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onPressed: () async {
            await languageProvider.toggleLanguage();
          },
          tooltip: isEnglish
              ? languageProvider.tr('common.switchToTamil')
              : languageProvider.tr('common.switchToEnglish'),
        );
      },
    );
  }
}

/// Alternative widget with language selector dropdown
class LanguageSelectorButton extends StatelessWidget {
  final Color? iconColor;

  const LanguageSelectorButton({super.key, this.iconColor});

  Future<void> _showLanguageDialog(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(languageProvider.tr('settings.selectLanguage')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageTile(
                context,
                languageProvider,
                'en',
                languageProvider.tr('common.english'),
              ),
              _languageTile(
                context,
                languageProvider,
                'ta',
                languageProvider.tr('common.tamil'),
              ),
              _languageTile(
                context,
                languageProvider,
                'ml',
                languageProvider.tr('common.malayalam'),
              ),
              _languageTile(
                context,
                languageProvider,
                'kn',
                languageProvider.tr('common.kannada'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _languageTile(
    BuildContext context,
    LanguageProvider languageProvider,
    String code,
    String label,
  ) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(label),
      trailing: languageProvider.currentLanguage == code
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        languageProvider.setLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.language, color: iconColor ?? Colors.white),
      onPressed: () => _showLanguageDialog(context),
      tooltip: context.read<LanguageProvider>().tr('common.changeLanguage'),
    );
  }
}
