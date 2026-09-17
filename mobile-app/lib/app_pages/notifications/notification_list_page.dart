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
    final title = _unreadCount > 0
        ? '${languageProvider.tr('notifications.title').toUpperCase()} ($_unreadCount)'
        : languageProvider.tr('notifications.title').toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _NotificationsAppHeader(
        title: title,
        onBack: () => Navigator.pop(context),
        onMarkAllRead: (_notifications.isNotEmpty && _unreadCount > 0)
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MoiEmptyState(
                        title: languageProvider.tr('notifications.emptyTitle'),
                        subtitle:
                            languageProvider.tr('notifications.emptyMessage'),
                        icon: HugeIcons.strokeRoundedNotification03,
                        accentColor: primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.page,
                        ),
                        child: SizedBox(
                          width: 180,
                          child: _SoftActionButton(
                            label: languageProvider.tr('common.tryAgain'),
                            onTap: _refreshNotifications,
                          ),
                        ),
                      ),
                    ],
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

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.moiGiven,
          borderRadius: BorderRadius.circular(16),
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
        accent: _getNotificationColor(notification.type, primary),
        icon: _getNotificationIcon(notification.type),
        timeAgo: _getTimeAgo(notification.time),
        onTap: () => _toggleNotificationReadStatus(notification),
      ),
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
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _notifications = [];
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

  Future<void> _refreshNotifications() async {
    await _fetchNotifications();
    await _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await _notificationServices.getUnreadCount();
      if (response != null &&
          response['responseType'] == 'S' &&
          response['responseValue'] != null &&
          mounted) {
        setState(() {
          _unreadCount = response['responseValue']['count'] ?? 0;
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageProvider.tr('notifications.deleted'),
                style: AppTypography.body.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.moiReceived,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: languageProvider.tr('notifications.restore'),
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _notifications.insert(index, deletedNotification);
                    if (!deletedNotification.isRead) {
                      _unreadCount++;
                    }
                  });
                },
              ),
            ),
          );
        }
      } else {
        setState(() {
          _notifications.insert(index, deletedNotification);
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
        _notifications.insert(index, deletedNotification);
        if (!notification.isRead) {
          _unreadCount++;
        }
      });
      if (mounted) {
        _alertServices.errorToast(languageProvider.tr('common.error'));
      }
    }
  }

  Future<void> _toggleNotificationReadStatus(
    NotificationItem notification,
  ) async {
    try {
      final response = notification.isRead
          ? await _notificationServices.markAsUnread(notification.id)
          : await _notificationServices.markAsRead(notification.id);

      if (response != null && response['responseType'] == 'S') {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n.id == notification.id,
          );
          if (index != -1) {
            final wasRead = notification.isRead;
            _notifications[index] = NotificationItem(
              id: notification.id,
              title: notification.title,
              body: notification.body,
              time: notification.time,
              isRead: !notification.isRead,
              type: notification.type,
            );

            if (wasRead) {
              _unreadCount++;
            } else {
              _unreadCount = (_unreadCount - 1).clamp(0, 999);
            }
          }
        });
      }
    } catch (e) {
      printContent('Error toggling notification status: $e');
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
      isRead: data['isRead'] ?? false,
      type: type,
    );
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

  const _NotificationCard({
    required this.notification,
    required this.accent,
    required this.icon,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withValues(alpha: 0.06),
        highlightColor: accent.withValues(alpha: 0.03),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? accent.withValues(alpha: 0.28)
                  : const Color(0xffE4E4E7),
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.label.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          size: 13,
                          strokeWidth: 1.8,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          timeAgo,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SoftActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                AppColors.deepenAccent(primary, amount: 0.28),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.24),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
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
