import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/app_logs.dart';
import 'package:moi/app_services/notification_services.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final NotificationServices _notificationServices = NotificationServices();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBarWidget(
        title: _unreadCount > 0
            ? '${languageProvider.tr('notifications.title')} ($_unreadCount)'
            : languageProvider.tr('notifications.title'),
        action: [
          if (_notifications.isNotEmpty && _unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_outlined),
              tooltip: languageProvider.tr('notifications.markAllRead'),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: _buildEmptyState(theme, colorScheme),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildDismissibleNotificationCard(
                    _notifications[index],
                    theme,
                    colorScheme,
                    index,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildDismissibleNotificationCard(
    NotificationItem notification,
    ThemeData theme,
    ColorScheme colorScheme,
    int index,
  ) {
    final languageProvider = context.read<LanguageProvider>();
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outlined, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                languageProvider.tr('notifications.deleteTitle'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                languageProvider.tr('notifications.deleteMessage'),
                style: TextStyle(fontFamily: 'appFontFamily'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    languageProvider.tr('common.cancel'),
                    style: TextStyle(fontFamily: 'appFontFamily'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    languageProvider.tr('common.delete'),
                    style: TextStyle(fontFamily: 'appFontFamily'),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _deleteNotification(notification, index);
      },
      child: _buildNotificationCard(notification, theme, colorScheme),
    );
  }

  Widget _buildNotificationCard(
    NotificationItem notification,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final timeAgo = _getTimeAgo(notification.time);
    final notifColor = _getNotificationColor(notification.type, colorScheme);
    final notifIcon = _getNotificationIcon(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            notifColor.withValues(alpha: 0.08),
            notifColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notifColor.withValues(alpha: notification.isRead ? 0.15 : 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: notifColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleNotificationReadStatus(notification),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: notifColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(notifIcon, color: notifColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[900],
                                  ),
                              // style: TextStyle(
                              //   fontSize: 14,
                              //   fontWeight: FontWeight.w700,
                              //   color: Colors.grey[900],
                              // ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: notifColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 11,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.normal,
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
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    final languageProvider = context.read<LanguageProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.15),
                    colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              languageProvider.tr('notifications.emptyTitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,

                fontSize: 18,
              ),

              // style: TextStyle(
              //
              //   fontSize: 22,
              // fontWeight: FontWeight.w800,
              // color: colorScheme.primary,
              //   letterSpacing: 0.5,
              // ),
            ),
            const SizedBox(height: 10),
            Text(
              languageProvider.tr('notifications.emptyMessage'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              // style: TextStyle(
              //
              //   fontSize: 14,
              //   height: 1.6,
              //   color: Colors.grey.shade600,
              // ),
            ),
            const SizedBox(height: 30),
            AppButton(
              title: languageProvider.tr('common.tryAgain'),
              onPressed: _refreshNotifications,
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type, ColorScheme colorScheme) {
    switch (type) {
      case NotificationType.moi:
        return Colors.green;
      case NotificationType.moiOut:
        return Colors.red;
      case NotificationType.function:
        return Colors.purple;
      case NotificationType.account:
        return Colors.blue;
      case NotificationType.settings:
        return Colors.orange;
      case NotificationType.general:
        return colorScheme.primary;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.moi:
        return Icons.arrow_downward_outlined;
      case NotificationType.moiOut:
        return Icons.arrow_upward_outlined;
      case NotificationType.function:
        return Icons.celebration_outlined;
      case NotificationType.account:
        return Icons.account_circle_outlined;
      case NotificationType.settings:
        return Icons.settings_outlined;
      case NotificationType.general:
        return Icons.notifications_outlined;
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
      } catch (e) {
        return DateFormat('dd MMM yyyy').format(dateTime);
      }
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _notificationServices.getNotificationList(
        "1",
        showLoading: false,
      );

      if (response != null &&
          response['responseType'] == 'S' &&
          response['responseValue'] != null) {
        final List<dynamic> notificationsData = response['responseValue'];
        final List<NotificationItem> notifications = notificationsData
            .map((item) => _mapToNotificationItem(item))
            .toList();

        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
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
          response['responseValue'] != null) {
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
          // Update all notifications to read status
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageProvider.tr('notifications.markedAllRead'),
                style: TextStyle(fontFamily: 'appFontFamily'),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      printContent('Error marking all as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.tr('notifications.markAllReadError'),
              style: TextStyle(fontFamily: 'appFontFamily'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(
    NotificationItem notification,
    int index,
  ) async {
    final languageProvider = context.read<LanguageProvider>();
    // Optimistically remove from list
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
                style: TextStyle(fontFamily: 'appFontFamily'),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: languageProvider.tr('notifications.restore'),
                textColor: Colors.white,
                onPressed: () {
                  // Restore the deleted notification
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
        // Restore on failure
        setState(() {
          _notifications.insert(index, deletedNotification);
          if (!notification.isRead) {
            _unreadCount++;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageProvider.tr('notifications.deleteError'),
                style: TextStyle(fontFamily: 'appFontFamily'),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      printContent('Error deleting notification: $e');
      // Restore on error
      setState(() {
        _notifications.insert(index, deletedNotification);
        if (!notification.isRead) {
          _unreadCount++;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.tr('common.error'),
              style: TextStyle(fontFamily: 'appFontFamily'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
        // Update the notification in the list
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

            // Update unread count
            if (wasRead) {
              _unreadCount++;
            } else {
              _unreadCount = (_unreadCount - 1).clamp(0, 999);
            }
          }
        });
      }
    } catch (e) {
      // Handle error silently or show a message
      printContent('Error toggling notification status: $e');
    }
  }

  NotificationItem _mapToNotificationItem(Map<String, dynamic> data) {
    // Map type string to NotificationType enum
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

    // Parse DateTime from createdAt
    DateTime time;
    try {
      time = DateTime.parse(
        data['createdAt'] ?? DateTime.now().toIso8601String(),
      );
    } catch (e) {
      time = DateTime.now();
    }

    // isRead is already a boolean in the new API format
    final isRead = data['isRead'] ?? false;

    return NotificationItem(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      time: time,
      isRead: isRead,
      type: type,
    );
  }
}

// Notification Model
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
