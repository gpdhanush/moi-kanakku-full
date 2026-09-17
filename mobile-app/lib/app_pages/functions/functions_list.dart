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
    getUserFunctions();
    searchController.addListener(searchListener);
  }

  Future<void> getUserFunctions({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    user = [await storage.get(AppVariables.userInformation)];
    String userId = user[0]['id'].toString();
    final response = await services.getUserFunctions(
      {"userId": userId},
      showLoading: showLoading,
    );
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
    final primary = Theme.of(context).colorScheme.primary;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final scaffold = Scaffold(
            backgroundColor: AppColors.background,
            appBar: MoiAppHeader(
              title: languageProvider.tr('functions.title'),
              showBack: !widget.embeddedInShell,
              onBack: _goHome,
              height: 72,
              titleFontSize: 18,
            ),
            body: MoiRefreshIndicator(
              onRefresh: () => getUserFunctions(showLoading: false),
              child: _isLoading && functionList.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
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
                            subtitle:
                                languageProvider.tr('functions.noFunctionsHint'),
                            actionLabel:
                                languageProvider.tr('functions.addFunction'),
                            onAdd: () async {
                              await Navigator.pushNamed(
                                context,
                                "add-edit-functions",
                                arguments: [],
                              );
                              if (mounted) {
                                await getUserFunctions(showLoading: false);
                              }
                            },
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
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: Colors.white,
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
            bool? confirmDelete = await alertServices.confirmAlert(
              context,
              languageProvider.tr('functions.deleteConfirmation'),
            );
            if (confirmDelete!) {
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
  final String actionLabel;
  final VoidCallback onAdd;

  const _NoFunctionsState({
    required this.primary,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAdd,
  });

  @override
  State<_NoFunctionsState> createState() => _NoFunctionsStateState();
}

class _NoFunctionsStateState extends State<_NoFunctionsState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scale = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: reduceMotion ? const AlwaysStoppedAnimation(1) : _scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.primary.withValues(alpha: 0.06),
                    ),
                  ),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xffE4E4E7)),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primary.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: const Color(
                            0xff09090B,
                          ).withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedWedding,
                      color: widget.primary,
                      size: 34,
                      strokeWidth: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle.copyWith(
                color: const Color(0xff18181B),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: const Color(0xff71717A),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: widget.primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: widget.onAdd,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedAdd01,
                            color: Colors.white,
                            size: 18,
                            strokeWidth: 2,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.actionLabel,
                            style: AppTypography.label.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (reduceMotion) return content;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: content),
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

class _EmptySearchStateState extends State<_EmptySearchState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.9,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xffE4E4E7)),
                boxShadow: [
                  BoxShadow(
                    color: widget.primary.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSearchRemove,
                color: widget.primary.withValues(alpha: 0.8),
                size: 30,
                strokeWidth: 1.8,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle.copyWith(
                color: const Color(0xff18181B),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: const Color(0xff71717A),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );

    if (reduceMotion) return content;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: content),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: primary.withValues(alpha: 0.06),
        highlightColor: primary.withValues(alpha: 0.03),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffE4E4E7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff09090B).withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: const Color(0xff09090B).withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
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
                        color: const Color(0xff18181B),
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
                          color: const Color(0xff71717A),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: const Color(0xffA1A1AA),
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
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
    );
  }
}
