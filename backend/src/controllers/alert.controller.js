// Import the database connection
const pool = require('../config/database');

/**
 * Get all alerts
 * GET /api/alerts
 */
const getAllAlerts = async (req, res) => {
    try {
        const { is_active, category, severity } = req.query;

        let query = 'SELECT * FROM alerts WHERE 1=1';
        const values = [];
        let paramCount = 1;

        if (is_active !== undefined) {
            query += ` AND is_active = $${paramCount}`;
            values.push(is_active === 'true');
            paramCount++;
        }

        if (category) {
            query += ` AND category = $${paramCount}`;
            values.push(category);
            paramCount++;
        }

        if (severity) {
            query += ` AND severity = $${paramCount}`;
            values.push(severity);
            paramCount++;
        }

        query += ' ORDER BY created_at DESC';

        const result = await pool.query(query, values);

        res.status(200).json({
            success: true,
            data: {
                alerts: result.rows
            }
        });

    } catch (error) {
        console.error('Get alerts error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch alerts',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get alert by ID
 * GET /api/alerts/:id
 */
const getAlertById = async (req, res) => {
    try {
        const alertId = parseInt(req.params.id);
        const query = 'SELECT * FROM alerts WHERE id = $1';
        const result = await pool.query(query, [alertId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Alert not found'
            });
        }

        res.status(200).json({
            success: true,
            data: {
                alert: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Get alert error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch alert',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Create a new alert
 * POST /api/alerts
 */
const createAlert = async (req, res) => {
    try {
        const {
            title,
            description,
            category,
            severity,
            region,
            start_date,
            end_date,
            is_active = true
        } = req.body;

        // Validate required fields
        if (!title || !description) {
            return res.status(400).json({
                success: false,
                message: 'Title and description are required'
            });
        }

        const query = `
            INSERT INTO alerts (
                created_by, title, description, category, severity,
                region, start_date, end_date, is_active, created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
            RETURNING *
        `;

        const values = [
            req.user.id,
            title.trim(),
            description.trim(),
            category || 'General',
            severity || 'Medium',
            region || null,
            start_date || null,
            end_date || null,
            is_active
        ];

        const result = await pool.query(query, values);

        res.status(201).json({
            success: true,
            message: 'Alert created successfully',
            data: {
                alert: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Create alert error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create alert',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update an alert
 * PUT /api/alerts/:id
 */
const updateAlert = async (req, res) => {
    try {
        const alertId = parseInt(req.params.id);
        const {
            title,
            description,
            category,
            severity,
            region,
            start_date,
            end_date,
            is_active
        } = req.body;

        // Check if alert exists
        const checkQuery = 'SELECT id FROM alerts WHERE id = $1';
        const checkResult = await pool.query(checkQuery, [alertId]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Alert not found'
            });
        }

        // Build update query
        const fields = [];
        const values = [];
        let paramCount = 1;

        if (title !== undefined) {
            fields.push(`title = $${paramCount}`);
            values.push(title.trim());
            paramCount++;
        }
        if (description !== undefined) {
            fields.push(`description = $${paramCount}`);
            values.push(description.trim());
            paramCount++;
        }
        if (category !== undefined) {
            fields.push(`category = $${paramCount}`);
            values.push(category);
            paramCount++;
        }
        if (severity !== undefined) {
            fields.push(`severity = $${paramCount}`);
            values.push(severity);
            paramCount++;
        }
        if (region !== undefined) {
            fields.push(`region = $${paramCount}`);
            values.push(region);
            paramCount++;
        }
        if (start_date !== undefined) {
            fields.push(`start_date = $${paramCount}`);
            values.push(start_date);
            paramCount++;
        }
        if (end_date !== undefined) {
            fields.push(`end_date = $${paramCount}`);
            values.push(end_date);
            paramCount++;
        }
        if (is_active !== undefined) {
            fields.push(`is_active = $${paramCount}`);
            values.push(is_active);
            paramCount++;
        }

        if (fields.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No fields to update'
            });
        }

        values.push(alertId);
        const query = `
            UPDATE alerts 
            SET ${fields.join(', ')}, updated_at = NOW()
            WHERE id = $${paramCount}
            RETURNING *
        `;

        const result = await pool.query(query, values);

        res.status(200).json({
            success: true,
            message: 'Alert updated successfully',
            data: {
                alert: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Update alert error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update alert',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Delete an alert
 * DELETE /api/alerts/:id
 */
const deleteAlert = async (req, res) => {
    try {
        const alertId = parseInt(req.params.id);

        const query = 'DELETE FROM alerts WHERE id = $1 RETURNING id';
        const result = await pool.query(query, [alertId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Alert not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Alert deleted successfully'
        });

    } catch (error) {
        console.error('Delete alert error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete alert',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

module.exports = {
    getAllAlerts,
    getAlertById,
    createAlert,
    updateAlert,
    deleteAlert
};