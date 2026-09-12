const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

// All notification routes require authentication
router.use(authenticate);

// Get all notifications for the current user
router.get('/', notificationController.getNotifications);

// Get unread notification count
router.get('/unread-count', notificationController.getUnreadCount);

// Mark a notification as read
router.patch('/:id/read', notificationController.markAsRead);

// Mark all notifications as read
router.post('/mark-all-read', notificationController.markAllAsRead);

// Delete a notification
router.delete('/:id', notificationController.deleteNotification);

// Delete all notifications
router.delete('/delete-all', notificationController.deleteAllNotifications);

// Register device token for push notifications
router.post('/register-device', notificationController.registerDeviceToken);

// Unregister device token
router.post('/unregister-device', notificationController.unregisterDeviceToken);

// Admin only - create notification manually
router.post('/create', isAdmin, notificationController.createNotification);

module.exports = router;