// Import the database connection
const pool = require('../config/database');

/**
 * Get all investigations
 * GET /api/investigations
 */
const getAllInvestigations = async (req, res) => {
    try {
        const { status, officer_id } = req.query;

        let query = `
            SELECT i.*, 
                   u.full_name as officer_name,
                   r.title as report_title,
                   r.report_code as report_code
            FROM investigations i
            LEFT JOIN users u ON i.officer_id = u.id
            LEFT JOIN reports r ON i.report_id = r.id
            WHERE 1=1
        `;
        const values = [];
        let paramCount = 1;

        if (status) {
            query += ` AND i.status = $${paramCount}`;
            values.push(status);
            paramCount++;
        }

        if (officer_id) {
            query += ` AND i.officer_id = $${paramCount}`;
            values.push(parseInt(officer_id));
            paramCount++;
        }

        // If user is officer, only show investigations assigned to them
        if (req.user.role === 'officer') {
            query += ` AND i.officer_id = $${paramCount}`;
            values.push(req.user.id);
            paramCount++;
        }

        query += ' ORDER BY i.created_at DESC';

        const result = await pool.query(query, values);

        res.status(200).json({
            success: true,
            data: {
                investigations: result.rows
            }
        });

    } catch (error) {
        console.error('Get investigations error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch investigations',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get investigation by ID
 * GET /api/investigations/:id
 */
const getInvestigationById = async (req, res) => {
    try {
        const investigationId = parseInt(req.params.id);
        const query = `
            SELECT i.*, 
                   u.full_name as officer_name,
                   r.title as report_title,
                   r.report_code as report_code
            FROM investigations i
            LEFT JOIN users u ON i.officer_id = u.id
            LEFT JOIN reports r ON i.report_id = r.id
            WHERE i.id = $1
        `;
        const result = await pool.query(query, [investigationId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Investigation not found'
            });
        }

        res.status(200).json({
            success: true,
            data: {
                investigation: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Get investigation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch investigation',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Create a new investigation
 * POST /api/investigations
 */
const createInvestigation = async (req, res) => {
    try {
        const {
            report_id,
            officer_id,
            title,
            findings,
            notes,
            recommendation,
            status = 'not_started'
        } = req.body;

        // Validate required fields
        if (!report_id || !title) {
            return res.status(400).json({
                success: false,
                message: 'Report ID and title are required'
            });
        }

        // Check if report exists
        const reportCheck = await pool.query('SELECT id FROM reports WHERE id = $1', [report_id]);
        if (reportCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Report not found'
            });
        }

        const query = `
            INSERT INTO investigations (
                report_id, officer_id, title, findings, notes,
                recommendation, status, started_at, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW(), NOW())
            RETURNING *
        `;

        const values = [
            report_id,
            officer_id || null,
            title.trim(),
            findings || null,
            notes || null,
            recommendation || null,
            status
        ];

        const result = await pool.query(query, values);

        // Update report status to under_investigation
        await pool.query(
            'UPDATE reports SET status = $1, updated_at = NOW() WHERE id = $2',
            ['under_investigation', report_id]
        );

        res.status(201).json({
            success: true,
            message: 'Investigation created successfully',
            data: {
                investigation: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Create investigation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create investigation',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update an investigation
 * PUT /api/investigations/:id
 */
const updateInvestigation = async (req, res) => {
    try {
        const investigationId = parseInt(req.params.id);
        const {
            officer_id,
            title,
            findings,
            notes,
            recommendation,
            status
        } = req.body;

        // Check if investigation exists
        const checkQuery = 'SELECT id FROM investigations WHERE id = $1';
        const checkResult = await pool.query(checkQuery, [investigationId]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Investigation not found'
            });
        }

        // Build update query
        const fields = [];
        const values = [];
        let paramCount = 1;

        if (officer_id !== undefined) {
            fields.push(`officer_id = $${paramCount}`);
            values.push(officer_id);
            paramCount++;
        }
        if (title !== undefined) {
            fields.push(`title = $${paramCount}`);
            values.push(title.trim());
            paramCount++;
        }
        if (findings !== undefined) {
            fields.push(`findings = $${paramCount}`);
            values.push(findings);
            paramCount++;
        }
        if (notes !== undefined) {
            fields.push(`notes = $${paramCount}`);
            values.push(notes);
            paramCount++;
        }
        if (recommendation !== undefined) {
            fields.push(`recommendation = $${paramCount}`);
            values.push(recommendation);
            paramCount++;
        }
        if (status !== undefined) {
            fields.push(`status = $${paramCount}`);
            values.push(status);
            paramCount++;
        }

        if (fields.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No fields to update'
            });
        }

        values.push(investigationId);
        const query = `
            UPDATE investigations 
            SET ${fields.join(', ')}, updated_at = NOW()
            WHERE id = $${paramCount}
            RETURNING *
        `;

        const result = await pool.query(query, values);

        res.status(200).json({
            success: true,
            message: 'Investigation updated successfully',
            data: {
                investigation: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Update investigation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update investigation',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update investigation status only
 * PATCH /api/investigations/:id/status
 */
const updateInvestigationStatus = async (req, res) => {
    try {
        const investigationId = parseInt(req.params.id);
        const { status, comment } = req.body;

        if (!status) {
            return res.status(400).json({
                success: false,
                message: 'Status is required'
            });
        }

        // Check if investigation exists
        const checkQuery = 'SELECT id, officer_id FROM investigations WHERE id = $1';
        const checkResult = await pool.query(checkQuery, [investigationId]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Investigation not found'
            });
        }

        const investigation = checkResult.rows[0];

        // Check if user is allowed to update status
        if (req.user.role === 'officer' && investigation.officer_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'You can only update investigations assigned to you'
            });
        }

        const query = `
            UPDATE investigations 
            SET status = $1, updated_at = NOW()
            WHERE id = $2
            RETURNING *
        `;

        const result = await pool.query(query, [status, investigationId]);

        // If investigation is completed, update report status to resolved
        if (status === 'completed') {
            const invQuery = 'SELECT report_id FROM investigations WHERE id = $1';
            const invResult = await pool.query(invQuery, [investigationId]);
            if (invResult.rows.length > 0 && invResult.rows[0].report_id) {
                await pool.query(
                    'UPDATE reports SET status = $1, updated_at = NOW() WHERE id = $2',
                    ['resolved', invResult.rows[0].report_id]
                );
            }
        }

        res.status(200).json({
            success: true,
            message: 'Investigation status updated successfully',
            data: {
                investigation: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Update investigation status error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update investigation status',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Delete an investigation
 * DELETE /api/investigations/:id
 */
const deleteInvestigation = async (req, res) => {
    try {
        const investigationId = parseInt(req.params.id);

        const query = 'DELETE FROM investigations WHERE id = $1 RETURNING id';
        const result = await pool.query(query, [investigationId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Investigation not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Investigation deleted successfully'
        });

    } catch (error) {
        console.error('Delete investigation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete investigation',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

module.exports = {
    getAllInvestigations,
    getInvestigationById,
    createInvestigation,
    updateInvestigation,
    updateInvestigationStatus,
    deleteInvestigation
};