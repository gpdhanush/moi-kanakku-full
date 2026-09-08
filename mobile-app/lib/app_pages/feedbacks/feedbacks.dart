import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_services/feedback_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class Feedbacks extends StatefulWidget {
  const Feedbacks({super.key});

  @override
  State<Feedbacks> createState() => _FeedbacksState();
}

class _FeedbacksState extends State<Feedbacks> {
  // Initialize services and controllers
  final AlertServices _alertServices = AlertServices();
  final FeedbackServices _feedbackServices = FeedbackServices();
  final SecureStorageService _storage = SecureStorageService();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _previousFeedbacks = [];
  bool _isLoading = false;
  // bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousFeedbacks();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load previous feedbacks from API
  Future<void> _loadPreviousFeedbacks() async {
    setState(() => _isLoading = true);

    try {
      // Get user ID from secure storage
      final userData = await _storage.get(AppVariables.userInformation);
      if (userData == null || userData['id'] == null) {
        if (mounted) {
          setState(() {
            _previousFeedbacks = [];
            _isLoading = false;
          });
        }
        return;
      }

      final userId = userData['id'].toString();

      // Prepare request params
      final params = {'userId': userId};

      // Call API with POST method (page has its own spinner)
      final response = await _feedbackServices.getFeedbacksList(
        params,
        showLoading: false,
      );

      if (response != null) {
        List<dynamic> feedbacksList = [];

        // Handle different response formats
        if (response is List) {
          // Direct list response
          feedbacksList = response;
          debugPrint(
            'Feedbacks: Direct list response with ${feedbacksList.length} items',
          );
        } else if (response is Map) {
          // Wrapped response (like notifications)
          if (response['responseValue'] != null &&
              response['responseValue'] is List) {
            feedbacksList = response['responseValue'];
            debugPrint(
              'Feedbacks: Wrapped in responseValue with ${feedbacksList.length} items',
            );
          } else if (response['data'] != null && response['data'] is List) {
            feedbacksList = response['data'];
            debugPrint(
              'Feedbacks: Wrapped in data with ${feedbacksList.length} items',
            );
          } else if (response['count'] != null &&
              response['responseValue'] != null) {
            // Handle response with count field
            feedbacksList = response['responseValue'] is List
                ? response['responseValue']
                : [];
            debugPrint(
              'Feedbacks: Response with count field, ${feedbacksList.length} items',
            );
          } else {
            debugPrint(
              'Feedbacks: Unknown response format: ${response.runtimeType}',
            );
          }
        } else {
          debugPrint(
            'Feedbacks: Response is not List or Map: ${response.runtimeType}',
          );
        }

        // Filter only active feedbacks (include all if active is null/empty or 'Y')
        final List<dynamic> feedbacks = feedbacksList.where((item) {
          final active = item['active']?.toString().toUpperCase();
          // Include if active is 'Y', null, empty, or doesn't exist
          return active == null || active.isEmpty || active == 'Y';
        }).toList();

        debugPrint('Feedbacks after filtering: ${feedbacks.length} items');
        debugPrint('Setting _previousFeedbacks to ${feedbacks.length} items');

        // Sort by createdAt descending (newest first)
        feedbacks.sort((a, b) {
          final dateA = a['createdAt']?.toString() ?? '';
          final dateB = b['createdAt']?.toString() ?? '';
          if (dateA.isEmpty || dateB.isEmpty) return 0;
          try {
            final dateTimeA = DateTime.parse(dateA);
            final dateTimeB = DateTime.parse(dateB);
            return dateTimeB.compareTo(dateTimeA);
          } catch (e) {
            return 0;
          }
        });

        if (mounted) {
          setState(() {
            _previousFeedbacks = feedbacks;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _previousFeedbacks = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading feedbacks: $e');
      if (mounted) {
        setState(() {
          _previousFeedbacks = [];
          _isLoading = false;
        });
      }
    }
  }

  /// Get color for feedback type badge
  // MaterialColor _getTypeColor(String type) {
  //   switch (type.toUpperCase()) {
  //     case 'COMPLAINT':
  //       return Colors.red;
  //     case 'SUGGESTION':
  //       return Colors.blue;
  //     case 'GENERAL':
  //       return Colors.indigo;
  //     case 'PRAISE':
  //       return Colors.green;
  //     default:
  //       return Colors.grey;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBarWidget(
        title: context.read<LanguageProvider>().tr('feedback.title'),
        action: [],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPreviousFeedbacks,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // New Feedback Section
              _buildNewFeedbackSection(colorScheme),
              const SizedBox(height: 24),
              // Previous Feedbacks Section
              _buildPreviousFeedbacksSection(colorScheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the new feedback submission section
  Widget _buildNewFeedbackSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.feedback_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.read<LanguageProvider>().tr('feedback.newFeedback'),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.read<LanguageProvider>().tr(
                      'feedback.shareFeedback',
                    ),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 25.0),
        // Form Section
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text Field
              TextFormWidget(
                title: context.read<LanguageProvider>().tr('feedback.feedback'),
                required: true,
                controller: _feedbackController,
                maxLines: 10,
                minLines: 6,
                enableMic: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return context.read<LanguageProvider>().tr(
                      'feedback.required',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Submit Button
              AppButton(
                title: context.read<LanguageProvider>().tr('common.save'),
                onPressed: _onSavePressed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build the previous feedbacks section
  Widget _buildPreviousFeedbacksSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_outlined, color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              context.read<LanguageProvider>().tr('feedback.previousFeedback'),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_previousFeedbacks.isEmpty)
          _buildEmptyState(colorScheme)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _previousFeedbacks.length,
            itemBuilder: (context, index) {
              return _buildFeedbackCard(
                colorScheme,
                _previousFeedbacks[index],
                index,
              );
            },
          ),
      ],
    );
  }

  /// Build empty state when no feedbacks exist
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.recent_actors_outlined,
            size: 64,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.read<LanguageProvider>().tr('feedback.empty'),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.read<LanguageProvider>().tr('feedback.emptyHint'),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual feedback card with reply
  Widget _buildFeedbackCard(
    ColorScheme colorScheme,
    dynamic feedback,
    int index,
  ) {
    final feedbackText =
        feedback['message']?.toString() ??
        feedback['feedbacks']?.toString() ??
        '';
    final replyText =
        feedback['adminResponse']?.toString() ??
        feedback['reply']?.toString() ??
        '';
    // final feedbackType = feedback['type']?.toString() ?? 'GENERAL';
    final feedbackStatus = (feedback['status']?.toString() ?? 'OPEN')
        .toUpperCase();

    // Show reply section if adminResponse is not empty
    final hasReply = replyText.isNotEmpty && replyText.trim().isNotEmpty;

    // Determine if feedback is closed/resolved
    final isClosed = feedbackStatus == 'CLOSED' || feedbackStatus == 'RESOLVED';

    // Debug log to check data
    debugPrint(
      'Feedback ${feedback['id']}: status=$feedbackStatus, adminResponse="$replyText", hasReply=$hasReply, isClosed=$isClosed',
    );

    final createdAt = _formatDate(
      feedback['createdAt']?.toString() ?? '',
    ).toTitleCase();
    final repliedAt = hasReply
        ? _formatDate(
            feedback['respondedAt']?.toString() ??
                feedback['repliedAt']?.toString() ??
                '',
          ).toTitleCase()
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasReply
              ? Colors.green.withValues(alpha: 0.3)
              : colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasReply ? Colors.green : colorScheme.primary).withValues(
              alpha: 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feedback Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.08),
                  colorScheme.primary.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.read<LanguageProvider>().tr(
                                        'feedback.yourFeedback',
                                      ),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Time moved here
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_outlined,
                                          size: 11,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          createdAt.isNotEmpty
                                              ? createdAt
                                              : context
                                                    .read<LanguageProvider>()
                                                    .tr('feedback.unknownDate'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                            fontFamily: 'amountFont',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              // // Type Badge
                              // Container(
                              //   padding: const EdgeInsets.symmetric(
                              //     horizontal: 7,
                              //     vertical: 3,
                              //   ),
                              //   decoration: BoxDecoration(
                              //     color: _getTypeColor(feedbackType)[100],
                              //     borderRadius: BorderRadius.circular(5),
                              //   ),
                              //   child: Text(
                              //     feedbackType.toCapitalized(),
                              //     style: TextStyle(
                              //       fontSize: 10,
                              //       fontWeight: FontWeight.w600,
                              //       color: _getTypeColor(feedbackType)[700],
                              //       fontFamily: 'amountFont',
                              //     ),
                              //   ),
                              // ),
                              // const SizedBox(width: 4),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isClosed
                                      ? Colors.green[100]
                                      : feedbackStatus == 'PENDING'
                                      ? Colors.blue[100]
                                      : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Icon(
                                    //   isClosed
                                    //       ? Icons.check_circle_outlined
                                    //       : feedbackStatus == 'PENDING'
                                    //       ? Icons.pending_outlined
                                    //       : Icons.mark_email_unread_outlined,
                                    //   size: 12,
                                    //   color: isClosed
                                    //       ? Colors.green[700]
                                    //       : feedbackStatus == 'PENDING'
                                    //       ? Colors.blue[700]
                                    //       : Colors.orange[700],
                                    // ),
                                    // const SizedBox(width: 3),
                                    Text(
                                      isClosed
                                          ? context.read<LanguageProvider>().tr(
                                              'feedback.closed',
                                            )
                                          : feedbackStatus == 'PENDING'
                                          ? context.read<LanguageProvider>().tr(
                                              'feedback.pending',
                                            )
                                          : context.read<LanguageProvider>().tr(
                                              'feedback.open',
                                            ),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: isClosed
                                            ? Colors.green[700]
                                            : feedbackStatus == 'PENDING'
                                            ? Colors.blue[700]
                                            : Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    feedbackText.toTitleCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Reply Section
          if (hasReply)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green[50]!,
                    Colors.green[50]!.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border(
                  top: BorderSide(color: Colors.green[200]!, width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[600]!, Colors.green[700]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.read<LanguageProvider>().tr(
                                          'feedback.reply',
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Time moved here
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_outlined,
                                            size: 11,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            repliedAt.isNotEmpty
                                                ? repliedAt
                                                : context
                                                      .read<LanguageProvider>()
                                                      .tr(
                                                        'feedback.unknownDate',
                                                      ),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              fontFamily: 'amountFont',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Admin Badge moved here
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    context.read<LanguageProvider>().tr(
                                      'feedback.admin',
                                    ),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green[200]!, width: 1),
                    ),
                    child: Text(
                      replyText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border(
                  top: BorderSide(color: Colors.orange[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.read<LanguageProvider>().tr(
                            'feedback.replyPending',
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.read<LanguageProvider>().tr(
                            'feedback.replySoon',
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(String dateString) {
    if (dateString.isEmpty || dateString.trim().isEmpty) {
      return '';
    }

    try {
      // Try to parse the date string directly
      DateTime date = DateTime.parse(dateString.trim());

      // Convert to local time
      date = date.toLocal();

      // Get current date and time
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);

      // Calculate difference in days
      final difference = today.difference(dateOnly).inDays;

      if (difference == 0) {
        // Today
        return context.read<LanguageProvider>().tr('feedback.today');
      } else if (difference == 1) {
        // Yesterday
        return context.read<LanguageProvider>().tr('feedback.yesterday');
      } else if (difference > 1 && difference <= 5) {
        // 2-5 days ago
        return '$difference ${context.read<LanguageProvider>().tr('feedback.daysAgo')}';
      } else {
        // After 5 days - show full date with time
        return DateFormat('dd-MMM-yyyy hh:mm:ss a', 'en').format(date);
      }
    } catch (e) {
      // If parsing fails completely, return a readable version of the original string
      String cleaned = dateString
          .replaceAll('T', ' ')
          .replaceAll('.000Z', '')
          .replaceAll('Z', '')
          .replaceAll('.000', '');
      return cleaned;
    }
  }

  // Handle save button press
  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      FocusScope.of(context).unfocus();
      _saveFeedback();
    }
  }

  /// SAVE THE USERS FEEDBACK
  Future<void> _saveFeedback() async {
    // setState(() => _isSubmitting = true);

    try {
      final feedbackText = _feedbackController.text.trim();

      // Get user ID from secure storage
      final userData = await _storage.get(AppVariables.userInformation);
      if (userData == null || userData['id'] == null) {
        _alertServices.errorToast(
          context.read<LanguageProvider>().tr('feedback.userInfoMissing'),
        );
        return;
      }

      final userId = userData['id'].toString();

      // Prepare request params
      final params = {'userId': userId, 'feedbacks': feedbackText};

      // Call API to save feedback
      final response = await _feedbackServices.saveFeedbacks(params);

      if (mounted) {
        if (response != null && response['responseType'] == 'S') {
          // Success - show message from API
          final message =
              response['responseValue']?['message']?.toString() ??
              context.read<LanguageProvider>().tr('feedback.saved');
          _alertServices.successToast(message);

          // Unfocus first to prevent validation trigger
          FocusScope.of(context).unfocus();

          // Clear the controller
          _feedbackController.clear();

          // Recreate form key to completely reset form state and clear validation errors
          setState(() {
            _formKey = GlobalKey<FormState>();
          });

          // Reload feedbacks list to show the new feedback
          await _loadPreviousFeedbacks();

          // Scroll to top to show new feedback
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          // Error response
          final errorMessage =
              response?['responseValue']?['message']?.toString() ??
              context.read<LanguageProvider>().tr('feedback.saveFailed');
          _alertServices.errorToast(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        _alertServices.errorToast(
          context.read<LanguageProvider>().tr('feedback.saveFailed'),
        );
      }
    } finally {
      if (mounted) {
        // setState(() => _isSubmitting = false);
      }
    }
  }
}
