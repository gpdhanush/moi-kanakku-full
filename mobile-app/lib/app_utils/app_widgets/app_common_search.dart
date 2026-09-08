import 'package:flutter/material.dart';
import 'package:moi/app_utils/app_widgets/app_search.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class AppCommonSearch extends StatelessWidget {
  final TextEditingController controller;

  const AppCommonSearch({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      width: double.infinity,
      child: SearchWidget(
        controller: controller,
        hintText: context.watch<LanguageProvider>().tr('common.search'),
      ),
    );
  }
}
