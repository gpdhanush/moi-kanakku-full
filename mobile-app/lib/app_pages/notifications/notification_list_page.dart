import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/app_logs.dart';
import 'package:moi/app_services/notification_services.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final NotificationServices _notificationServices = NotificationServices();
  final AlertServices _alertServices = AlertServices();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final languageProvider = context.watch<LanguageProvider>();
    final localUnread = _notifications.where((n) => !n.isRead).length;
    final unreadCount = localUnread > 0 ? localUnread : _unreadCount;
    final title = unreadCount > 0
        ? '${languageProvider.tr('notifications.title').toUpperCase()} ($unreadCount)'
        : languageProvider.tr('notifications.title').toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _NotificationsAppHeader(
        title: title,
        onBack: () => Navigator.pop(context),
        onMarkAllRead: (_notifications.isNotEmpty && unreadCount > 0)
            ? _markAllAsRead
            : null,
        markAllTooltip: languageProvider.tr('notifications.markAllRead'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : _notifications.isEmpty
          ? CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: MoiEmptyState(
                    title: languageProvider.tr('notifications.emptyTitle'),
                    subtitle:
                        languageProvider.tr('notifications.emptyMessage'),
                    icon: HugeIcons.strokeRoundedNotification03,
                    accentColor: primary,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              itemCount: _notifications.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                return _buildDismissibleNotificationCard(
                  _notifications[index],
                  primary,
                  index,
                );
              },
            ),
    );
  }

  Widget _buildDismissibleNotificationCard(
    NotificationItem notification,
    Color primary,
    int index,
  ) {
    final languageProvider = context.read<LanguageProvider>();
    final accent = _getNotificationColor(notification.type, primary);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.moiGiven,
          borderRadius: AppRadius.mdAll,
        ),
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          color: Colors.white,
          size: 24,
          strokeWidth: 1.9,
        ),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showMoiConfirmSheet(
          context: context,
          title: languageProvider.tr('notifications.deleteTitle'),
          message: languageProvider.tr('notifications.deleteMessage'),
          confirmLabel: languageProvider.tr('common.delete'),
          cancelLabel: languageProvider.tr('common.cancel'),
          icon: HugeIcons.strokeRoundedDelete02,
          isDestructive: true,
        );
        return confirmed == true;
      },
      onDismissed: (direction) {
        _deleteNotification(notification, index);
      },
      child: _NotificationCard(
        notification: notification,
        accent: accent,
        icon: _getNotificationIcon(notification.type),
        timeAgo: _getTimeAgo(notification.time),
        onTap: () => _showNotificationDetailSheet(notification, accent),
        onDelete: () => _confirmAndDelete(notification, index),
      ),
    );
  }

  Future<void> _confirmAndDelete(
    NotificationItem notification,
    int index,
  ) async {
    final languageProvider = context.read<LanguageProvider>();
    final confirmed = await showMoiConfirmSheet(
      context: context,
      title: languageProvider.tr('notifications.deleteTitle'),
      message: languageProvider.tr('notifications.deleteMessage'),
      confirmLabel: languageProvider.tr('common.delete'),
      cancelLabel: languageProvider.tr('common.cancel'),
      icon: HugeIcons.strokeRoundedDelete02,
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      final currentIndex = _notifications.indexWhere(
        (n) => n.id == notification.id,
      );
      if (currentIndex != -1) {
        await _deleteNotification(notification, currentIndex);
      }
    }
  }

  Future<void> _showNotificationDetailSheet(
    NotificationItem notification,
    Color accent,
  ) async {
    final languageProvider = context.read<LanguageProvider>();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.78;
        final isUnread = !notification.isRead;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 8),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.of(sheetContext).surfaceElevated,
              borderRadius: AppRadius.xlAll,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.of(sheetContext).border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: HugeIcon(
                            icon: _getNotificationIcon(notification.type),
                            color: accent,
                            size: 22,
                            strokeWidth: 1.8,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isUnread)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    languageProvider.tr(
                                      'notifications.unreadBadge',
                                    ),
                                    textAlign: TextAlign.left,
                                    style: AppTypography.body.copyWith(
                                      color: accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              Text(
                                _getTimeAgo(notification.time),
                                textAlign: TextAlign.left,
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                textAlign: TextAlign.left,
                                style: AppTypography.sectionTitle.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  height: 1.35,
                                ),
                              ),
                              if (notification.body.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  notification.body,
                                  textAlign: TextAlign.left,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (isUnread) ...[
                          Tooltip(
                            message: languageProvider.tr(
                              'notifications.markAsRead',
                            ),
                            child: Material(
                              color: accent,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              elevation: 0,
                              child: InkWell(
                                onTap: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _markAsRead(notification);
                                },
                                customBorder: const CircleBorder(),
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Center(
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedTick02,
                                      color: Colors.white,
                                      size: 20,
                                      strokeWidth: 1.9,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Material(
                            color: const Color(0xffF4F4F5),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => Navigator.of(sheetContext).pop(),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: Text(
                                    languageProvider.tr('common.cancel'),
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getNotificationColor(NotificationType type, Color primary) {
    switch (type) {
      case NotificationType.moi:
        return AppColors.moiReceived;
      case NotificationType.moiOut:
        return AppColors.moiGiven;
      case NotificationType.function:
        return const Color(0xff7C3AED);
      case NotificationType.account:
        return const Color(0xff0284C7);
      case NotificationType.settings:
        return AppColors.accentAmber;
      case NotificationType.general:
        return primary;
    }
  }

  List<List<dynamic>> _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.moi:
        return HugeIcons.strokeRoundedArrowDown01;
      case NotificationType.moiOut:
        return HugeIcons.strokeRoundedArrowUp01;
      case NotificationType.function:
        return HugeIcons.strokeRoundedWedding;
      case NotificationType.account:
        return HugeIcons.strokeRoundedUser;
      case NotificationType.settings:
        return HugeIcons.strokeRoundedSettings01;
      case NotificationType.general:
        return HugeIcons.strokeRoundedNotification03;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final languageProvider = context.read<LanguageProvider>();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return languageProvider.tr('notifications.justNow');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${languageProvider.tr('notifications.minutesAgo')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${languageProvider.tr('notifications.hoursAgo')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${languageProvider.tr('notifications.daysAgo')}';
    } else {
      try {
        return DateFormat(
          'dd MMM yyyy',
          languageProvider.currentLanguage,
        ).format(dateTime);
      } catch (_) {
        return DateFormat('dd MMM yyyy').format(dateTime);
      }
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);

    try {
      final response = await _notificationServices.getNotificationList(
        '1',
        showLoading: false,
      );

      if (response != null &&
          response['responseType'] == 'S' &&
          response['responseValue'] != null) {
        final List<dynamic> notificationsData = response['responseValue'];
        final List<NotificationItem> notifications = notificationsData
            .map((item) => _mapToNotificationItem(item))
            .toList();

        if (mounted) {
          setState(() {
            _notifications = notifications;
            _unreadCount = notifications.where((n) => !n.isRead).length;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _notifications = [];
          _unreadCount = 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await _notificationServices.getUnreadCount();
      if (response != null &&
          response['responseType'] == 'S' &&
          response['responseValue'] != null &&
          mounted) {
        final value = response['responseValue'];
        final raw = value is Map
            ? (value['count'] ?? value['unreadCount'])
            : value;
        final parsed = int.tryParse(raw?.toString() ?? '') ?? 0;
        setState(() {
          // Prefer local unread when list already loaded with unread items.
          final localUnread =
              _notifications.where((n) => !n.isRead).length;
          _unreadCount = localUnread > 0 ? localUnread : parsed;
        });
      }
    } catch (e) {
      printContent('Error fetching unread count: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final languageProvider = context.read<LanguageProvider>();
    try {
      final response = await _notificationServices.markAllAsRead();
      if (response != null && response['responseType'] == 'S') {
        setState(() {
          _notifications = _notifications.map((notif) {
            return NotificationItem(
              id: notif.id,
              title: notif.title,
              body: notif.body,
              time: notif.time,
              isRead: true,
              type: notif.type,
            );
          }).toList();
          _unreadCount = 0;
        });

        if (mounted) {
          _alertServices.successToast(
            languageProvider.tr('notifications.markedAllRead'),
          );
        }
      }
    } catch (e) {
      printContent('Error marking all as read: $e');
      if (mounted) {
        _alertServices.errorToast(
          languageProvider.tr('notifications.markAllReadError'),
        );
      }
    }
  }

  Future<void> _deleteNotification(
    NotificationItem notification,
    int index,
  ) async {
    final languageProvider = context.read<LanguageProvider>();
    final deletedNotification = notification;
    setState(() {
      _notifications.removeAt(index);
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      }
    });

    try {
      final response = await _notificationServices.deleteNotification(
        notification.id,
      );

      if (response != null && response['responseType'] == 'S') {
        if (mounted) {
          _alertServices.successToast(
            languageProvider.tr('notifications.deleted'),
          );
        }
      } else {
        setState(() {
          final insertAt = index.clamp(0, _notifications.length);
          _notifications.insert(insertAt, deletedNotification);
          if (!notification.isRead) {
            _unreadCount++;
          }
        });
        if (mounted) {
          _alertServices.errorToast(
            languageProvider.tr('notifications.deleteError'),
          );
        }
      }
    } catch (e) {
      printContent('Error deleting notification: $e');
      setState(() {
        final insertAt = index.clamp(0, _notifications.length);
        _notifications.insert(insertAt, deletedNotification);
        if (!notification.isRead) {
          _unreadCount++;
        }
      });
      if (mounted) {
        _alertServices.errorToast(languageProvider.tr('common.error'));
      }
    }
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (notification.isRead) return;

    try {
      final response = await _notificationServices.markAsRead(notification.id);

      if (response != null && response['responseType'] == 'S') {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n.id == notification.id,
          );
          if (index != -1) {
            _notifications[index] = NotificationItem(
              id: notification.id,
              title: notification.title,
              body: notification.body,
              time: notification.time,
              isRead: true,
              type: notification.type,
            );
            _unreadCount = (_unreadCount - 1).clamp(0, 999);
          }
        });
      }
    } catch (e) {
      printContent('Error marking notification as read: $e');
    }
  }

  NotificationItem _mapToNotificationItem(Map<String, dynamic> data) {
    NotificationType type;
    final typeString = data['type']?.toString().toLowerCase() ?? 'general';
    switch (typeString) {
      case 'moi':
        type = NotificationType.moi;
        break;
      case 'moiout':
        type = NotificationType.moiOut;
        break;
      case 'function':
        type = NotificationType.function;
        break;
      case 'account':
        type = NotificationType.account;
        break;
      case 'settings':
        type = NotificationType.settings;
        break;
      default:
        type = NotificationType.general;
    }

    DateTime time;
    try {
      time = DateTime.parse(
        data['createdAt'] ?? DateTime.now().toIso8601String(),
      );
    } catch (_) {
      time = DateTime.now();
    }

    return NotificationItem(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      time: time,
      isRead: _parseIsRead(data),
      type: type,
    );
  }

  bool _parseIsRead(Map<String, dynamic> data) {
    final raw = data['isRead'] ?? data['is_read'] ?? data['read'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final text = raw?.toString().toLowerCase().trim();
    if (text == null || text.isEmpty) return false;
    return text == 'true' || text == '1' || text == 'yes';
  }
}

class _NotificationsAppHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onMarkAllRead;
  final String markAllTooltip;

  const _NotificationsAppHeader({
    required this.title,
    required this.onBack,
    required this.onMarkAllRead,
    required this.markAllTooltip,
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
              AppColors.deepenAccent(primary, amount: 0.35),
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
      leading: Padding(
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
      ),
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
      actions: [
        if (onMarkAllRead != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Material(
                color: Colors.white.withValues(alpha: 0.14),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onMarkAllRead,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Tooltip(
                      message: markAllTooltip,
                      child: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedTickDouble02,
                          color: Colors.white,
                          size: 20,
                          strokeWidth: 1.9,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 54),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final Color accent;
  final List<List<dynamic>> icon;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.accent,
    required this.icon,
    required this.timeAgo,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        splashColor: accent.withValues(alpha: 0.06),
        highlightColor: accent.withValues(alpha: 0.03),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            color: isUnread
                ? accent.withValues(alpha: 0.10)
                : colors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: isUnread
                  ? accent.withValues(alpha: 0.28)
                  : colors.border,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: icon,
                  color: accent,
                  size: 18,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.label.copyWith(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          size: 12,
                          strokeWidth: 1.8,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            timeAgo,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: AppColors.moiGivenSoft,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onDelete,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        color: AppColors.moiGiven,
                        size: 16,
                        strokeWidth: 1.9,
                      ),
                    ),
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

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.type,
  });
}

enum NotificationType { moi, moiOut, function, account, settings, general }
