import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';

class NotificationApiService {
  final Dio dio;

  NotificationApiService() : dio = Dio() {
    dio.options.baseUrl = AppConfig.apiUrl;
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Register device token with backend
  Future<bool> registerDeviceToken(String token) async {
    try {
      final response = await dio.post(
        '/notifications/register-device',
        data: {'device_token': token},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Error registering device token: $e');
      return false;
    }
  }

  // Unregister device token
  Future<bool> unregisterDeviceToken(String token) async {
    try {
      final response = await dio.post(
        '/notifications/unregister-device',
        data: {'device_token': token},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Error unregistering device token: $e');
      return false;
    }
  }

  // Get all notifications for user
  Future<Response> getNotifications({int limit = 50, int offset = 0}) async {
    return await dio.get(
      '/notifications',
      queryParameters: {'limit': limit, 'offset': offset},
    );
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await dio.patch('/notifications/$notificationId/read');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await dio.post('/notifications/mark-all-read');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await dio.delete('/notifications/$notificationId');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}