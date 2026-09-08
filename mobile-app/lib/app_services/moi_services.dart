import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_services/connection.dart';

class MoiServices {
  final Connection connection = Connection();

  Future<dynamic> getTotalAmount(
    dynamic params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/default/total-amount';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> saveMoi(dynamic params) async {
    var url = '$appBaseUri/moi/create';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> updateMoi(dynamic params) async {
    var url = '$appBaseUri/moi/update';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> getUserMoi(dynamic params) async {
    var url = '$appBaseUri/moi/list';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> deleteUserBaseMoi(String id) async {
    var url = '$appBaseUri/moi/delete/$id';
    return await connection.getData(url, useToken: true);
  }

  Future<dynamic> saveMoiOut(dynamic params) async {
    var url = '$appBaseUri/moi-out/create';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> updateMoiOut(dynamic params) async {
    var url = '$appBaseUri/moi-out/update';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> getUserMoiOut(dynamic params) async {
    var url = '$appBaseUri/moi-out/list';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> deleteUserBaseMoiOut(String id) async {
    var url = '$appBaseUri/moi-out/delete/$id';
    return await connection.getData(url, useToken: true);
  }

  Future<dynamic> getMoiCreditDebitDashboard(
    dynamic params, {
    bool showLoading = true,
  }) async {
    var url = '$appBaseUri/moi/dashboard';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> createMoiPerson(dynamic params) async {
    var url = '$appBaseUri/moi-persons/create';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> updateMoiPerson(dynamic params) async {
    var url = '$appBaseUri/moi-persons/update';
    return await connection.putData(url, params, useToken: true);
  }

  Future<dynamic> createMoiReturn(dynamic params) async {
    var url = '$appBaseUri/moi-credit-debit/return';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> createMoiInvest(dynamic params) async {
    var url = '$appBaseUri/moi-credit-debit/invest';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> getMoiDefaultFunctions(
    dynamic params, {
    bool showLoading = false,
  }) async {
    var url = '$appBaseUri/moi-default-functions/list';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> getMoiDefaultFunctionsDropdown(
    dynamic params, {
    bool showLoading = false,
  }) async {
    var url = '$appBaseUri/moi-default-functions/dropdown';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> getDefaultFunctionLists(
    dynamic params, {
    bool showLoading = false,
  }) async {
    var url = '$appBaseUri/moi-default-functions/list';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> deleteMoiPerson(String id) async {
    var url = '$appBaseUri/persons/$id';
    return await connection.deleteData(url, useToken: true);
  }

  Future<dynamic> updateMoiCreditDebit(dynamic params) async {
    var url = '$appBaseUri/moi-credit-debit/update';
    return await connection.putData(url, params, useToken: true);
  }

  // ---------------------------------------------------------------------
  // New transaction APIs
  // These endpoints replace the older "moi-credit-debit" calls. They
  // live under `/transactions` and expect a common payload regardless of
  // whether the transaction is a return or an invest. The caller is
  // responsible for converting the form values into the format shown in
  // documentation.

  Future<dynamic> createTransaction(dynamic params) async {
    var url = '$appBaseUri/transactions/create';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> updateTransaction(dynamic params) async {
    var url = '$appBaseUri/transactions/update';
    return await connection.postData(url, params, useToken: true);
  }

  Future<dynamic> deleteMoiCreditDebit(String id) async {
    var url = '$appBaseUri/moi-credit-debit/$id';
    return await connection.deleteData(url, useToken: true);
  }
}
