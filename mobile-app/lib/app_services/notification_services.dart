import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_services/connection.dart';

class NotificationServices {
  final Connection connection = Connection();

  // Get notifications for user (server-side pagination via limit/offset).
  Future<dynamic> getNotificationList(
    String userId, {
    int limit = 30,
    int offset = 0,
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/notification/list';
    return await connection.postData(
      url,
      {
        "userId": userId,
        "limit": limit,
        "offset": offset,
      },
      useToken: true,
      showLoading: showLoading,
    );
  }

  // Get unread notification count
  Future<dynamic> getUnreadCount() async {
    String url = '$appBaseUri/notification/unread-count';
    return await connection.getData(url, useToken: true, showLoading: false);
  }

  // Mark single notification as read
  Future<dynamic> markAsRead(String notificationId) async {
    String url = '$appBaseUri/notification/mark-as-read';
    return await connection.postData(
      url,
      {"notificationId": notificationId},
      useToken: true,
      showLoading: false,
    );
  }

  // Mark single notification as unread
  Future<dynamic> markAsUnread(String notificationId) async {
    String url = '$appBaseUri/notification/mark-as-unread';
    return await connection.postData(
      url,
      {"notificationId": notificationId},
      useToken: true,
      showLoading: false,
    );
  }

  // Mark all notifications as read
  Future<dynamic> markAllAsRead() async {
    String url = '$appBaseUri/notification/mark-all-as-read';
    return await connection.postData(
      url,
      {},
      useToken: true,
      showLoading: false,
    );
  }

  // Delete notification (soft delete)
  Future<dynamic> deleteNotification(String notificationId) async {
    String url = '$appBaseUri/notification/delete';
    return await connection.postData(
      url,
      {"notificationId": notificationId},
      useToken: true,
      showLoading: false,
    );
  }
}
