import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _initConnectivity();
    _listenToConnectivityChanges();
  }

  /// Check initial connectivity status on app startup
  Future<void> _initConnectivity() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      _updateConnectivityStatus(result);
    } catch (e) {
      _isOnline = true; // Default to online on error
      notifyListeners();
    }
  }

  /// Listen to connectivity changes in real-time
  void _listenToConnectivityChanges() {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((result) {
      _updateConnectivityStatus(result);
    });
  }

  /// Update connectivity status
  void _updateConnectivityStatus(List<ConnectivityResult> result) {
    final wasOnline = _isOnline;
    _isOnline = !result.contains(ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      notifyListeners();
    }
  }
}
