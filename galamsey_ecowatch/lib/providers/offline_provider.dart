import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/report_model.dart';
import '../models/notification_model.dart';

class OfflineProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  bool _isOffline = false;
  bool _hasOfflineData = false;

  bool get isOffline => _isOffline;
  bool get hasOfflineData => _hasOfflineData;

  OfflineProvider() {
    checkOfflineData();
  }

  void setOfflineMode(bool offline) {
    _isOffline = offline;
    notifyListeners();
  }

  Future<void> checkOfflineData() async {
    _hasOfflineData = await _db.hasData();
    notifyListeners();
  }

  // Save reports offline
  Future<void> saveReportsOffline(List<Report> reports) async {
    await _db.saveReports(reports);
    _hasOfflineData = true;
    notifyListeners();
  }

  // Get reports from offline storage
  Future<List<Report>> getReportsOffline() async {
    return await _db.getReports();
  }

  // Get a single report from offline storage
  Future<Report?> getReportOffline(int id) async {
    return await _db.getReportById(id);
  }

  // Save notifications offline
  Future<void> saveNotificationsOffline(List<AppNotification> notifications) async {
    await _db.saveNotifications(notifications);
    notifyListeners();
  }

  // Get notifications from offline storage
  Future<List<AppNotification>> getNotificationsOffline() async {
    return await _db.getNotifications();
  }

  // Clear all offline data
  Future<void> clearAllOfflineData() async {
    await _db.clearAllData();
    _hasOfflineData = false;
    notifyListeners();
  }

  // Save user offline
  Future<void> saveUserOffline(Map<String, dynamic> user) async {
    await _db.saveUser(user);
    notifyListeners();
  }

  // Get user from offline storage
  Future<Map<String, dynamic>?> getUserOffline() async {
    return await _db.getUser();
  }

  // Save alerts offline
  Future<void> saveAlertsOffline(List<Map<String, dynamic>> alerts) async {
    await _db.saveAlerts(alerts);
    notifyListeners();
  }

  // Get alerts from offline storage
  Future<List<Map<String, dynamic>>> getAlertsOffline() async {
    return await _db.getAlerts();
  }
}