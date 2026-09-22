import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_configs/startup_timing.dart';
import 'package:moi/app_services/feedback_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class Feedbacks extends StatefulWidget {
  final bool embeddedInShell;

  const Feedbacks({super.key, this.embeddedInShell = false});

  @override
  State<Feedbacks> createState() => _FeedbacksState();
}

class _FeedbacksState extends State<Feedbacks> {
  final AlertServices _alertServices = AlertServices();
  final FeedbackServices _feedbackServices = FeedbackServices();
  final SecureStorageService _storage = SecureStorageService();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _previousFeedbacks = [];
  bool _isLoading = false;
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    StartupTiming.log('Feedbacks.initState');
    _loadPreviousFeedbacks();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviousFeedbacks({bool showLoading = true}) async {
    await StartupTiming.timeAsync('Feedbacks.loadPrevious', () async {
      if (showLoading && mounted) {
        setState(() => _isLoading = true);
      }

      try {
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

        if (mounted) {
          setState(() {
            _profileImageUrl = _resolveProfileImageUrl(userData);
          });
        }

        final userId = userData['id'].toString();
        final response = await _feedbackServices.getFeedbacksList({
          'userId': userId,
        }, showLoading: false);

        if (response != null) {
          List<dynamic> feedbacksList = [];

          if (response is List) {
            feedbacksList = response;
          } else if (response is Map) {
            if (response['responseValue'] != null &&
                response['responseValue'] is List) {
              feedbacksList = response['responseValue'];
            } else if (response['data'] != null && response['data'] is List) {
              feedbacksList = response['data'];
            } else if (response['count'] != null &&
                response['responseValue'] != null) {
              feedbacksList = response['responseValue'] is List
                  ? response['responseValue']
                  : [];
            }
          }

          final List<dynamic> feedbacks = feedbacksList.where((item) {
            final active = item['active']?.toString().toUpperCase();
            return active == null || active.isEmpty || active == 'Y';
          }).toList();

          feedbacks.sort((a, b) {
            final dateA = a['createdAt']?.toString() ?? '';
            final dateB = b['createdAt']?.toString() ?? '';
            if (dateA.isEmpty || dateB.isEmpty) return 0;
            try {
              return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
            } catch (_) {
              return 0;
            }
          });

          if (mounted) {
            setState(() {
              _previousFeedbacks = feedbacks;
              _isLoading = false;
            });
          }
        } else if (mounted) {
          setState(() {
            _previousFeedbacks = [];
            _isLoading = false;
          });
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
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final primary = Theme.of(context).colorScheme.primary;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: MoiAppHeader(
            title: languageProvider.tr('feedback.title'),
            showBack: !widget.embeddedInShell,
            onBack: () => Navigator.pop(context),
          ),
          body: MoiRefreshIndicator(
            onRefresh: () => _loadPreviousFeedbacks(showLoading: false),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildComposerCard(languageProvider, primary),
                  const SizedBox(height: AppSpacing.lg),
                  MoiInfoSectionLabel(
                    title: languageProvider.tr('feedback.previousFeedback'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPreviousList(languageProvider, primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposerCard(LanguageProvider languageProvider, Color primary) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormWidget(
              title: languageProvider.tr('feedback.feedback'),
              required: true,
              controller: _feedbackController,
              maxLines: 8,
              minLines: 5,
              enableMic: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return languageProvider.tr('feedback.required');
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              title: languageProvider.tr('common.save'),
              onPressed: _onSavePressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousList(LanguageProvider languageProvider, Color primary) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            for (int i = 0; i < 12; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.of(context).border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(width: 160, height: 12, radius: 8),
                    const SizedBox(height: 12),
                    AppSkeleton(width: double.infinity, height: 62, radius: 12),
                    const SizedBox(height: 12),
                    AppSkeleton(width: 110, height: 11, radius: 8),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_previousFeedbacks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.of(context).border),
          boxShadow: AppShadows.soft,
        ),
        child: MoiEmptyState(
          title: languageProvider.tr('feedback.empty'),
          subtitle: languageProvider.tr('feedback.emptyHint'),
          imagePath: 'assets/images/empty-state/feedback.png',
          accentColor: primary,
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _previousFeedbacks.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == _previousFeedbacks.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: _FeedbackCard(
              feedback: _previousFeedbacks[i],
              primary: primary,
              languageProvider: languageProvider,
              formatDate: _formatDate,
              profileImageUrl: _profileImageUrl,
            ),
          ),
      ],
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty || dateString.trim().isEmpty) return '';

    try {
      DateTime date = DateTime.parse(dateString.trim()).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      final difference = today.difference(dateOnly).inDays;
      final lp = context.read<LanguageProvider>();

      if (difference == 0) return lp.tr('feedback.today');
      if (difference == 1) return lp.tr('feedback.yesterday');
      if (difference > 1 && difference <= 5) {
        return '$difference ${lp.tr('feedback.daysAgo')}';
      }
      return DateFormat('dd-MMM-yyyy hh:mm a', 'en').format(date);
    } catch (_) {
      return dateString
          .replaceAll('T', ' ')
          .replaceAll('.000Z', '')
          .replaceAll('Z', '')
          .replaceAll('.000', '');
    }
  }

  String _resolveProfileImageUrl(Map<String, dynamic> user) {
    final imagePath = (user['profile_image_url'] ?? user['profile_image'])
        ?.toString()
        .trim();
    if (imagePath == null ||
        imagePath.isEmpty ||
        imagePath.toLowerCase() == 'null' ||
        imagePath.toLowerCase() == 'undefined') {
      return '';
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    final normalized = imagePath.replaceFirst(RegExp(r'^/+'), '');
    if (appImageUrl.trim().isNotEmpty) {
      return '$appImageUrl/$normalized';
    }
    final apiBase = bootstrapApiBaseUri.trim();
    final baseWithoutApis = apiBase.endsWith('/apis')
        ? apiBase.replaceFirst(RegExp(r'/apis$'), '')
        : apiBase;
    return '$baseWithoutApis/$normalized';
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      FocusScope.of(context).unfocus();
      _saveFeedback();
    }
  }

  Future<void> _saveFeedback() async {
    try {
      final feedbackText = _feedbackController.text.trim();
      final userData = await _storage.get(AppVariables.userInformation);
      if (userData == null || userData['id'] == null) {
        _alertServices.errorToast(
          context.read<LanguageProvider>().tr('feedback.userInfoMissing'),
        );
        return;
      }

      final response = await _feedbackServices.saveFeedbacks({
        'userId': userData['id'].toString(),
        'feedbacks': feedbackText,
      });

      if (!mounted) return;

      if (response != null && response['responseType'] == 'S') {
        final message =
            response['responseValue']?['message']?.toString() ??
            context.read<LanguageProvider>().tr('feedback.saved');
        _alertServices.successToast(message);

        FocusScope.of(context).unfocus();
        _feedbackController.clear();
        setState(() => _formKey = GlobalKey<FormState>());

        await _loadPreviousFeedbacks();

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
        final errorMessage =
            response?['responseValue']?['message']?.toString() ??
            context.read<LanguageProvider>().tr('feedback.saveFailed');
        _alertServices.errorToast(errorMessage);
      }
    } catch (_) {
      if (mounted) {
        _alertServices.errorToast(
          context.read<LanguageProvider>().tr('feedback.saveFailed'),
        );
      }
    }
  }
}

class _FeedbackCard extends StatelessWidget {
  final dynamic feedback;
  final Color primary;
  final LanguageProvider languageProvider;
  final String Function(String) formatDate;
  final String profileImageUrl;

  const _FeedbackCard({
    required this.feedback,
    required this.primary,
    required this.languageProvider,
    required this.formatDate,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final feedbackText =
        feedback['message']?.toString() ??
        feedback['feedbacks']?.toString() ??
        '';
    final replyText =
        feedback['adminResponse']?.toString() ??
        feedback['reply']?.toString() ??
        '';
    final feedbackStatus = (feedback['status']?.toString() ?? 'OPEN')
        .toUpperCase();
    final hasReply = replyText.trim().isNotEmpty;
    final isClosed = feedbackStatus == 'CLOSED' || feedbackStatus == 'RESOLVED';
    final createdAt = formatDate(
      feedback['createdAt']?.toString() ?? '',
    ).toTitleCase();
    final repliedAt = hasReply
        ? formatDate(
            feedback['respondedAt']?.toString() ??
                feedback['repliedAt']?.toString() ??
                '',
          ).toTitleCase()
        : '';
    final cardColors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusLabel = isClosed
        ? languageProvider.tr('feedback.closed')
        : feedbackStatus == 'PENDING'
        ? languageProvider.tr('feedback.pending')
        : languageProvider.tr('feedback.open');
    final statusColor = isClosed
        ? const Color(0xFF2E7D32)
        : feedbackStatus == 'PENDING'
        ? primary
        : const Color(0xFFE65100);
    final statusBg = isClosed
        ? const Color(0xFFE8F5E9)
        : feedbackStatus == 'PENDING'
        ? primary.withValues(alpha: 0.10)
        : const Color(0xFFFFF3E0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: hasReply
              ? const Color(0xFF2E7D32).withValues(alpha: 0.18)
              : cardColors.border.withValues(alpha: 0.72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: profileImageUrl.isEmpty
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedUser,
                              color: primary,
                              size: 18,
                              strokeWidth: 1.8,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: MoiNetworkImage(
                                url: profileImageUrl,
                                width: 38,
                                height: 38,
                                errorBuilder: (_, _, _) => HugeIcon(
                                  icon: HugeIcons.strokeRoundedUser,
                                  color: primary,
                                  size: 18,
                                  strokeWidth: 1.8,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.tr('feedback.yourFeedback'),
                            style: AppTypography.label.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            createdAt.isNotEmpty
                                ? createdAt
                                : languageProvider.tr('feedback.unknownDate'),
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.transparent : statusBg,
                        borderRadius: BorderRadius.circular(20),
                        border: isDark
                            ? Border.all(color: statusColor, width: 1)
                            : null,
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTypography.label.copyWith(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    feedbackText.toTitleCase(),
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasReply)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurfaceVariant.withValues(alpha: 0.88)
                    : const Color(0xFFE8F5E9).withValues(alpha: 0.55),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : const Color(0xFF2E7D32).withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkSuccess.withValues(alpha: 0.18)
                              : const Color(0xFF2E7D32).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/admin.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageProvider.tr('feedback.reply'),
                              style: AppTypography.label.copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkSuccess
                                    : const Color(0xFF2E7D32),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              repliedAt.isNotEmpty
                                  ? repliedAt
                                  : languageProvider.tr('feedback.unknownDate'),
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkSuccess.withValues(alpha: 0.16)
                              : const Color(0xFF2E7D32).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          languageProvider.tr('feedback.admin'),
                          style: AppTypography.label.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextPrimary
                                : const Color(0xFF1B5E20),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkBorder
                            : const Color(0xFF2E7D32).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      replyText,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF332B1E).withValues(alpha: 0.9)
                    : const Color(0xFFFFF8E1).withValues(alpha: 0.7),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkWarning.withValues(alpha: 0.3)
                        : const Color(0xFFE65100).withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkWarning.withValues(alpha: 0.14)
                          : const Color(0xFFFFE0B2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedClock01,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkWarning
                          : const Color(0xFFE65100),
                      size: 16,
                      strokeWidth: 1.8,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.tr('feedback.replyPending'),
                          style: AppTypography.label.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkWarning
                                : const Color(0xFFE65100),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          languageProvider.tr('feedback.replySoon'),
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
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
}
