import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_services/connection.dart';

class AppAlertServices {
  final Connection connection = Connection();

  Future<dynamic> getActiveAlert({bool showLoading = false}) async {
    final url = '$appBaseUri/app-alert/active';
    return connection.getData(url, useToken: true, showLoading: showLoading);
  }

  Future<dynamic> recordAction({
    required String alertId,
    required String action,
    int? remindHours,
    bool showLoading = false,
  }) async {
    final url = '$appBaseUri/app-alert/action';
    return connection.postData(
      url,
      {
        'alertId': alertId,
        'action': action,
        'remindHours': ?remindHours,
      },
      useToken: true,
      showLoading: showLoading,
    );
  }
}
