import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_models/index.dart';
import 'package:moi/app_pages/transactions/edit_person_page.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class TransactionDashboard extends StatefulWidget {
  final bool embeddedInShell;

  const TransactionDashboard({super.key, this.embeddedInShell = false});

  @override
  State<TransactionDashboard> createState() => _TransactionDashboardState();
}

class _TransactionDashboardState extends State<TransactionDashboard> {
  static const int _pageSize = 40;

  final SecureStorageService storage = SecureStorageService();
  final AlertServices alertServices = AlertServices();
  final TransactionServices txServices = TransactionServices();
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> persons = [];
  String? _userId;
  Timer? _searchDebounce;

  int _page = 1;
  int _totalCount = 0;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    searchController.addListener(_onSearchChanged);
    fetchPersonLists(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      fetchPersonLists(reset: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        !_hasMore ||
        _isLoadingMore ||
        _isLoading) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      fetchPersonLists(reset: false);
    }
  }

  Future<void> fetchPersonLists({required bool reset}) async {
    if (reset) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _page = 1;
          _hasMore = true;
        });
      }
    } else {
      if (!_hasMore || _isLoadingMore || _isLoading) return;
      if (mounted) setState(() => _isLoadingMore = true);
    }

    try {
      _userId ??= await _resolveUserId();
      if (_userId == null || _userId!.isEmpty) {
        if (mounted) _clearDashboardState();
        return;
      }

      final pageToLoad = reset ? 1 : _page + 1;
      final searchQuery = searchController.text.trim();

      final response = await txServices.getPersons(
        {
          'userId': _userId,
          'page': pageToLoad,
          'limit': _pageSize,
          if (searchQuery.isNotEmpty) 'search': searchQuery,
        },
        showLoading: false,
      );
      printDirect('Dashboard Response page=$pageToLoad: $response');

      if (response == null || response is! Map) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            if (reset) {
              persons = [];
              _totalCount = 0;
              _hasMore = false;
            }
          });
        }
        return;
      }

      if (response['responseType'] == 'S') {
        final responseValue = response['responseValue'];
        final chunk = responseValue is List
            ? List<Map<String, dynamic>>.from(
                responseValue.map(
                  (e) => e is Map
                      ? Map<String, dynamic>.from(e)
                      : <String, dynamic>{},
                ),
              )
            : <Map<String, dynamic>>[];

        final total = response['count'] is int
            ? response['count'] as int
            : int.tryParse(response['count']?.toString() ?? '') ??
                (reset ? chunk.length : _totalCount);
        final hasMore = response['hasMore'] == true ||
            (response['hasMore'] == null && chunk.length >= _pageSize);

        if (mounted) {
          setState(() {
            if (reset) {
              persons = chunk;
            } else {
              persons = [...persons, ...chunk];
            }
            _page = pageToLoad;
            _totalCount = total;
            _hasMore = hasMore && chunk.isNotEmpty;
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          if (reset) {
            persons = [];
            _totalCount = 0;
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          if (reset) {
            persons = [];
            _totalCount = 0;
            _hasMore = false;
          }
        });
        alertServices.errorToast(
          context.read<LanguageProvider>().tr('transactions.loadError'),
        );
      }
    }
  }

  Future<String?> _resolveUserId() async {
    final userData = await storage.get(AppVariables.userInformation);
    if (userData == null || userData is! Map) return null;
    return userData['id']?.toString();
  }

  void _clearDashboardState() {
    setState(() {
      persons = [];
      _totalCount = 0;
      _page = 1;
      _hasMore = false;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  Future<void> _deletePerson(
    String personId,
    LanguageProvider languageProvider,
  ) async {
    try {
      if (personId.isEmpty) {
        alertServices.errorToast(
          languageProvider.tr('transactions.personIdMissing'),
        );
        return;
      }

      alertServices.showLoading();
      final response = await txServices.deletePerson(
        personId,
        showLoading: false,
      );
      alertServices.hideLoading();

      if (response == null) {
        alertServices.errorToast(
          languageProvider.tr('transactions.noServerResponse'),
        );
        return;
      }

      if (response is! Map) {
        alertServices.errorToast(
          languageProvider.tr('transactions.invalidResponse'),
        );
        return;
      }

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['responseType'] == 'S') {
        final message =
            responseMap['responseValue']?['message']?.toString() ??
            languageProvider.tr('transactions.personDeleted');
        alertServices.successToast(message);
        if (mounted) fetchPersonLists(reset: true);
      } else {
        final errorMsg =
            responseMap['responseValue']?['message']?.toString() ??
            languageProvider.tr('transactions.deleteFailed');
        alertServices.errorToast(errorMsg);
      }
    } catch (e, stackTrace) {
      alertServices.hideLoading();
      debugPrint('Error deleting person: $e');
      debugPrint('Stack trace: $stackTrace');
      alertServices.errorToast(languageProvider.tr('transactions.deleteError'));
    }
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(context, 'home', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final scaffold = Scaffold(
          backgroundColor: AppColors.background,
          appBar: MoiAppHeader(
            title: languageProvider.tr('nav.overview'),
            showBack: !widget.embeddedInShell,
            onBack: _goHome,
          ),
          body: _isLoading && persons.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : _buildBody(languageProvider),
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

  Widget _buildBody(LanguageProvider languageProvider) {
    final primary = Theme.of(context).colorScheme.primary;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              0,
            ),
            child: Column(
              children: [
                SearchWidget(
                  controller: searchController,
                  hintText: languageProvider.tr('transactions.search'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildActionButtons(languageProvider),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        _buildPersonsSliverList(languageProvider, primary),
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  Widget _buildActionButtons(LanguageProvider languageProvider) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: languageProvider.tr('transactions.newInvest'),
            color: AppColors.moiReceived,
            icon: HugeIcons.strokeRoundedArrowDownLeft01,
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                'add-edit-transaction',
                arguments: {'type': 'INVEST'},
              );
              if (result == true && mounted) fetchPersonLists(reset: true);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            label: languageProvider.tr('transactions.newReturn'),
            color: AppColors.moiGiven,
            icon: HugeIcons.strokeRoundedArrowUpRight01,
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                'add-edit-transaction',
                arguments: [
                  {'type': 'RETURN'},
                ],
              );
              if (result == true && mounted) fetchPersonLists(reset: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPersonsSliverList(
    LanguageProvider languageProvider,
    Color primary,
  ) {
    final isSearching = searchController.text.trim().isNotEmpty;

    if (persons.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: MoiEmptyState(
          title: languageProvider.tr('transactions.noPersonsFound'),
          subtitle: isSearching
              ? languageProvider.tr('functions.tryAdjustSearch')
              : languageProvider.tr('transactions.emptyHint'),
          icon: isSearching
              ? HugeIcons.strokeRoundedSearchRemove
              : HugeIcons.strokeRoundedUser,
          accentColor: primary,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      sliver: SliverList.separated(
        itemCount: persons.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final person = persons[index];
          final firstName = person['firstName']?.toString() ?? '';
          final secondName = person['secondName']?.toString() ?? '';
          final business = person['business']?.toString() ?? '';
          final city = person['city']?.toString() ?? '';
          final mobile = person['mobile']?.toString() ?? '';
          final displayName =
              '${firstName.toTitleCase()} ${secondName.toTitleCase()}'.trim();
          final subtitle = [
            if (city.isNotEmpty) city.toUpperCase(),
            if (mobile.isNotEmpty) mobile,
            if (business.isNotEmpty) business.toUpperCase(),
          ].join(' · ');

          Future<void> openDetails() async {
            final result = await Navigator.pushNamed(
              context,
              'transaction-person-details',
              arguments: PersonResponseModel.fromJson(person),
            );
            if (result == true && mounted) fetchPersonLists(reset: true);
          }

          Future<void> editPerson() async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditPersonPage(
                  person: PersonResponseModel.fromJson(person),
                ),
              ),
            );
            if (result == true && mounted) fetchPersonLists(reset: true);
          }

          Future<void> deletePerson() async {
            final personModel = PersonResponseModel.fromJson(person);
            final confirm = await showMoiConfirmSheet(
              context: context,
              title: languageProvider.tr('transactions.deleteTitle'),
              message: languageProvider.tr('transactions.deleteConfirmation'),
              confirmLabel: languageProvider.tr('common.delete'),
              cancelLabel: languageProvider.tr('common.cancel'),
              icon: HugeIcons.strokeRoundedDelete02,
              isDestructive: true,
            );
            if (confirm == true && mounted) {
              await _deletePerson(personModel.id.toString(), languageProvider);
            }
          }

          return _PersonCard(
            primary: primary,
            title: displayName.isEmpty ? '—' : displayName,
            subtitle: subtitle,
            onTap: openDetails,
            onEdit: editPerson,
            onDelete: deletePerson,
            editTooltip: languageProvider.tr('transactions.edit'),
            deleteTooltip: languageProvider.tr('transactions.delete'),
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final List<List<dynamic>> icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                color: Colors.white,
                size: 16,
                strokeWidth: 1.9,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Color primary;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editTooltip;
  final String deleteTooltip;

  const _PersonCard({
    required this.primary,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.editTooltip,
    required this.deleteTooltip,
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
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffE4E4E7)),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  color: primary,
                  size: 20,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _IconAction(
                icon: HugeIcons.strokeRoundedPencilEdit02,
                color: primary,
                tooltip: editTooltip,
                onTap: onEdit,
              ),
              const SizedBox(width: 4),
              _IconAction(
                icon: HugeIcons.strokeRoundedDelete02,
                color: AppColors.moiGiven,
                tooltip: deleteTooltip,
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: color,
                size: 16,
                strokeWidth: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
