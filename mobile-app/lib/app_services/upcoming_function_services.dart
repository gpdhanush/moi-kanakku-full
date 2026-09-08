import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/connection.dart';

class UpcomingFunctionServices {
  final Connection connection = Connection();

  // List all upcoming functions for authenticated user
  Future<dynamic> getUpcomingFunctions() async {
    String url = '$appBaseUri/upcoming-functions/list';
    return await connection.postData(
      url,
      {},
      useToken: true,
      showLoading: true,
    );
  }

  // Create new upcoming function
  Future<dynamic> createUpcomingFunction(
    Map<String, dynamic> params, {
    String? imagePath,
  }) async {
    String url = '$appBaseUri/upcoming-functions/create';
    if (imagePath != null && imagePath.isNotEmpty) {
      return await connection.uploadFile(
        url,
        params,
        'invitationImage',
        imagePath,
        useToken: true,
      );
    }
    return await connection.postData(url, params, useToken: true);
  }

  // Update existing upcoming function
  Future<dynamic> updateUpcomingFunction(
    Map<String, dynamic> params, {
    String? imagePath,
  }) async {
    String url = '$appBaseUri/upcoming-functions/update';
    if (imagePath != null && imagePath.isNotEmpty) {
      return await connection.uploadFile(
        url,
        params,
        'invitationImage',
        imagePath,
        useToken: true,
      );
    }
    return await connection.postData(url, params, useToken: true);
  }

  // Update status of upcoming function
  Future<dynamic> updateStatus(String functionId, String status) async {
    String url = '$appBaseUri/upcoming-functions/update-status';
    return await connection.postData(
      url,
      {'id': functionId, 'status': status},
      useToken: true,
      showLoading: false,
    );
  }

  // Delete upcoming function (soft delete)
  Future<dynamic> deleteUpcomingFunction(String functionId) async {
    String url = '$appBaseUri/upcoming-functions/delete/$functionId';
    return await connection.getData(url, useToken: true, showLoading: false);
  }

  // Admin: Get all upcoming functions
  Future<dynamic> adminListAll() async {
    String url = '$appBaseUri/upcoming-functions/admin/list-all';
    return await connection.postData(
      url,
      {},
      useToken: true,
      showLoading: true,
    );
  }

  // Admin: Get statistics
  Future<dynamic> adminGetStatistics() async {
    String url = '$appBaseUri/upcoming-functions/admin/statistics';
    return await connection.getData(url, useToken: true, showLoading: false);
  }

  // Admin: Get by date range
  Future<dynamic> adminGetByDateRange(String startDate, String endDate) async {
    String url = '$appBaseUri/upcoming-functions/admin/by-date-range';
    return await connection.postData(
      url,
      {'startDate': startDate, 'endDate': endDate},
      useToken: true,
      showLoading: true,
    );
  }

  // Upload invitation image
  Future<dynamic> uploadUpcomingFunctionImage(
    Map<String, dynamic> params,
    String imagePath,
  ) async {
    String url = '$appBaseUri/uploads/saveFiles';
    return await connection.uploadFile(
      url,
      params,
      'file',
      imagePath,
      useToken: true,
    );
  }
}
