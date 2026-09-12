// Import the database connection
const pool = require('../config/database');

// Report model - contains all database operations for reports
const Report = {
    /**
     * Create a new environmental report
     * @param {Object} reportData - Report information
     * @returns {Object} The created report
     */
    async create(reportData) {
        const {
            user_id,
            report_code,
            title,
            description,
            category_id,
            severity,
            observed_at,
            latitude,
            longitude,
            region,
            district,
            community,
            anonymous = false,
            status = 'pending',
            assigned_to = null
        } = reportData;

        const query = `
            INSERT INTO reports (
                user_id, report_code, title, description, category_id, severity,
                observed_at, latitude, longitude, region, district, community,
                anonymous, status, assigned_to, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, NOW(), NOW())
            RETURNING id, report_code, title, description, category_id, severity,
                      observed_at, latitude, longitude, region, district, community,
                      anonymous, status, assigned_to, created_at, updated_at
        `;

        const values = [
            user_id,
            report_code,
            title,
            description,
            category_id,
            severity,
            observed_at || new Date(),
            latitude || null,
            longitude || null,
            region || null,
            district || null,
            community || null,
            anonymous,
            status,
            assigned_to
        ];

        const result = await pool.query(query, values);
        return result.rows[0];
    },

    /**
     * Find a report by its ID
     * @param {number} id - Report ID
     * @param {number} userId - Optional user ID for access control
     * @returns {Object|null} Report object or null if not found
     */
    async findById(id, userId = null) {
        let query = `
            SELECT r.*, 
                   c.name as category_name,
                   u.full_name as reporter_name,
                   u.email as reporter_email,
                   assigned.full_name as assigned_officer_name
            FROM reports r
            LEFT JOIN report_categories c ON r.category_id = c.id
            LEFT JOIN users u ON r.user_id = u.id
            LEFT JOIN users assigned ON r.assigned_to = assigned.id
            WHERE r.id = $1
        `;
        
        if (userId) {
            query += ` AND (r.user_id = $2 OR r.anonymous = false)`;
            const result = await pool.query(query, [id, userId]);
            return result.rows[0] || null;
        }
        
        const result = await pool.query(query, [id]);
        return result.rows[0] || null;
    },

    /**
     * Find a report by its unique code
     * @param {string} reportCode - Report code (e.g., ECO-2024-000123)
     * @returns {Object|null} Report object or null if not found
     */
    async findByCode(reportCode) {
        const query = `
            SELECT r.*, 
                   c.name as category_name,
                   u.full_name as reporter_name,
                   assigned.full_name as assigned_officer_name
            FROM reports r
            LEFT JOIN report_categories c ON r.category_id = c.id
            LEFT JOIN users u ON r.user_id = u.id
            LEFT JOIN users assigned ON r.assigned_to = assigned.id
            WHERE r.report_code = $1
        `;
        const result = await pool.query(query, [reportCode]);
        return result.rows[0] || null;
    },

    /**
     * Get all reports with filters and pagination
     * @param {Object} options - Filter and pagination options
     * @param {number} userId - Optional user ID for access control
     * @returns {Array} List of reports
     */
    async findAll(options = {}, userId = null) {
        const {
            limit = 20,
            offset = 0,
            status = null,
            category_id = null,
            severity = null,
            region = null,
            search = '',
            sortBy = 'created_at',
            sortOrder = 'DESC'
        } = options;

        let query = `
            SELECT r.id, r.report_code, r.title, r.description, r.severity,
                   r.status, r.observed_at, r.created_at, r.updated_at,
                   r.latitude, r.longitude, r.region, r.district, r.community,
                   r.anonymous, r.category_id, r.assigned_to,
                   c.name as category_name,
                   u.full_name as reporter_name,
                   assigned.full_name as assigned_officer_name
            FROM reports r
            LEFT JOIN report_categories c ON r.category_id = c.id
            LEFT JOIN users u ON r.user_id = u.id
            LEFT JOIN users assigned ON r.assigned_to = assigned.id
            WHERE 1=1
        `;
        const values = [];
        let paramCount = 1;

        if (userId) {
            query += ` AND (r.user_id = $${paramCount} OR r.anonymous = false)`;
            values.push(userId);
            paramCount++;
        }

        if (status) {
            query += ` AND r.status = $${paramCount}`;
            values.push(status);
            paramCount++;
        }

        if (category_id) {
            query += ` AND r.category_id = $${paramCount}`;
            values.push(category_id);
            paramCount++;
        }

        if (severity) {
            query += ` AND r.severity = $${paramCount}`;
            values.push(severity);
            paramCount++;
        }

        if (region) {
            query += ` AND r.region = $${paramCount}`;
            values.push(region);
            paramCount++;
        }

        if (search) {
            query += ` AND (r.title ILIKE $${paramCount} OR r.description ILIKE $${paramCount} OR r.report_code ILIKE $${paramCount})`;
            values.push(`%${search}%`);
            paramCount++;
        }

        const validSortColumns = ['created_at', 'observed_at', 'severity', 'status'];
        const sortColumn = validSortColumns.includes(sortBy) ? sortBy : 'created_at';
        const order = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
        
        query += ` ORDER BY r.${sortColumn} ${order}`;
        query += ` LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
        values.push(limit, offset);

        const result = await pool.query(query, values);
        return result.rows;
    },

    /**
     * Count total reports with filters (for pagination)
     * @param {Object} options - Filter options
     * @param {number} userId - Optional user ID for access control
     * @returns {number} Total count
     */
    async count(options = {}, userId = null) {
        const {
            status = null,
            category_id = null,
            severity = null,
            region = null,
            search = ''
        } = options;

        let query = 'SELECT COUNT(*) FROM reports r WHERE 1=1';
        const values = [];
        let paramCount = 1;

        if (userId) {
            query += ` AND (r.user_id = $${paramCount} OR r.anonymous = false)`;
            values.push(userId);
            paramCount++;
        }

        if (status) {
            query += ` AND r.status = $${paramCount}`;
            values.push(status);
            paramCount++;
        }

        if (category_id) {
            query += ` AND r.category_id = $${paramCount}`;
            values.push(category_id);
            paramCount++;
        }

        if (severity) {
            query += ` AND r.severity = $${paramCount}`;
            values.push(severity);
            paramCount++;
        }

        if (region) {
            query += ` AND r.region = $${paramCount}`;
            values.push(region);
            paramCount++;
        }

        if (search) {
            query += ` AND (r.title ILIKE $${paramCount} OR r.description ILIKE $${paramCount} OR r.report_code ILIKE $${paramCount})`;
            values.push(`%${search}%`);
            paramCount++;
        }

        const result = await pool.query(query, values);
        return parseInt(result.rows[0].count);
    },

    /**
     * Update a report's status
     * @param {number} id - Report ID
     * @param {string} status - New status
     * @param {number} changedBy - User ID of the person making the change
     * @param {string} comment - Optional comment about the status change
     * @returns {Object} Updated report
     */
    async updateStatus(id, status, changedBy, comment = null) {
        const query = `
            UPDATE reports 
            SET status = $1, updated_at = NOW()
            WHERE id = $2
            RETURNING id, report_code, title, status, updated_at
        `;
        const result = await pool.query(query, [status, id]);
        
        // Insert into status history
        if (result.rows.length > 0) {
            const historyQuery = `
                INSERT INTO report_status_history (report_id, previous_status, new_status, changed_by, comment)
                SELECT $1, status, $2, $3, $4
                FROM reports WHERE id = $1
            `;
            await pool.query(historyQuery, [id, status, changedBy, comment]);
        }
        
        return result.rows[0] || null;
    },

    /**
     * Assign an officer to a report
     * @param {number} id - Report ID
     * @param {number} officerId - Officer user ID
     * @param {number} assignedBy - User ID who assigned
     * @returns {Object} Updated report
     */
    async assignOfficer(id, officerId, assignedBy) {
        const query = `
            UPDATE reports 
            SET assigned_to = $1, updated_at = NOW()
            WHERE id = $2
            RETURNING id, report_code, title, assigned_to, updated_at
        `;
        const result = await pool.query(query, [officerId, id]);
        
        if (result.rows.length > 0) {
            // Add to status history
            const historyQuery = `
                INSERT INTO report_status_history (report_id, new_status, changed_by, comment)
                VALUES ($1, $2, $3, $4)
            `;
            await pool.query(historyQuery, [
                id, 
                'assigned', 
                assignedBy, 
                `Assigned to officer ID: ${officerId}`
            ]);
        }
        
        return result.rows[0] || null;
    },

    /**
     * Update a report's details
     * @param {number} id - Report ID
     * @param {Object} updates - Fields to update
     * @returns {Object} Updated report
     */
    async update(id, updates) {
        const fields = [];
        const values = [];
        let paramCount = 1;

        if (updates.title !== undefined) {
            fields.push(`title = $${paramCount}`);
            values.push(updates.title);
            paramCount++;
        }
        if (updates.description !== undefined) {
            fields.push(`description = $${paramCount}`);
            values.push(updates.description);
            paramCount++;
        }
        if (updates.category_id !== undefined) {
            fields.push(`category_id = $${paramCount}`);
            values.push(updates.category_id);
            paramCount++;
        }
        if (updates.severity !== undefined) {
            fields.push(`severity = $${paramCount}`);
            values.push(updates.severity);
            paramCount++;
        }
        if (updates.latitude !== undefined) {
            fields.push(`latitude = $${paramCount}`);
            values.push(updates.latitude);
            paramCount++;
        }
        if (updates.longitude !== undefined) {
            fields.push(`longitude = $${paramCount}`);
            values.push(updates.longitude);
            paramCount++;
        }
        if (updates.region !== undefined) {
            fields.push(`region = $${paramCount}`);
            values.push(updates.region);
            paramCount++;
        }
        if (updates.district !== undefined) {
            fields.push(`district = $${paramCount}`);
            values.push(updates.district);
            paramCount++;
        }
        if (updates.community !== undefined) {
            fields.push(`community = $${paramCount}`);
            values.push(updates.community);
            paramCount++;
        }
        if (updates.assigned_to !== undefined) {
            fields.push(`assigned_to = $${paramCount}`);
            values.push(updates.assigned_to);
            paramCount++;
        }

        fields.push(`updated_at = NOW()`);

        if (fields.length === 0) {
            return null;
        }

        values.push(id);
        const query = `
            UPDATE reports 
            SET ${fields.join(', ')}
            WHERE id = $${paramCount}
            RETURNING id, report_code, title, description, category_id, severity,
                      observed_at, latitude, longitude, region, district, community,
                      anonymous, status, assigned_to, created_at, updated_at
        `;

        const result = await pool.query(query, values);
        return result.rows[0] || null;
    },

    /**
     * Get reports by user ID
     * @param {number} userId - User ID
     * @param {Object} options - Pagination options
     * @returns {Array} List of reports
     */
    async findByUser(userId, options = {}) {
        const { limit = 50, offset = 0 } = options;
        const query = `
            SELECT r.id, r.report_code, r.title, r.severity, r.status,
                   r.observed_at, r.created_at, r.region, r.community,
                   c.name as category_name
            FROM reports r
            LEFT JOIN report_categories c ON r.category_id = c.id
            WHERE r.user_id = $1
            ORDER BY r.created_at DESC
            LIMIT $2 OFFSET $3
        `;
        const result = await pool.query(query, [userId, limit, offset]);
        return result.rows;
    },

    /**
     * Count reports by user ID
     * @param {number} userId - User ID
     * @returns {number} Total count
     */
    async countByUser(userId) {
        const query = 'SELECT COUNT(*) FROM reports WHERE user_id = $1';
        const result = await pool.query(query, [userId]);
        return parseInt(result.rows[0].count);
    },

    /**
     * Get reports by status for a user
     * @param {number} userId - User ID
     * @param {string} status - Report status
     * @returns {number} Count
     */
    async countByStatus(userId, status) {
        const query = `
            SELECT COUNT(*) FROM reports 
            WHERE user_id = $1 AND status = $2
        `;
        const result = await pool.query(query, [userId, status]);
        return parseInt(result.rows[0].count);
    },

    /**
     * Get all reports for map view (limited fields for performance)
     * @param {Object} filters - Filter options
     * @returns {Array} List of reports with location data
     */
    async getMapReports(filters = {}) {
        const { status = null, region = null, severity = null } = filters;

        let query = `
            SELECT id, report_code, title, severity, status,
                   latitude, longitude, region, community,
                   category_id, created_at
            FROM reports
            WHERE latitude IS NOT NULL AND longitude IS NOT NULL
        `;
        const values = [];
        let paramCount = 1;

        if (status) {
            query += ` AND status = $${paramCount}`;
            values.push(status);
            paramCount++;
        }

        if (region) {
            query += ` AND region = $${paramCount}`;
            values.push(region);
            paramCount++;
        }

        if (severity) {
            query += ` AND severity = $${paramCount}`;
            values.push(severity);
            paramCount++;
        }

        query += ` ORDER BY created_at DESC LIMIT 1000`;

        const result = await pool.query(query, values);
        return result.rows;
    },

    /**
     * Get dashboard statistics for admin
     * @returns {Object} Statistics object
     */
    async getStats() {
        const query = `
            SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
                COUNT(CASE WHEN status = 'under_review' THEN 1 END) as under_review,
                COUNT(CASE WHEN status = 'verified' THEN 1 END) as verified,
                COUNT(CASE WHEN status = 'under_investigation' THEN 1 END) as under_investigation,
                COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved,
                COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected,
                COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed
            FROM reports
        `;
        const result = await pool.query(query);
        return result.rows[0];
    },

    /**
     * Get report statistics by category
     * @returns {Array} Category statistics
     */
    async getStatsByCategory() {
        const query = `
            SELECT 
                c.name as category_name,
                c.id as category_id,
                COUNT(r.id) as count
            FROM report_categories c
            LEFT JOIN reports r ON c.id = r.category_id
            GROUP BY c.id, c.name
            ORDER BY count DESC
        `;
        const result = await pool.query(query);
        return result.rows;
    },

    /**
     * Get report statistics by region
     * @returns {Array} Region statistics
     */
    async getStatsByRegion() {
        const query = `
            SELECT 
                region,
                COUNT(*) as count
            FROM reports
            WHERE region IS NOT NULL
            GROUP BY region
            ORDER BY count DESC
        `;
        const result = await pool.query(query);
        return result.rows;
    }
};

// Export the Report model
module.exports = Report;