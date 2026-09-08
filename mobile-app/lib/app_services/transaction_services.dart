import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/connection.dart';

/// SERVICE CLASS FOR TRANSACTION RELATED API CALLS
class TransactionServices {
  final Connection connection = Connection();

  // ---------------------------------------------------------------------------
  // PERSON APIS
  // ---------------------------------------------------------------------------
  Future<dynamic> getPersons(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/persons/list';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> createPerson(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/persons/create';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> updatePerson(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/persons/update';
    return await connection.putData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> deletePerson(
    String personId, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/persons/$personId';
    return await connection.deleteData(
      url,
      useToken: true,
      showLoading: showLoading,
    );
  }

  // ---------------------------------------------------------------------------
  // TRANSACTION-FUNCTION APIS
  // ---------------------------------------------------------------------------
  Future<dynamic> createTransactionFunction(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/transaction-functions/create';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> listTransactionFunctions(
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

  Future<dynamic> updateTransactionFunction(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/transaction-functions/update';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> deleteTransactionFunction(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/transaction-functions/delete';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  // ---------------------------------------------------------------------------
  // TRANSACTION APIS
  // ---------------------------------------------------------------------------
  Future<dynamic> createTransactionV2(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/transactions/create-v2';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> listTransactions(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/transactions/list';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> updateTransaction(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/transactions/update';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> deleteTransaction(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/transactions/delete';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> getTransactionDetail(
    Map<String, dynamic> params, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/transactions/detail';
    return await connection.postData(
      url,
      params,
      useToken: true,
      showLoading: showLoading,
    );
  }
}
