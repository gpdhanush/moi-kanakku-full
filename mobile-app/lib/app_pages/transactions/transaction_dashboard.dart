import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_models/index.dart';
import 'package:moi/app_pages/transactions/edit_person_page.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/app_no_data_found.dart';
import 'package:moi/app_utils/app_widgets/moi_list_item.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class TransactionDashboard extends StatefulWidget {
  const TransactionDashboard({super.key});

  @override
  State<TransactionDashboard> createState() => _TransactionDashboardState();
}

class _TransactionDashboardState extends State<TransactionDashboard> {
  SecureStorageService storage = SecureStorageService();
  AlertServices alertServices = AlertServices();
  MoiServices moiServices = MoiServices();

  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> persons = [];
  List<Map<String, dynamic>> filteredPersons = [];
  final txServices = TransactionServices();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchPersonLists();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterPersons();
  }

  void _filterPersons() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      if (mounted) {
        final newList = List<Map<String, dynamic>>.from(persons);
        if (!listEquals(filteredPersons, newList)) {
          setState(() {
            filteredPersons = newList;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          filteredPersons = persons.where((person) {
            final firstName =
                (person['firstName']?.toString().toLowerCase()) ?? '';
            final secondName =
                (person['secondName']?.toString().toLowerCase()) ?? '';
            final business =
                (person['business']?.toString().toLowerCase()) ?? '';
            final city = (person['city']?.toString().toLowerCase()) ?? '';
            final mobile = (person['mobile']?.toString().toLowerCase()) ?? '';
            final searchText = '$firstName $secondName $business $city $mobile';
            return searchText.contains(query);
          }).toList();
        });
      }
    }
  }

  Future<void> fetchPersonLists() async {
    try {
      final userData = await storage.get(AppVariables.userInformation);
      if (userData == null || userData is! Map) {
        if (mounted) _clearDashboardState();
        return;
      }

      final userId = userData['id']?.toString();
      if (userId == null || userId.isEmpty) {
        if (mounted) _clearDashboardState();
        return;
      }

      final request = {"userId": userId};
      // Connection shows a single loader — avoid stacking EasyLoading here
      final response = await txServices.getPersons(request);
      printDirect("Dashboard Response: $response");
      if (response == null || response is! Map) {
        if (mounted) _clearDashboardState();
        return;
      }

      if (response['responseType'] == "S") {
        final responseValue = response['responseValue'];
        // new API returns a list of person objects directly
        if (responseValue == null || responseValue is! List) {
          if (mounted) _clearDashboardState();
          return;
        }

        final newPersons = List<Map<String, dynamic>>.from(
          (responseValue).map(
            (e) =>
                e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
          ),
        );

        if (mounted) {
          setState(() {
            persons = newPersons;
            filteredPersons = List<Map<String, dynamic>>.from(newPersons);
          });
        }
      } else {
        if (mounted) _clearDashboardState();
      }
    } catch (e) {
      if (mounted) _clearDashboardState();
      final languageProvider = context.read<LanguageProvider>();
      alertServices.errorToast(languageProvider.tr('transactions.loadError'));
    }
  }

  void _clearDashboardState() {
    setState(() {
      persons = [];
      filteredPersons = [];
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
      // Handle different response types
      if (response == null) {
        alertServices.errorToast(
          languageProvider.tr('transactions.noServerResponse'),
        );
        return;
      }

      // Ensure response is a Map
      if (response is! Map) {
        alertServices.errorToast(
          languageProvider.tr('transactions.invalidResponse'),
        );
        return;
      }

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['responseType'] == "S") {
        final message =
            responseMap['responseValue']?['message']?.toString() ??
            languageProvider.tr('transactions.personDeleted');
        alertServices.successToast(message);
        if (mounted) {
          fetchPersonLists();
        }
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

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.pushNamedAndRemoveUntil(context, "home", (r) => false);
          },
          child: Scaffold(
            appBar: AppBarWidget(
              title:
                  '${languageProvider.tr('transactions.title')} (${persons.length})',
              action: [],
            ),
            body: _buildBody(languageProvider),
          ),
        );
      },
    );
  }

  Widget _buildBody(LanguageProvider languageProvider) {
    return RefreshIndicator(
      onRefresh: fetchPersonLists,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildSearchAndFilter(languageProvider),
                  const SizedBox(height: 12),
                  _buildActionButtons(languageProvider),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _buildPersonsSliverList(languageProvider),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(LanguageProvider languageProvider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          ),
          child: SearchWidget(
            controller: searchController,
            hintText: languageProvider.tr('transactions.search'),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(LanguageProvider languageProvider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                "add-edit-transaction",
                arguments: {"type": "INVEST"},
              );
              if (result == true) {
                fetchPersonLists();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 3, 153, 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.south_west_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    languageProvider.tr('transactions.newInvest'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                "add-edit-transaction",
                arguments: [
                  {"type": "RETURN"},
                ],
              );
              if (result == true) {
                fetchPersonLists();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.north_east_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    languageProvider.tr('transactions.newReturn'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonsSliverList(LanguageProvider languageProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    if (filteredPersons.isEmpty && persons.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          // child: Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 32),
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     crossAxisAlignment: CrossAxisAlignment.center,
          //     children: [
          //       Container(
          //         width: 75,
          //         height: 75,
          //         decoration: BoxDecoration(
          //           gradient: LinearGradient(
          //             colors: [
          //               colorScheme.primary.withAlpha((0.15 * 255).toInt()),
          //               colorScheme.primary.withAlpha((0.05 * 255).toInt()),
          //             ],
          //             begin: Alignment.topLeft,
          //             end: Alignment.bottomRight,
          //           ),
          //           shape: BoxShape.circle,
          //         ),
          //         child: Icon(
          //           Icons.people_outline,
          //           size: 50,
          //           color: colorScheme.primary.withAlpha((0.7 * 255).toInt()),
          //         ),
          //       ),
          //       const SizedBox(height: 28),
          //       Text(
          //         'பதிவுகள் இல்லை',
          //         textAlign: TextAlign.center,
          //         style: Theme.of(context).textTheme.titleMedium?.copyWith(
          //           color: colorScheme.primary,
          //           fontWeight: FontWeight.w500,
          //         ),
          //         // style: TextStyle(
          //         //   fontSize: 20,
          //         //   fontWeight: FontWeight.w700,
          //         //   color: colorScheme.primary,
          //         // ),
          //       ),
          //       const SizedBox(height: 10),
          //       Text(
          //         'புதிய நபர்களை சேர்த்தால் இங்கே காண்பிக்கப்படும்.',
          //         textAlign: TextAlign.center,
          //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //           color: Colors.grey.shade600,
          //           fontWeight: FontWeight.normal,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          child: AppNoDataFound(showSecond: false),
        ),
      );
    }

    if (filteredPersons.isEmpty && persons.isNotEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_outlined,
                  size: 50,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                languageProvider.tr('transactions.noPersonsFound'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontFamily: 'RobotoBold',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final person = filteredPersons[index];
          final firstName = person['firstName']?.toString() ?? '';
          final secondName = person['secondName']?.toString() ?? '';
          final business = person['business']?.toString() ?? '';
          final city = person['city']?.toString() ?? '';
          final mobile = person['mobile']?.toString() ?? '';
          final displayName =
              '${firstName.toTitleCase()} ${secondName.toTitleCase()}'.trim();
          final subtitle = [
            if (city.isNotEmpty) city.toTitleCase(),
            if (mobile.isNotEmpty) mobile,
            if (business.isNotEmpty) business.toTitleCase(),
          ].join(' | ');

          Future<void> openDetails() async {
            final result = await Navigator.pushNamed(
              context,
              "transaction-person-details",
              arguments: PersonResponseModel.fromJson(person),
            );
            if (result == true && mounted) fetchPersonLists();
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
            if (result == true && mounted) fetchPersonLists();
          }

          Future<void> deletePerson() async {
            final personModel = PersonResponseModel.fromJson(person);
            final confirm = await alertServices.confirmAlert(
              context,
              languageProvider.tr('transactions.deleteConfirmation'),
            );
            if (confirm == true && mounted) {
              await _deletePerson(personModel.id.toString(), languageProvider);
            }
          }

          return RepaintBoundary(
            child: MoiListItem(
              leadingIcon: Icons.person_outline,
              accentColor: colorScheme.primary,
              title: displayName.isEmpty ? '-' : displayName,
              subtitle: subtitle,
              onTap: openDetails,
              actions: [
                _buildPersonAction(
                  icon: Icons.edit_outlined,
                  color: colorScheme.primary,
                  tooltip: languageProvider.tr('transactions.edit'),
                  onPressed: editPerson,
                ),
                _buildPersonAction(
                  icon: Icons.delete_outline,
                  color: Colors.redAccent,
                  tooltip: languageProvider.tr('transactions.delete'),
                  onPressed: deletePerson,
                ),
              ],
            ),
          );
        }, childCount: filteredPersons.length),
      ),
    );
  }

  Widget _buildPersonAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 19),
      color: color,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.09),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
      ),
    );
  }
}
