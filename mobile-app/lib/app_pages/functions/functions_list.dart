import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class FunctionsList extends StatefulWidget {
  final bool embeddedInShell;

  const FunctionsList({super.key, this.embeddedInShell = false});

  @override
  State<FunctionsList> createState() => _FunctionsListState();
}

class _FunctionsListState extends State<FunctionsList> {
  final AlertServices alertServices = AlertServices();
  final SecureStorageService storage = SecureStorageService();
  final FunctionServices services = FunctionServices();
  final MoiServices moiServices = MoiServices();

  List functionList = [];
  List searchHistory = [];
  List user = [];
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    StartupTiming.log('FunctionsList.initState');
    // Local spinner only — never global EasyLoading while user may be on Home.
    getUserFunctions(showLoading: false);
    searchController.addListener(searchListener);
  }

  Future<void> getUserFunctions({bool showLoading = true}) async {
    await StartupTiming.timeAsync('FunctionsList.getUserFunctions', () async {
      if (showLoading && mounted) {
        setState(() => _isLoading = true);
      }
      user = [await storage.get(AppVariables.userInformation)];
      String userId = user[0]['id'].toString();
      final response = await services.getUserFunctions({
        "userId": userId,
      }, showLoading: false);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response != null && response['responseType'] == "S") {
            functionList = response['responseValue'];
            searchHistory = response['responseValue'];
          } else {
            searchHistory = [];
            functionList = [];
          }
        });
        if (searchController.text.isNotEmpty) {
          search(searchController.text);
        }
      }
    });
  }

  @override
  void dispose() {
    searchController.removeListener(searchListener);
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void searchListener() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      search(searchController.text);
    });
  }

  void search(String value) {
    if (!mounted) return;

    final filteredList = value.isEmpty
        ? functionList
        : functionList.where((element) {
            final functionName = element['functionName']
                .toString()
                .toLowerCase();
            final functionDate = element['date'].toString().toLowerCase();
            final input = value.toLowerCase();
            return functionName.contains(input) || functionDate.contains(input);
          }).toList();

    setState(() {
      searchHistory = filteredList;
    });
  }

  String _resolveImageUrl(dynamic function) {
    final raw = function['imageUrl']?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '$appImageUrl/${raw.replaceFirst(RegExp(r'^/+'), '')}';
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(context, "home", (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final scaffold = Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: MoiAppHeader(
            title: languageProvider.tr('functions.title'),
            showBack: !widget.embeddedInShell,
            onBack: _goHome,
            height: AppConstants.appHeaderHeight,
            titleFontSize: 18,
          ),
          body: MoiRefreshIndicator(
            onRefresh: () => getUserFunctions(showLoading: false),
            child: _isLoading && functionList.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.md,
                      AppSpacing.page,
                      AppSpacing.xxl,
                    ),
                    children: [
                      for (int i = 0; i < 12; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        const AppSkeletonListTile(),
                      ],
                    ],
                  )
                : functionList.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.65,
                        child: _NoFunctionsState(
                          primary: primary,
                          title: languageProvider.tr('functions.noFunctions'),
                          subtitle: languageProvider.tr(
                            'functions.noFunctionsHint',
                          ),
                        ),
                      ),
                    ],
                  )
                : mainContent(languageProvider, primary),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                "add-edit-functions",
                arguments: [],
              );
              if (mounted) await getUserFunctions(showLoading: false);
            },
            elevation: 2,
            highlightElevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: primary,
            tooltip: languageProvider.tr('functions.addFunction'),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : Colors.black,
              size: 24,
              strokeWidth: 2,
            ),
          ),
        );

        if (widget.embeddedInShell) return scaffold;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _goHome();
          },
          child: scaffold,
        );
      },
    );
  }

  Widget mainContent(LanguageProvider languageProvider, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          SearchWidget(
            controller: searchController,
            hintText: languageProvider.tr('functions.search'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (searchHistory.isEmpty)
            Expanded(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptySearchState(
                      primary: primary,
                      title: languageProvider.tr('functions.noFunctions'),
                      subtitle: languageProvider.tr(
                        'functions.tryAdjustSearch',
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: searchHistory.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final function = searchHistory[index];
                  final name =
                      function['functionName']?.toString().trim() ?? '-';
                  return _FunctionRow(
                    primary: primary,
                    title: name.toUpperCase(),
                    dateDay: formatFunctionDateWithDay(
                      function['functionDate']?.toString(),
                    ),
                    imageUrl: _resolveImageUrl(function),
                    onTap: () => showSheet(context, [function]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void deleteRecord(String id) async {
    final response = await services.deleteUserBaseFunctions(id.toString());
    if (response != null && response['responseType'] == "S") {
      String msg = response['responseValue']['message'].toString();
      alertServices.successToast(msg);
      getUserFunctions(showLoading: false);
    }
  }

  void showSheet(BuildContext context, List data) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    showMoiActionSheet(
      context: context,
      title: languageProvider.tr('common.chooseAction'),
      titleColor: colorScheme.primary,
      actions: [
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedView,
          title: languageProvider.tr('functions.viewDetails'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              "view-functions-list",
              arguments: [data[0]],
            );
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedPencilEdit02,
          title: languageProvider.tr('functions.editFunction'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            await Navigator.pushNamed(
              context,
              "add-edit-functions",
              arguments: [data[0]],
            );
            if (mounted) await getUserFunctions(showLoading: false);
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedDelete02,
          title: languageProvider.tr('functions.deleteFunction'),
          isDestructive: true,
          onPressed: (context) async {
            Navigator.pop(context);
            final confirmDelete = await showMoiConfirmSheet(
              context: this.context,
              title: languageProvider.tr('functions.deleteFunction'),
              message: languageProvider.tr('functions.deleteConfirmation'),
              confirmLabel: languageProvider.tr('common.delete'),
              cancelLabel: languageProvider.tr('common.cancel'),
              icon: HugeIcons.strokeRoundedDelete02,
              isDestructive: true,
            );
            if (confirmDelete == true && mounted) {
              String id = data[0]['id'].toString();
              deleteRecord(id);
            }
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedCancel01,
          title: languageProvider.tr('common.cancel'),
          isCancel: true,
          onPressed: (context) async {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _NoFunctionsState extends StatefulWidget {
  final Color primary;
  final String title;
  final String subtitle;

  const _NoFunctionsState({
    required this.primary,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_NoFunctionsState> createState() => _NoFunctionsStateState();
}

class _NoFunctionsStateState extends State<_NoFunctionsState> {
  @override
  Widget build(BuildContext context) {
    return MoiEmptyState(
      title: widget.title,
      subtitle: widget.subtitle,
      imagePath: 'assets/images/empty-state/function-empty.png',
      accentColor: widget.primary,
      imageSize: 100,
    );
  }
}

class _EmptySearchState extends StatefulWidget {
  final Color primary;
  final String title;
  final String subtitle;

  const _EmptySearchState({
    required this.primary,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_EmptySearchState> createState() => _EmptySearchStateState();
}

class _EmptySearchStateState extends State<_EmptySearchState> {
  @override
  Widget build(BuildContext context) {
    return MoiEmptyState(
      title: widget.title,
      subtitle: widget.subtitle,
      imagePath: 'assets/images/empty-state/function-empty.png',
      accentColor: widget.primary,
      imageSize: 80,
    );
  }
}

class _FunctionRow extends StatelessWidget {
  final Color primary;
  final String title;
  final String dateDay;
  final String imageUrl;
  final VoidCallback onTap;

  const _FunctionRow({
    required this.primary,
    required this.title,
    required this.dateDay,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: primary.withValues(alpha: 0.06),
        highlightColor: primary.withValues(alpha: 0.03),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              _Leading(primary: primary, imageUrl: imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (dateDay.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateDay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: colors.textMuted,
                size: 18,
                strokeWidth: 1.9,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  final Color primary;
  final String imageUrl;

  const _Leading({required this.primary, required this.imageUrl});

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedWedding,
        color: primary,
        size: 22,
        strokeWidth: 1.7,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: imageUrl.isEmpty ? primary.withValues(alpha: 0.1) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? _placeholder()
          : MoiNetworkImage(
              url: imageUrl,
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
    );
  }
}
