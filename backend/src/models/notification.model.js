// Import the database connection
const pool = require('../config/database');

// Notification model - contains all database operations for notifications
const Notification = {
    /**
     * Create a new notification for a user
     * @param {Object} notificationData - Notification information
     * @returns {Object} Created notification
     */
    async create(notificationData) {
        const {
            user_id,
            title,
            message,
            type,
            related_id = null,
            related_type = null
        } = notificationData;

        const query = `
            INSERT INTO notifications (user_id, title, message, type, related_id, related_type, is_read, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
            RETURNING id, user_id, title, message, type, related_id, related_type, is_read, created_at
        `;

        const result = await pool.query(query, [
            user_id,
            title,
            message,
            type,
            related_id,
            related_type,
            false // is_read defaults to false
        ]);

        return result.rows[0];
    },

    /**
     * Get all notifications for a user
     * @param {number} userId - User ID
     * @param {Object} options - Pagination options
     * @returns {Array} List of notifications
     */
    async findByUser(userId, options = {}) {
        const { limit = 50, offset = 0, unreadOnly = false } = options;

        let query = `
            SELECT id, user_id, title, message, type, related_id, related_type, is_read, created_at
            FROM notifications
            WHERE user_id = $1
        `;
        const values = [userId];
        let paramCount = 2;

        if (unreadOnly) {
            query += ` AND is_read = false`;
        }

        query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
        values.push(limit, offset);

        const result = await pool.query(query, values);
        return result.rows;
    },

    /**
     * Count total notifications for a user
     * @param {number} userId - User ID
     * @param {boolean} unreadOnly - Count only unread notifications
     * @returns {number} Total count
     */
    async countByUser(userId, unreadOnly = false) {
        let query = 'SELECT COUNT(*) FROM notifications WHERE user_id = $1';
        const values = [userId];

        if (unreadOnly) {
            query += ` AND is_read = false`;
        }

        const result = await pool.query(query, values);
        return parseInt(result.rows[0].count);
    },

    /**
     * Mark a notification as read
     * @param {number} notificationId - Notification ID
     * @param {number} userId - User ID (for authorization)
     * @returns {Object} Updated notification
     */
    async markAsRead(notificationId, userId) {
        const query = `
            UPDATE notifications 
            SET is_read = true
            WHERE id = $1 AND user_id = $2
            RETURNING id, user_id, title, message, type, is_read, created_at
        `;
        const result = await pool.query(query, [notificationId, userId]);
        return result.rows[0] || null;
    },

    /**
     * Mark all notifications as read for a user
     * @param {number} userId - User ID
     * @returns {number} Number of notifications marked as read
     */
    async markAllAsRead(userId) {
        const query = `
            UPDATE notifications 
            SET is_read = true
            WHERE user_id = $1 AND is_read = false
            RETURNING id
        `;
        const result = await pool.query(query, [userId]);
        return result.rows.length;
    },

    /**
     * Delete a notification
     * @param {number} notificationId - Notification ID
     * @param {number} userId - User ID (for authorization)
     * @returns {boolean} True if deleted
     */
    async delete(notificationId, userId) {
        const query = 'DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING id';
        const result = await pool.query(query, [notificationId, userId]);
        return result.rows.length > 0;
    },

    /**
     * Delete all notifications for a user
     * @param {number} userId - User ID
     * @returns {number} Number of notifications deleted
     */
    async deleteAll(userId) {
        const query = 'DELETE FROM notifications WHERE user_id = $1 RETURNING id';
        const result = await pool.query(query, [userId]);
        return result.rows.length;
    },

    /**
     * Create notifications for multiple users (e.g., for alerts)
     * @param {Array} userIds - List of user IDs
     * @param {Object} notificationData - Notification information
     * @returns {Array} Created notifications
     */
    async createBulk(userIds, notificationData) {
        const { title, message, type, related_id = null, related_type = null } = notificationData;

        const notifications = [];
        for (const userId of userIds) {
            const notification = await this.create({
                user_id: userId,
                title,
                message,
                type,
                related_id,
                related_type
            });
            notifications.push(notification);
        }

        return notifications;
    },

    /**
     * Get unread count for a user
     * @param {number} userId - User ID
     * @returns {number} Unread count
     */
    async getUnreadCount(userId) {
        return await this.countByUser(userId, true);
    },

    /**
     * Get notifications by type
     * @param {number} userId - User ID
     * @param {string} type - Notification type
     * @param {Object} options - Pagination options
     * @returns {Array} List of notifications
     */
    async findByType(userId, type, options = {}) {
        const { limit = 50, offset = 0 } = options;

        const query = `
            SELECT id, user_id, title, message, type, related_id, related_type, is_read, created_at
            FROM notifications
            WHERE user_id = $1 AND type = $2
            ORDER BY created_at DESC
            LIMIT $3 OFFSET $4
        `;
        const result = await pool.query(query, [userId, type, limit, offset]);
        return result.rows;
    }
};

// Export the Notification model
module.exports = Notification;