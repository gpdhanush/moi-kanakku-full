import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/app_widgets/app_no_data_found.dart';
import 'package:moi/app_utils/app_widgets/moi_list_item.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/custom_action_sheet.dart';
import 'dart:async';
import 'package:provider/provider.dart';

class FunctionsList extends StatefulWidget {
  const FunctionsList({super.key});

  @override
  State<FunctionsList> createState() => _FunctionsListState();
}

class _FunctionsListState extends State<FunctionsList> {
  // Services and storage instances
  final AlertServices alertServices = AlertServices();
  final SecureStorageService storage = SecureStorageService();
  final FunctionServices services = FunctionServices();
  final MoiServices moiServices = MoiServices();

  // Data lists
  List functionList = [];
  List searchHistory = [];
  List user = [];
  final TextEditingController searchController = TextEditingController();

  // Search debounce
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    getUserFunctions();
    searchController.addListener(searchListener);
  }

  // Fetches user functions from the service
  Future<void> getUserFunctions() async {
    user = [await storage.get(AppVariables.userInformation)];
    String userId = user[0]['id'].toString();
    final response = await services.getUserFunctions({"userId": userId});
    if (mounted) {
      setState(() {
        if (response != null && response['responseType'] == "S") {
          functionList = response['responseValue'];
          searchHistory = response['responseValue'];
        } else {
          searchHistory = [];
          functionList = [];
        }
      });
    }
  }

  @override
  void dispose() {
    searchController.removeListener(searchListener);
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Listener for search input changes with debouncing
  void searchListener() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      search(searchController.text);
    });
  }

  // Filters the function list based on the search input
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

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            Navigator.pushNamedAndRemoveUntil(context, "home", (r) => false);
          },
          child: Scaffold(
            appBar: AppBarWidget(
              title:
                  '${languageProvider.tr('functions.title')} (${functionList.length})',
              action: [],
            ),
            body: functionList.isEmpty
                ? const AppNoDataFound(showSecond: true)
                : mainContent(languageProvider),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  "add-edit-functions",
                  arguments: [],
                );
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              tooltip: languageProvider.tr('functions.addFunction'),
              child: const Icon(Icons.add_outlined, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  // Main content widget displaying the list of functions
  Widget mainContent(LanguageProvider languageProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.celebration_outlined,
                    color: colorScheme.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    languageProvider.tr('functions.title'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${functionList.length}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontFamily: 'Arimo',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: SearchWidget(
              controller: searchController,
              hintText: languageProvider.tr('functions.search'),
            ),
          ),
          const SizedBox(height: 14),
          if (searchHistory.isEmpty)
            Expanded(
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
                        size: 64,
                        color: colorScheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      languageProvider.tr('functions.noFunctions'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      languageProvider.tr('functions.tryAdjustSearch'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: searchHistory.length,
                itemBuilder: (context, index) {
                  final function = searchHistory[index];
                  return MoiListItem(
                    leadingIcon: Icons.celebration_outlined,
                    accentColor: colorScheme.primary,
                    title:
                        function['functionName']?.toString().toTitleCase() ??
                        '-',
                    subtitle: formatFunctionDate(
                      function['functionDate']?.toString(),
                    ),
                    onTap: () => showSheet(context, [function]),
                    trailing: Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Deletes a function record
  void deleteRecord(String id) async {
    final response = await services.deleteUserBaseFunctions(id.toString());
    if (response != null && response['responseType'] == "S") {
      String msg = response['responseValue']['message'].toString();
      alertServices.successToast(msg);
      getUserFunctions();
    }
  }

  // Displays an action sheet with options for the selected function
  void showSheet(BuildContext context, List data) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    showCustomActionSheet(
      context: context,
      // title: languageProvider.tr('functions.selectOption'),
      title: "",
      titleColor: colorScheme.primary,
      actions: [
        ActionSheetItem(
          icon: Icons.visibility_outlined,
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
          icon: Icons.edit_outlined,
          title: languageProvider.tr('functions.editFunction'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              "add-edit-functions",
              arguments: [data[0]],
            );
          },
        ),
        ActionSheetItem(
          icon: Icons.delete_outlined,
          title: languageProvider.tr('functions.deleteFunction'),
          color: Colors.redAccent,
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
          icon: Icons.close_outlined,
          title: languageProvider.tr('common.cancel'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
