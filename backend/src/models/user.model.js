// Import the database connection
const pool = require('../config/database');

// User model - contains all database operations for users
const User = {
    /**
     * Create a new user in the database
     * @param {Object} userData - User information
     * @returns {Object} The created user (without password)
     */
    async create(userData) {
        const {
            full_name,
            email,
            phone,
            password_hash,
            role = 'citizen',
            region,
            district,
            profile_image
        } = userData;

        // SQL query to insert a new user
        const query = `
            INSERT INTO users (
                full_name, email, phone, password_hash, role, 
                region, district, profile_image, is_active, created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
            RETURNING id, full_name, email, phone, role, region, district, 
                      profile_image, is_active, created_at
        `;

        const values = [
            full_name,
            email.toLowerCase(), // Store email in lowercase for consistency
            phone,
            password_hash,
            role,
            region || null,
            district || null,
            profile_image || null,
            true // is_active defaults to true
        ];

        const result = await pool.query(query, values);
        return result.rows[0];
    },

    /**
     * Find a user by their email address
     * @param {string} email - User's email address
     * @returns {Object|null} User object or null if not found
     */
    async findByEmail(email) {
        const query = `
            SELECT id, full_name, email, phone, password_hash, role, 
                   region, district, profile_image, is_active, created_at, updated_at
            FROM users 
            WHERE email = $1
        `;
        const result = await pool.query(query, [email.toLowerCase()]);
        return result.rows[0] || null;
    },

    /**
     * Find a user by their ID
     * @param {number} id - User's ID
     * @returns {Object|null} User object (without password) or null if not found
     */
    async findById(id) {
        const query = `
            SELECT id, full_name, email, phone, role, region, district, 
                   profile_image, is_active, created_at, updated_at
            FROM users 
            WHERE id = $1
        `;
        const result = await pool.query(query, [id]);
        return result.rows[0] || null;
    },

    /**
     * Find a user by ID including password hash (for login verification)
     * @param {number} id - User's ID
     * @returns {Object|null} User object with password hash or null if not found
     */
    async findByIdWithPassword(id) {
        const query = `
            SELECT id, full_name, email, phone, password_hash, role, 
                   region, district, profile_image, is_active
            FROM users 
            WHERE id = $1
        `;
        const result = await pool.query(query, [id]);
        return result.rows[0] || null;
    },

    /**
     * Update a user's profile information
     * @param {number} id - User's ID
     * @param {Object} updates - Fields to update
     * @returns {Object} Updated user (without password)
     */
    async update(id, updates) {
        // Build the SET clause dynamically based on what fields are provided
        const fields = [];
        const values = [];
        let paramCount = 1;

        // Only add fields that are provided
        if (updates.full_name !== undefined) {
            fields.push(`full_name = $${paramCount}`);
            values.push(updates.full_name);
            paramCount++;
        }
        if (updates.phone !== undefined) {
            fields.push(`phone = $${paramCount}`);
            values.push(updates.phone);
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
        if (updates.profile_image !== undefined) {
            fields.push(`profile_image = $${paramCount}`);
            values.push(updates.profile_image);
            paramCount++;
        }
        if (updates.password_hash !== undefined) {
            fields.push(`password_hash = $${paramCount}`);
            values.push(updates.password_hash);
            paramCount++;
        }
        if (updates.is_active !== undefined) {
            fields.push(`is_active = $${paramCount}`);
            values.push(updates.is_active);
            paramCount++;
        }

        // Always update the updated_at timestamp
        fields.push(`updated_at = NOW()`);

        // If no fields to update, return null
        if (fields.length === 0) {
            return null;
        }

        // Add the ID as the last parameter
        values.push(id);

        const query = `
            UPDATE users 
            SET ${fields.join(', ')}
            WHERE id = $${paramCount}
            RETURNING id, full_name, email, phone, role, region, district, 
                      profile_image, is_active, created_at, updated_at
        `;

        const result = await pool.query(query, values);
        return result.rows[0] || null;
    },

    /**
     * Check if an email is already registered
     * @param {string} email - Email to check
     * @returns {boolean} True if email exists
     */
    async emailExists(email) {
        const query = 'SELECT id FROM users WHERE email = $1';
        const result = await pool.query(query, [email.toLowerCase()]);
        return result.rows.length > 0;
    },

    /**
     * Get all users (for admin dashboard)
     * @param {Object} options - Pagination and filter options
     * @returns {Array} List of users
     */
    async findAll(options = {}) {
        const { limit = 50, offset = 0, role = null, search = '' } = options;

        let query = `
            SELECT id, full_name, email, phone, role, region, district, 
                   profile_image, is_active, created_at
            FROM users 
            WHERE 1=1
        `;
        const values = [];
        let paramCount = 1;

        if (role) {
            query += ` AND role = $${paramCount}`;
            values.push(role);
            paramCount++;
        }

        if (search) {
            query += ` AND (full_name ILIKE $${paramCount} OR email ILIKE $${paramCount})`;
            values.push(`%${search}%`);
            paramCount++;
        }

        query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
        values.push(limit, offset);

        const result = await pool.query(query, values);
        return result.rows;
    },

    /**
     * Count total users (for pagination)
     * @param {Object} options - Filter options
     * @returns {number} Total count
     */
    async count(options = {}) {
        const { role = null, search = '' } = options;

        let query = 'SELECT COUNT(*) FROM users WHERE 1=1';
        const values = [];
        let paramCount = 1;

        if (role) {
            query += ` AND role = $${paramCount}`;
            values.push(role);
            paramCount++;
        }

        if (search) {
            query += ` AND (full_name ILIKE $${paramCount} OR email ILIKE $${paramCount})`;
            values.push(`%${search}%`);
            paramCount++;
        }

        const result = await pool.query(query, values);
        return parseInt(result.rows[0].count);
    },

    /**
     * Delete a user (soft delete - set is_active to false)
     * @param {number} id - User's ID
     * @returns {boolean} True if deleted
     */
    async delete(id) {
        const query = `
            UPDATE users 
            SET is_active = false, updated_at = NOW()
            WHERE id = $1
            RETURNING id
        `;
        const result = await pool.query(query, [id]);
        return result.rows.length > 0;
    }
};

// Export the User model so other files can use it
module.exports = User;