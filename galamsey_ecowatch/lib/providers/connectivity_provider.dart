import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isConnected = true;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;

  bool get isConnected => _isConnected;
  ConnectivityResult get connectivityResult => _connectivityResult;

  ConnectivityProvider() {
    _initConnectivity();
    _listenForChanges();
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _updateState(result);
  }

  void _listenForChanges() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _updateState(result);
    });
  }

  void _updateState(ConnectivityResult result) {
    _connectivityResult = result;
    final bool wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;
    
    if (wasConnected != _isConnected) {
      notifyListeners();
    }
  }

  // Check if currently connected
  Future<bool> checkConnection() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _updateState(result);
    return _isConnected;
  }
}