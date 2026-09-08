import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/connection.dart';

class FeedbackServices {
  Connection connection = Connection();

  /// Save feedback with static type and status
  /// Adds type: "COMPLAINT" and status: "OPEN" to the request
  Future<dynamic> saveFeedbacks(dynamic params) async {
    String url = '$appBaseUri/feedbacks/create';

    // Add static type and status
    final updateParams = {
      if (params is Map) ...params,
      'type': 'GENERAL',
      'status': 'OPEN',
    };

    return await connection.postData(url, updateParams, useToken: true);
  }

  // Fetch previous feedbacks with replies
  Future<dynamic> getFeedbacks(
    dynamic params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/feedbacks/list';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  // Get feedbacks list (POST request with userId for security)
  Future<dynamic> getFeedbacksList(
    dynamic params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/feedbacks/list';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }
}
