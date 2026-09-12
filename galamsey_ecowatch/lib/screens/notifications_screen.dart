import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        actions: [
          if (notificationProvider.notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                await notificationProvider.markAllAsRead();
                await notificationProvider.loadNotifications();
              },
              child: const Text(
                'Mark All Read',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationProvider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'re all caught up!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notificationProvider.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationProvider.notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: notification.isRead
                              ? Colors.grey[200]
                              : const Color(0xFF2E7D32).withOpacity(0.2),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: notification.isRead
                                ? Colors.grey[400]
                                : const Color(0xFF2E7D32),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          notification.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: notification.isRead
                                ? Colors.grey[500]
                                : Colors.grey[700],
                          ),
                        ),
                        trailing: notification.isRead
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await notificationProvider.markAsRead(notification.id);
                                  await notificationProvider.loadNotifications();
                                },
                              ),
                        onTap: () {
                          // Navigate to related content if applicable
                        },
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'report_status':
        return Icons.assignment;
      case 'alert':
        return Icons.warning;
      case 'general':
        return Icons.notifications;
      case 'community':
        return Icons.people;
      default:
        return Icons.notifications;
    }
  }
}