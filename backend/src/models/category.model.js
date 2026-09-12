// Import the database connection
const pool = require('../config/database');

// Category model - contains all database operations for report categories
const Category = {
    /**
     * Get all categories
     * @param {Object} options - Filter options
     * @returns {Array} List of categories
     */
    async findAll(options = {}) {
        const { is_active = null, search = '' } = options;

        let query = 'SELECT * FROM report_categories WHERE 1=1';
        const values = [];
        let paramCount = 1;

        if (is_active !== null) {
            query += ` AND is_active = $${paramCount}`;
            values.push(is_active);
            paramCount++;
        }

        if (search) {
            query += ` AND name ILIKE $${paramCount}`;
            values.push(`%${search}%`);
            paramCount++;
        }

        query += ` ORDER BY name ASC`;

        const result = await pool.query(query, values);
        return result.rows;
    },

    /**
     * Find a category by ID
     * @param {number} id - Category ID
     * @returns {Object|null} Category object or null if not found
     */
    async findById(id) {
        const query = 'SELECT * FROM report_categories WHERE id = $1';
        const result = await pool.query(query, [id]);
        return result.rows[0] || null;
    },

    /**
     * Find a category by name
     * @param {string} name - Category name
     * @returns {Object|null} Category object or null if not found
     */
    async findByName(name) {
        const query = 'SELECT * FROM report_categories WHERE name = $1';
        const result = await pool.query(query, [name]);
        return result.rows[0] || null;
    },

    /**
     * Create a new category (admin only)
     * @param {Object} categoryData - Category information
     * @returns {Object} Created category
     */
    async create(categoryData) {
        const { name, description, icon, is_active = true } = categoryData;

        const query = `
            INSERT INTO report_categories (name, description, icon, is_active)
            VALUES ($1, $2, $3, $4)
            RETURNING id, name, description, icon, is_active, created_at
        `;

        const result = await pool.query(query, [
            name.trim(),
            description || null,
            icon || null,
            is_active
        ]);

        return result.rows[0];
    },

    /**
     * Update a category (admin only)
     * @param {number} id - Category ID
     * @param {Object} updates - Fields to update
     * @returns {Object} Updated category
     */
    async update(id, updates) {
        const fields = [];
        const values = [];
        let paramCount = 1;

        if (updates.name !== undefined) {
            fields.push(`name = $${paramCount}`);
            values.push(updates.name.trim());
            paramCount++;
        }
        if (updates.description !== undefined) {
            fields.push(`description = $${paramCount}`);
            values.push(updates.description);
            paramCount++;
        }
        if (updates.icon !== undefined) {
            fields.push(`icon = $${paramCount}`);
            values.push(updates.icon);
            paramCount++;
        }
        if (updates.is_active !== undefined) {
            fields.push(`is_active = $${paramCount}`);
            values.push(updates.is_active);
            paramCount++;
        }

        if (fields.length === 0) {
            return null;
        }

        values.push(id);
        const query = `
            UPDATE report_categories 
            SET ${fields.join(', ')}
            WHERE id = $${paramCount}
            RETURNING id, name, description, icon, is_active, created_at
        `;

        const result = await pool.query(query, values);
        return result.rows[0] || null;
    },

    /**
     * Delete a category (admin only)
     * @param {number} id - Category ID
     * @returns {boolean} True if deleted
     */
    async delete(id) {
        const query = 'DELETE FROM report_categories WHERE id = $1 RETURNING id';
        const result = await pool.query(query, [id]);
        return result.rows.length > 0;
    },

    /**
     * Get category with report count
     * @returns {Array} Categories with report counts
     */
    async getWithReportCount() {
        const query = `
            SELECT 
                c.id,
                c.name,
                c.description,
                c.icon,
                COUNT(r.id) as report_count
            FROM report_categories c
            LEFT JOIN reports r ON c.id = r.category_id
            WHERE c.is_active = true
            GROUP BY c.id, c.name, c.description, c.icon
            ORDER BY report_count DESC, c.name ASC
        `;
        const result = await pool.query(query);
        return result.rows;
    }
};

// Export the Category model
module.exports = Category;