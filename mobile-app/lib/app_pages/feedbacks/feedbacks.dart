import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/app_variables.dart';
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

  Future<void> _loadPreviousFeedbacks() async {
    setState(() => _isLoading = true);

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

      final userId = userData['id'].toString();
      final response = await _feedbackServices.getFeedbacksList(
        {'userId': userId},
        showLoading: false,
      );

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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final primary = Theme.of(context).colorScheme.primary;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _FeedbackAppHeader(
            title: languageProvider.tr('feedback.title').toUpperCase(),
            showBack: !widget.embeddedInShell,
            onBack: () => Navigator.pop(context),
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeedbackHero(
                  primary: primary,
                  title: languageProvider.tr('feedback.newFeedback'),
                  subtitle: languageProvider.tr('feedback.shareFeedback'),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildComposerCard(languageProvider, primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  languageProvider.tr('feedback.previousFeedback'),
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildPreviousList(languageProvider, primary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposerCard(LanguageProvider languageProvider, Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            _GradientActionButton(
              primary: primary,
              label: languageProvider.tr('common.save'),
              onTap: _onSavePressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousList(LanguageProvider languageProvider, Color primary) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: primary),
        ),
      );
    }

    if (_previousFeedbacks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.soft,
        ),
        child: MoiEmptyState(
          title: languageProvider.tr('feedback.empty'),
          subtitle: languageProvider.tr('feedback.emptyHint'),
          icon: HugeIcons.strokeRoundedComment01,
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

class _FeedbackAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  final bool showBack;

  const _FeedbackAppHeader({
    required this.title,
    required this.onBack,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              Color.lerp(primary, const Color(0xff0A3D8F), 0.35)!,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -28,
              right: -18,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -36,
              left: 48,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      leadingWidth: 54,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Center(
                child: Material(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onBack,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          color: Colors.white,
                          size: 22,
                          strokeWidth: 1.9,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(width: 54),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTypography.sectionTitle.copyWith(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      actions: const [SizedBox(width: 54)],
    );
  }
}

class _FeedbackHero extends StatelessWidget {
  final Color primary;
  final String title;
  final String subtitle;

  const _FeedbackHero({
    required this.primary,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final deep = Color.lerp(primary, const Color(0xff0A3D8F), 0.28)!;
    final soft = Color.lerp(primary, Colors.white, 0.22)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, soft, deep],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -16,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -24,
            bottom: -28,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedComment01,
                    color: Colors.white,
                    size: 24,
                    strokeWidth: 1.8,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.sectionTitle.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
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

class _FeedbackCard extends StatelessWidget {
  final dynamic feedback;
  final Color primary;
  final LanguageProvider languageProvider;
  final String Function(String) formatDate;

  const _FeedbackCard({
    required this.feedback,
    required this.primary,
    required this.languageProvider,
    required this.formatDate,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: hasReply
              ? const Color(0xFF2E7D32).withValues(alpha: 0.18)
              : const Color(0xffE4E4E7),
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
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedUser,
                        color: primary,
                        size: 18,
                        strokeWidth: 1.8,
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
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
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
                color: const Color(0xFFE8F5E9).withValues(alpha: 0.55),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
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
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCustomerService01,
                          color: Color(0xFF2E7D32),
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
                              languageProvider.tr('feedback.reply'),
                              style: AppTypography.label.copyWith(
                                color: const Color(0xFF2E7D32),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              repliedAt.isNotEmpty
                                  ? repliedAt
                                  : languageProvider.tr(
                                      'feedback.unknownDate',
                                    ),
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
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          languageProvider.tr('feedback.admin'),
                          style: AppTypography.label.copyWith(
                            color: const Color(0xFF1B5E20),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
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
                color: const Color(0xFFFFF8E1).withValues(alpha: 0.7),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE65100).withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0B2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedClock01,
                      color: Color(0xFFE65100),
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
                            color: const Color(0xFFE65100),
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

class _GradientActionButton extends StatelessWidget {
  final Color primary;
  final String label;
  final VoidCallback onTap;

  const _GradientActionButton({
    required this.primary,
    required this.label,
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
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                Color.lerp(primary, const Color(0xff0A3D8F), 0.28)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
