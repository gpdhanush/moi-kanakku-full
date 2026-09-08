import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/connection.dart';

class FunctionServices {
  final Connection connection = Connection();

  // TO GET ALL FUNCTION LISTS IN POST METHOD
  Future<dynamic> getUserFunctions(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/transaction-functions/list';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> saveFunctions(Map<String, dynamic> params) async {
    String url = '$appBaseUri/transaction-functions/create';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> updateFunctions(Map<String, dynamic> params) async {
    String url = '$appBaseUri/transaction-functions/update';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> deleteUserBaseFunctions(String id) async {
    String url = '$appBaseUri/transaction-functions/delete';
    final params = {"functionId": id};
    return await connection.postData(url, params, useToken: true);
  }

  /// generic file upload. [path] should be the server folder name (e.g. "function-image", "profile").
  Future<dynamic> uploadFile(
    String userId,
    String filePath,
    String path,
  ) async {
    String url = '$appBaseUri/uploads/saveFiles';
    final params = {"userId": userId, "path": path};
    return await connection.uploadFile(
      url,
      params,
      'file',
      filePath,
      useToken: true,
    );
  }
}
