// Import the database connection
const pool = require('../config/database');

/**
 * Get all tasks
 * GET /api/tasks
 */
const getAllTasks = async (req, res) => {
    try {
        const { status, priority, assigned_to } = req.query;

        let query = `
            SELECT t.*, 
                   u.full_name as assigned_name,
                   r.title as report_title
            FROM tasks t
            LEFT JOIN users u ON t.assigned_to = u.id
            LEFT JOIN reports r ON t.report_id = r.id
            WHERE 1=1
        `;
        const values = [];
        let paramCount = 1;

        if (status) {
            query += ` AND t.status = $${paramCount}`;
            values.push(status);
            paramCount++;
        }

        if (priority) {
            query += ` AND t.priority = $${paramCount}`;
            values.push(priority);
            paramCount++;
        }

        if (assigned_to) {
            query += ` AND t.assigned_to = $${paramCount}`;
            values.push(parseInt(assigned_to));
            paramCount++;
        }

        // If user is officer, only show tasks assigned to them
        if (req.user.role === 'officer') {
            query += ` AND (t.assigned_to = $${paramCount} OR t.assigned_to IS NULL)`;
            values.push(req.user.id);
            paramCount++;
        }

        query += ' ORDER BY t.created_at DESC';

        const result = await pool.query(query, values);

        res.status(200).json({
            success: true,
            data: {
                tasks: result.rows
            }
        });

    } catch (error) {
        console.error('Get tasks error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch tasks',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get task by ID
 * GET /api/tasks/:id
 */
const getTaskById = async (req, res) => {
    try {
        const taskId = parseInt(req.params.id);
        const query = `
            SELECT t.*, 
                   u.full_name as assigned_name,
                   r.title as report_title
            FROM tasks t
            LEFT JOIN users u ON t.assigned_to = u.id
            LEFT JOIN reports r ON t.report_id = r.id
            WHERE t.id = $1
        `;
        const result = await pool.query(query, [taskId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Task not found'
            });
        }

        res.status(200).json({
            success: true,
            data: {
                task: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Get task error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch task',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Create a new task
 * POST /api/tasks
 */
const createTask = async (req, res) => {
    try {
        const {
            title,
            description,
            priority = 'Medium',
            status = 'pending',
            assigned_to,
            report_id,
            due_date
        } = req.body;

        // Validate required fields
        if (!title || !description) {
            return res.status(400).json({
                success: false,
                message: 'Title and description are required'
            });
        }

        const query = `
            INSERT INTO tasks (
                title, description, priority, status,
                assigned_to, report_id, due_date, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
            RETURNING *
        `;

        const values = [
            title.trim(),
            description.trim(),
            priority,
            status,
            assigned_to || null,
            report_id || null,
            due_date || null
        ];

        const result = await pool.query(query, values);

        res.status(201).json({
            success: true,
            message: 'Task created successfully',
            data: {
                task: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Create task error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create task',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update a task
 * PUT /api/tasks/:id
 */
const updateTask = async (req, res) => {
    try {
        const taskId = parseInt(req.params.id);
        const {
            title,
            description,
            priority,
            status,
            assigned_to,
            report_id,
            due_date
        } = req.body;

        // Check if task exists
        const checkQuery = 'SELECT id FROM tasks WHERE id = $1';
        const checkResult = await pool.query(checkQuery, [taskId]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Task not found'
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
        if (priority !== undefined) {
            fields.push(`priority = $${paramCount}`);
            values.push(priority);
            paramCount++;
        }
        if (status !== undefined) {
            fields.push(`status = $${paramCount}`);
            values.push(status);
            paramCount++;
        }
        if (assigned_to !== undefined) {
            fields.push(`assigned_to = $${paramCount}`);
            values.push(assigned_to);
            paramCount++;
        }
        if (report_id !== undefined) {
            fields.push(`report_id = $${paramCount}`);
            values.push(report_id);
            paramCount++;
        }
        if (due_date !== undefined) {
            fields.push(`due_date = $${paramCount}`);
            values.push(due_date);
            paramCount++;
        }

        if (fields.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No fields to update'
            });
        }

        values.push(taskId);
        const query = `
            UPDATE tasks 
            SET ${fields.join(', ')}, updated_at = NOW()
            WHERE id = $${paramCount}
            RETURNING *
        `;

        const result = await pool.query(query, values);

        res.status(200).json({
            success: true,
            message: 'Task updated successfully',
            data: {
                task: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Update task error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update task',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update task status only
 * PATCH /api/tasks/:id/status
 */
const updateTaskStatus = async (req, res) => {
    try {
        const taskId = parseInt(req.params.id);
        const { status, comment } = req.body;

        if (!status) {
            return res.status(400).json({
                success: false,
                message: 'Status is required'
            });
        }

        // Check if task exists
        const checkQuery = 'SELECT id, assigned_to FROM tasks WHERE id = $1';
        const checkResult = await pool.query(checkQuery, [taskId]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Task not found'
            });
        }

        const task = checkResult.rows[0];

        // Check if user is allowed to update status
        if (req.user.role === 'officer' && task.assigned_to !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'You can only update tasks assigned to you'
            });
        }

        const query = `
            UPDATE tasks 
            SET status = $1, updated_at = NOW()
            WHERE id = $2
            RETURNING *
        `;

        const result = await pool.query(query, [status, taskId]);

        res.status(200).json({
            success: true,
            message: 'Task status updated successfully',
            data: {
                task: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Update task status error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update task status',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Delete a task
 * DELETE /api/tasks/:id
 */
const deleteTask = async (req, res) => {
    try {
        const taskId = parseInt(req.params.id);

        const query = 'DELETE FROM tasks WHERE id = $1 RETURNING id';
        const result = await pool.query(query, [taskId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Task not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Task deleted successfully'
        });

    } catch (error) {
        console.error('Delete task error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete task',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

module.exports = {
    getAllTasks,
    getTaskById,
    createTask,
    updateTask,
    updateTaskStatus,
    deleteTask
};