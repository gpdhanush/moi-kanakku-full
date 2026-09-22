import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/upcoming_functions/models/upcoming_function_model.dart';
import 'package:moi/app_services/upcoming_function_services.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class UpcomingFunctionList extends StatefulWidget {
  const UpcomingFunctionList({super.key});

  @override
  State<UpcomingFunctionList> createState() => _UpcomingFunctionListState();
}

class _UpcomingFunctionListState extends State<UpcomingFunctionList> {
  final AlertServices alertServices = AlertServices();
  final UpcomingFunctionServices services = UpcomingFunctionServices();

  List<UpcomingFunction> upcomingFunctionList = [];
  List<UpcomingFunction> searchHistory = [];
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // No global loader on first paint — list shows its own empty/loading UI.
    getUpcomingFunctions(showLoading: false);
    searchController.addListener(searchListener);
  }

  Future<void> getUpcomingFunctions({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => isLoading = true);
    }

    try {
      final response = await services.getUpcomingFunctions(
        showLoading: showLoading,
      );

      if (!mounted) return;

      setState(() {
        if (response != null && response['responseType'] == 'S') {
          final list = response['responseValue'] ?? [];
          upcomingFunctionList = List<UpcomingFunction>.from(
            list.map((item) => UpcomingFunction.fromJson(item)),
          );
          searchHistory = upcomingFunctionList;
        } else {
          searchHistory = [];
          upcomingFunctionList = [];
        }
        isLoading = false;
      });

      if (searchController.text.isNotEmpty) {
        search(searchController.text);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoading = false;
          searchHistory = [];
          upcomingFunctionList = [];
        });
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
        ? upcomingFunctionList
        : upcomingFunctionList.where((element) {
            final title = element.title.toLowerCase();
            final date = element.functionDate.toLowerCase();
            final location = element.location.toLowerCase();
            final input = value.toLowerCase();
            return title.contains(input) ||
                date.contains(input) ||
                location.contains(input);
          }).toList();

    setState(() => searchHistory = filteredList);
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.pushNamedAndRemoveUntil(context, 'home', (r) => false);
    }
  }

  String _resolveImageUrl(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '$appImageUrl/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _goBack();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: MoiFlowAppHeader(
              title:
                  '${languageProvider.tr('upcomingFunctions.title').toTitleCase()} (${upcomingFunctionList.length})',
              onBack: _goBack,
              accent: primary,
            ),
            body: isLoading && upcomingFunctionList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.md,
                      AppSpacing.page,
                      AppSpacing.xxl,
                    ),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      children: [
                        for (int i = 0; i < 12; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.sm),
                          const AppSkeletonListTile(showTrailing: true),
                        ],
                      ],
                    ),
                  )
                : upcomingFunctionList.isEmpty
                ? _EmptyUpcomingState(
                    primary: primary,
                    title: languageProvider.tr('upcomingFunctions.noFunctions'),
                    subtitle: languageProvider.tr(
                      'upcomingFunctions.noFunctionsHint',
                    ),
                    actionLabel: languageProvider.tr(
                      'upcomingFunctions.addFunction',
                    ),
                    onAdd: _openAdd,
                  )
                : _buildMainContent(languageProvider, primary),
            floatingActionButton: FloatingActionButton(
              onPressed: _openAdd,
              elevation: 2,
              highlightElevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: primary,
              tooltip: languageProvider.tr('upcomingFunctions.addFunction'),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                strokeWidth: 2,
                size: 24,
                color: isDark ? AppColors.charcoal : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAdd() async {
    final result = await Navigator.pushNamed(
      context,
      'add-edit-upcoming-function',
      arguments: UpcomingFunction(
        id: '',
        userId: '',
        title: '',
        functionDate: '',
        location: '',
        status: 'ACTIVE',
      ),
    );
    if (result == true && mounted) {
      await getUpcomingFunctions(showLoading: false);
    }
  }

  Widget _buildMainContent(LanguageProvider languageProvider, Color primary) {
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
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: MoiEmptyState(
                      title: languageProvider.tr(
                        'upcomingFunctions.noFunctions',
                      ),
                      subtitle: languageProvider.tr(
                        'functions.tryAdjustSearch',
                      ),
                      icon: HugeIcons.strokeRoundedSearchRemove,
                      accentColor: primary,
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: searchHistory.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final function = searchHistory[index];
                  return _UpcomingFunctionCard(
                    title: function.title.toUpperCase(),
                    date: function.functionDate,
                    location: function.location,
                    statusLabel: _getStatusText(function.status),
                    statusColor: _getStatusColor(function.status),
                    imageUrl: _resolveImageUrl(function.invitationUrl),
                    onTap: () => _showFunctionSheet(function),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF2E7D32);
      case 'CANCELLED':
        return AppColors.moiGiven;
      case 'COMPLETED':
        return const Color(0xFFE65100);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getStatusText(String status) {
    final languageProvider = context.read<LanguageProvider>();
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

  void _showFunctionSheet(UpcomingFunction function) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    showMoiActionSheet(
      context: context,
      title: languageProvider.tr('common.chooseAction'),
      titleColor: colorScheme.primary,
      actions: [
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedView,
          title: languageProvider.tr('common.viewDetails'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            _viewFunction(function);
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedRefresh,
          title: languageProvider.tr('upcomingFunctions.changeStatus'),
          color: AppColors.accentAmber,
          onPressed: (sheetContext) async {
            Navigator.pop(sheetContext);
            await Future<void>.delayed(const Duration(milliseconds: 220));
            if (!mounted) return;
            await _showStatusChangeSheet(function);
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedPencilEdit02,
          title: languageProvider.tr('common.edit'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            _editFunction(function);
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedDelete02,
          title: languageProvider.tr('common.delete'),
          isDestructive: true,
          onPressed: (sheetContext) async {
            Navigator.pop(sheetContext);
            await Future<void>.delayed(const Duration(milliseconds: 220));
            if (!mounted) return;
            await _confirmDelete(function);
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

  Future<void> _showStatusChangeSheet(UpcomingFunction function) async {
    final languageProvider = context.read<LanguageProvider>();

    final options =
        <({String code, String label, Color color, List<List<dynamic>> icon})>[
          (
            code: 'ACTIVE',
            label: languageProvider.tr('upcomingFunctions.active'),
            color: const Color(0xFF2E7D32),
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
          ),
          (
            code: 'CANCELLED',
            label: languageProvider.tr('upcomingFunctions.cancelled'),
            color: AppColors.moiGiven,
            icon: HugeIcons.strokeRoundedCancelCircle,
          ),
          (
            code: 'COMPLETED',
            label: languageProvider.tr('upcomingFunctions.completed'),
            color: const Color(0xFFE65100),
            icon: HugeIcons.strokeRoundedTick02,
          ),
        ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final current = function.status.toUpperCase();

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 8),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.of(sheetContext).surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.of(sheetContext).border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.of(sheetContext).border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedRefresh,
                        strokeWidth: 1.8,
                        size: 28,
                        color: AppColors.accentAmber,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      languageProvider.tr('upcomingFunctions.changeStatus'),
                      textAlign: TextAlign.center,
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.of(sheetContext).textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      function.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: AppColors.of(sheetContext).textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final option in options) ...[
                      _StatusOptionTile(
                        label: option.label,
                        color: option.color,
                        icon: option.icon,
                        selected: current == option.code,
                        onTap: () => Navigator.pop(sheetContext, option.code),
                      ),
                      if (option != options.last) const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Material(
                        color: AppColors.of(sheetContext).surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => Navigator.pop(sheetContext),
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: Text(
                              languageProvider.tr('common.cancel'),
                              style: AppTypography.label.copyWith(
                                color: AppColors.of(sheetContext).textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selected != null &&
        selected.toUpperCase() != function.status.toUpperCase() &&
        mounted) {
      await _updateFunctionStatus(function, selected);
    }
  }

  Future<void> _updateFunctionStatus(
    UpcomingFunction function,
    String newStatus,
  ) async {
    if (!mounted) return;
    final languageProvider = context.read<LanguageProvider>();

    try {
      final response = await services.updateStatus(function.id, newStatus);

      if (response != null && response['responseType'] == 'S') {
        final index = upcomingFunctionList.indexWhere(
          (f) => f.id == function.id,
        );
        if (index != -1) {
          setState(() {
            upcomingFunctionList[index].status = newStatus;
          });
          search(searchController.text);
        }

        if (mounted) {
          alertServices.successToast(
            languageProvider.tr('upcomingFunctions.statusUpdated'),
          );
        }
      } else if (mounted) {
        alertServices.errorToast(
          languageProvider.tr('upcomingFunctions.statusUpdateFailed'),
        );
      }
    } catch (_) {
      if (mounted) {
        alertServices.errorToast(
          languageProvider.tr('upcomingFunctions.statusUpdateFailed'),
        );
      }
    }
  }

  void _viewFunction(UpcomingFunction function) {
    Navigator.pushNamed(
      context,
      'upcoming-function-details',
      arguments: function,
    );
  }

  Future<void> _editFunction(UpcomingFunction function) async {
    final result = await Navigator.pushNamed(
      context,
      'add-edit-upcoming-function',
      arguments: function,
    );
    if (result == true && mounted) {
      await getUpcomingFunctions(showLoading: false);
    }
  }

  Future<void> _confirmDelete(UpcomingFunction function) async {
    final languageProvider = context.read<LanguageProvider>();
    final confirmed = await showMoiConfirmSheet(
      context: context,
      title: languageProvider.tr('upcomingFunctions.deleteTitle'),
      message: languageProvider.tr('upcomingFunctions.deleteConfirmation'),
      confirmLabel: languageProvider.tr('common.delete'),
      cancelLabel: languageProvider.tr('common.cancel'),
      icon: HugeIcons.strokeRoundedDelete02,
      isDestructive: true,
    );

    if (confirmed == true) {
      await _deleteFunction(function);
    }
  }

  Future<void> _deleteFunction(UpcomingFunction function) async {
    final languageProvider = context.read<LanguageProvider>();

    try {
      final response = await services.deleteUpcomingFunction(function.id);
      if (response != null && response['responseType'] == 'S') {
        setState(() {
          upcomingFunctionList.removeWhere((item) => item.id == function.id);
          searchHistory.removeWhere((item) => item.id == function.id);
        });

        final successMessage =
            response['responseValue']?['message']?.toString() ??
            languageProvider.tr('upcomingFunctions.deleted');
        alertServices.successToast(successMessage);
      } else {
        final errorMessage =
            response?['responseValue']?['message']?.toString() ??
            languageProvider.tr('upcomingFunctions.deleteFailed');
        alertServices.errorToast(errorMessage);
      }
    } catch (_) {
      alertServices.errorToast(
        languageProvider.tr('upcomingFunctions.deleteFailed'),
      );
    }
  }
}

class _StatusOptionTile extends StatelessWidget {
  final String label;
  final Color color;
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback onTap;

  const _StatusOptionTile({
    required this.label,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: selected ? color.withValues(alpha: 0.08) : colors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.45) : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: icon,
                  color: color,
                  size: 18,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.label.copyWith(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              HugeIcon(
                icon: selected
                    ? HugeIcons.strokeRoundedCheckmarkCircle02
                    : HugeIcons.strokeRoundedCircle,
                size: 20,
                color: selected ? color : colors.textMuted,
                strokeWidth: 1.8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingFunctionCard extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final String statusLabel;
  final Color statusColor;
  final String imageUrl;
  final VoidCallback onTap;

  const _UpcomingFunctionCard({
    required this.title,
    required this.date,
    required this.location,
    required this.statusLabel,
    required this.statusColor,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Ink(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.of(context).border),
            boxShadow: AppShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTypography.label.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            strokeWidth: 1.8,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              date.isNotEmpty ? date : '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (location.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              strokeWidth: 1.8,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl.isEmpty) {
      return Image.asset(AppImages.defaultImage, fit: BoxFit.cover);
    }

    return MoiNetworkImage(
      url: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      errorBuilder: (_, _, _) =>
          Image.asset(AppImages.defaultImage, fit: BoxFit.cover),
    );
  }
}

class _EmptyUpcomingState extends StatelessWidget {
  final Color primary;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAdd;

  const _EmptyUpcomingState({
    required this.primary,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return MoiEmptyState(
      title: title,
      subtitle: subtitle,
      imagePath: 'assets/images/empty-state/upcomming-function-empty.png',
      accentColor: primary,
    );
  }
}
