// Import the database connection
const pool = require('../config/database');

/**
 * Get all notifications for the current user
 * GET /api/notifications
 */
const getNotifications = async (req, res) => {
    try {
        const { limit = 50, offset = 0, unread_only = false } = req.query;
        const userId = req.user.id;

        let query = `
            SELECT id, user_id, title, message, type, related_id, related_type, is_read, created_at
            FROM notifications
            WHERE user_id = $1
        `;
        const values = [userId];
        let paramCount = 2;

        if (unread_only === 'true') {
            query += ` AND is_read = false`;
        }

        query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
        values.push(parseInt(limit), parseInt(offset));

        const result = await pool.query(query, values);
        
        // Get unread count
        const countQuery = 'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false';
        const countResult = await pool.query(countQuery, [userId]);
        const unreadCount = parseInt(countResult.rows[0].count);

        res.status(200).json({
            success: true,
            data: {
                notifications: result.rows,
                unread_count: unreadCount,
                pagination: {
                    total: result.rows.length,
                    limit: parseInt(limit),
                    offset: parseInt(offset)
                }
            }
        });

    } catch (error) {
        console.error('Get notifications error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch notifications'
        });
    }
};

/**
 * Get unread notification count for the current user
 * GET /api/notifications/unread-count
 */
const getUnreadCount = async (req, res) => {
    try {
        const userId = req.user.id;
        const query = 'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false';
        const result = await pool.query(query, [userId]);
        const unreadCount = parseInt(result.rows[0].count);

        res.status(200).json({
            success: true,
            data: {
                unread_count: unreadCount
            }
        });

    } catch (error) {
        console.error('Get unread count error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get unread count'
        });
    }
};

/**
 * Mark a notification as read
 * PATCH /api/notifications/:id/read
 */
const markAsRead = async (req, res) => {
    try {
        const notificationId = parseInt(req.params.id);
        const userId = req.user.id;

        const query = `
            UPDATE notifications 
            SET is_read = true
            WHERE id = $1 AND user_id = $2
            RETURNING id, user_id, title, message, type, is_read, created_at
        `;
        const result = await pool.query(query, [notificationId, userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Notification not found or you do not have access to it'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Notification marked as read',
            data: {
                notification: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Mark as read error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to mark notification as read'
        });
    }
};

/**
 * Mark all notifications as read for the current user
 * POST /api/notifications/mark-all-read
 */
const markAllAsRead = async (req, res) => {
    try {
        const userId = req.user.id;

        const query = `
            UPDATE notifications 
            SET is_read = true
            WHERE user_id = $1 AND is_read = false
            RETURNING id
        `;
        const result = await pool.query(query, [userId]);

        res.status(200).json({
            success: true,
            message: 'All notifications marked as read',
            data: {
                marked_count: result.rows.length
            }
        });

    } catch (error) {
        console.error('Mark all as read error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to mark all notifications as read'
        });
    }
};

/**
 * Delete a notification
 * DELETE /api/notifications/:id
 */
const deleteNotification = async (req, res) => {
    try {
        const notificationId = parseInt(req.params.id);
        const userId = req.user.id;

        const query = 'DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING id';
        const result = await pool.query(query, [notificationId, userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Notification not found or you do not have access to it'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Notification deleted successfully'
        });

    } catch (error) {
        console.error('Delete notification error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete notification'
        });
    }
};

/**
 * Delete all notifications for the current user
 * DELETE /api/notifications/delete-all
 */
const deleteAllNotifications = async (req, res) => {
    try {
        const userId = req.user.id;

        const query = 'DELETE FROM notifications WHERE user_id = $1 RETURNING id';
        const result = await pool.query(query, [userId]);

        res.status(200).json({
            success: true,
            message: 'All notifications deleted',
            data: {
                deleted_count: result.rows.length
            }
        });

    } catch (error) {
        console.error('Delete all notifications error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete notifications'
        });
    }
};

/**
 * Create a notification (internal use - for admin/system)
 * POST /api/notifications/create
 */
const createNotification = async (req, res) => {
    try {
        const { user_id, title, message, type, related_id, related_type } = req.body;

        if (!user_id || !title || !message || !type) {
            return res.status(400).json({
                success: false,
                message: 'Please provide user_id, title, message, and type'
            });
        }

        const query = `
            INSERT INTO notifications (user_id, title, message, type, related_id, related_type, is_read, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, false, NOW())
            RETURNING id, user_id, title, message, type, related_id, related_type, is_read, created_at
        `;

        const result = await pool.query(query, [
            user_id,
            title,
            message,
            type,
            related_id || null,
            related_type || null
        ]);

        res.status(201).json({
            success: true,
            message: 'Notification created successfully',
            data: {
                notification: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Create notification error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create notification'
        });
    }
};

/**
 * Register device token for push notifications
 * POST /api/notifications/register-device
 */
const registerDeviceToken = async (req, res) => {
    try {
        const { device_token } = req.body;
        const userId = req.user.id;

        if (!device_token) {
            return res.status(400).json({
                success: false,
                message: 'Device token is required'
            });
        }

        // Check if token already exists for this user
        const checkQuery = 'SELECT id FROM device_tokens WHERE token = $1 AND user_id = $2';
        const checkResult = await pool.query(checkQuery, [device_token, userId]);

        if (checkResult.rows.length > 0) {
            // Update last_used timestamp
            await pool.query(
                'UPDATE device_tokens SET last_used = NOW() WHERE token = $1 AND user_id = $2',
                [device_token, userId]
            );
        } else {
            // Insert new token
            await pool.query(
                'INSERT INTO device_tokens (user_id, token, last_used, created_at) VALUES ($1, $2, NOW(), NOW())',
                [userId, device_token]
            );
        }

        res.status(200).json({
            success: true,
            message: 'Device token registered successfully'
        });

    } catch (error) {
        console.error('Register device token error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to register device token'
        });
    }
};

/**
 * Unregister device token
 * POST /api/notifications/unregister-device
 */
const unregisterDeviceToken = async (req, res) => {
    try {
        const { device_token } = req.body;
        const userId = req.user.id;

        if (!device_token) {
            return res.status(400).json({
                success: false,
                message: 'Device token is required'
            });
        }

        await pool.query(
            'DELETE FROM device_tokens WHERE token = $1 AND user_id = $2',
            [device_token, userId]
        );

        res.status(200).json({
            success: true,
            message: 'Device token unregistered successfully'
        });

    } catch (error) {
        console.error('Unregister device token error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to unregister device token'
        });
    }
};

// Export all controller functions
module.exports = {
    getNotifications,
    getUnreadCount,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    deleteAllNotifications,
    createNotification,
    registerDeviceToken,
    unregisterDeviceToken
};