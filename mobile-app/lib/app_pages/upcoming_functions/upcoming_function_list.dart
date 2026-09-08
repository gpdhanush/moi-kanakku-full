import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/upcoming_function_services.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_widgets/app_no_data_found.dart';
import 'package:moi/app_utils/app_widgets/custom_action_sheet.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_pages/upcoming_functions/models/upcoming_function_model.dart';
import 'dart:async';
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
    getUpcomingFunctions();
    searchController.addListener(searchListener);
  }

  Future<void> getUpcomingFunctions() async {
    setState(() => isLoading = true);

    try {
      final response = await services.getUpcomingFunctions();

      if (mounted) {
        setState(() {
          if (response != null && response['responseType'] == "S") {
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
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pushNamedAndRemoveUntil(context, "home", (r) => false);
        },
        child: Scaffold(
          appBar: AppBarWidget(
            title: languageProvider.tr('upcomingFunctions.title'),
            action: [],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : upcomingFunctionList.isEmpty
              ? const AppNoDataFound(showSecond: true)
              : _buildMainContent(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                "add-edit-upcoming-function",
                arguments: UpcomingFunction(
                  id: '',
                  userId: '',
                  title: '',
                  functionDate: '',
                  location: '',
                  status: 'ACTIVE',
                ),
              ).then((result) {
                if (result == true) {
                  getUpcomingFunctions();
                }
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add_outlined, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: SearchWidget(
              controller: searchController,
              hintText: context.read<LanguageProvider>().tr('functions.search'),
            ),
          ),
          const SizedBox(height: 20),
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
                      context.read<LanguageProvider>().tr(
                        'upcomingFunctions.noFunctions',
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.read<LanguageProvider>().tr(
                        'functions.tryAdjustSearch',
                      ),
                      style: TextStyle(fontSize: 14, color: AppColors.fontGrey),
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
                itemBuilder: (context, index) => _buildFunctionCard(
                  searchHistory[index],
                  colorScheme,
                  index,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard(
    UpcomingFunction function,
    ColorScheme colorScheme,
    int index,
  ) {
    String imageUrl = function.invitationUrl ?? '';
    String functionDate = function.functionDate;
    String functionTitle = function.title;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildFunctionBackgroundImage(imageUrl),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    functionTitle.toCapitalized(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          functionDate,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'englishFont',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            function.status,
                          ).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _getStatusText(function.status),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () {
                  _showFunctionSheet(function);
                },
                icon: const Icon(Icons.more_vert_outlined, color: Colors.white),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showFunctionSheet(function);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionBackgroundImage(String imageUrl) {
    String url = imageUrl;

    if (url.isNotEmpty && !url.startsWith('http')) {
      url = '$appImageUrl/$url';
    }

    if (url.isEmpty) {
      return Image.asset(AppImages.defaultImage, fit: BoxFit.cover);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(AppImages.defaultImage, fit: BoxFit.cover);
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.orange;
      default:
        return Colors.blue;
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
    showCustomActionSheet(
      context: context,
      title: languageProvider.tr('common.chooseAction'),
      titleColor: colorScheme.primary,
      actions: [
        ActionSheetItem(
          icon: Icons.visibility_outlined,
          title: languageProvider.tr('common.viewDetails'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            _viewFunction(function);
          },
        ),
        ActionSheetItem(
          icon: Icons.change_circle_outlined,
          title: languageProvider.tr('upcomingFunctions.changeStatus'),
          color: Colors.orange,
          onPressed: (context) async {
            Navigator.pop(context);
            _showStatusChangeDialog(function);
          },
        ),
        ActionSheetItem(
          icon: Icons.edit_outlined,
          title: languageProvider.tr('common.edit'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            _editFunction(function);
          },
        ),
        ActionSheetItem(
          icon: Icons.delete_outlined,
          title: languageProvider.tr('common.delete'),
          color: Colors.redAccent,
          onPressed: (context) async {
            Navigator.pop(context);
            _confirmDelete(function, searchHistory.indexOf(function));
          },
        ),
        ActionSheetItem(
          icon: Icons.cancel_outlined,
          title: languageProvider.tr('common.cancel'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Future<void> _showStatusChangeDialog(UpcomingFunction function) async {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          languageProvider.tr('upcomingFunctions.changeStatus'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(
              'ACTIVE',
              languageProvider.tr('upcomingFunctions.active'),
              Colors.green,
              function,
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              'CANCELLED',
              languageProvider.tr('upcomingFunctions.cancelled'),
              Colors.red,
              function,
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              'COMPLETED',
              languageProvider.tr('upcomingFunctions.completed'),
              Colors.orange,
              function,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              languageProvider.tr('common.cancel'),
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    String statusCode,
    String statusText,
    Color color,
    UpcomingFunction function,
  ) {
    final isSelected = function.status == statusCode;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _updateFunctionStatus(function, statusCode);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check_outlined, color: color, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateFunctionStatus(
    UpcomingFunction function,
    String newStatus,
  ) async {
    if (!mounted) return;

    try {
      final response = await services.updateStatus(function.id, newStatus);

      if (response != null && response['responseType'] == 'S') {
        // Update local list
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
          alertServices.successToast('நிலை வெற்றிகரமாக மாற்றப்பட்டது');
        }
      }
    } catch (e) {
      if (mounted) {
        alertServices.errorToast('நிலை மாற்ற முடியவில்லை');
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

  void _editFunction(UpcomingFunction function) {
    Navigator.pushNamed(
      context,
      "add-edit-upcoming-function",
      arguments: function,
    ).then((result) {
      if (result == true) {
        getUpcomingFunctions();
      }
    });
  }

  void _confirmDelete(UpcomingFunction function, int index) {
    alertServices
        .confirmAlert(
          context,
          context.read<LanguageProvider>().tr(
            'upcomingFunctions.deleteConfirmation',
          ),
        )
        .then((confirmDelete) {
          if (confirmDelete == true) {
            _deleteFunction(function, index);
          }
        });
  }

  Future<void> _deleteFunction(UpcomingFunction function, int index) async {
    try {
      final response = await services.deleteUpcomingFunction(function.id);
      if (response != null && response['responseType'] == 'S') {
        setState(() {
          searchHistory.removeAt(index);
          upcomingFunctionList.removeWhere((item) => item.id == function.id);
        });

        final successMessage =
            response['responseValue']?['message']?.toString() ??
            'விழா நீக்கப்பட்டது';
        alertServices.successToast(successMessage);
      } else {
        final errorMessage =
            response?['responseValue']?['message']?.toString() ??
            'விழாவை நீக்க முடியவில்லை';
        alertServices.errorToast(errorMessage);
      }
    } catch (e) {
      alertServices.errorToast('பிழை ஏற்பட்டது');
    }
  }
}
