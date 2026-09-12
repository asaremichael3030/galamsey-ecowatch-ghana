import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService apiService;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  NotificationProvider(this.apiService);

  // Load notifications
  Future<void> loadNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      if (unreadOnly) queryParams['unread_only'] = 'true';

      final response = await apiService.get('/notifications', queryParams: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> notifData = response.data['data']['notifications'];
        _notifications = notifData.map((json) => AppNotification.fromJson(json)).toList();
        _unreadCount = response.data['data']['unread_count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add notification locally (for real-time updates)
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  // Mark notification as read
  Future<bool> markAsRead(int id) async {
    try {
      final response = await apiService.patch('/notifications/$id/read');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index].isRead = true;
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Mark all as read
  Future<int> markAllAsRead() async {
    try {
      final response = await apiService.post('/notifications/mark-all-read');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final count = response.data['data']['marked_count'] ?? 0;
        for (var notification in _notifications) {
          notification.isRead = true;
        }
        _unreadCount = 0;
        notifyListeners();
        return count;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(int id) async {
    try {
      final response = await apiService.delete('/notifications/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _notifications.removeWhere((n) => n.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get unread count
  Future<void> refreshUnreadCount() async {
    try {
      final response = await apiService.get('/notifications/unread-count');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _unreadCount = response.data['data']['unread_count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing unread count: $e');
    }
  }

  // Reset provider
  void reset() {
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    notifyListeners();
  }
}