// Import the database connection
const pool = require('../config/database');

/**
 * Get all news
 * GET /api/news
 */
const getAllNews = async (req, res) => {
    try {
        const { category, published, search } = req.query;

        let query = `
            SELECT n.*, u.full_name as author_name
            FROM news n
            LEFT JOIN users u ON n.author_id = u.id
            WHERE 1=1
        `;
        const values = [];
        let paramCount = 1;

        if (category) {
            query += ` AND n.category = $${paramCount}`;
            values.push(category);
            paramCount++;
        }

        if (published !== undefined) {
            query += ` AND n.published = $${paramCount}`;
            values.push(published === 'true');
            paramCount++;
        }

        if (search) {
            query += ` AND (n.title ILIKE $${paramCount} OR n.content ILIKE $${paramCount})`;
            values.push(`%${search}%`);
            paramCount++;
        }

        query += ' ORDER BY n.created_at DESC';

        const result = await pool.query(query, values);

        res.status(200).json({
            success: true,
            data: {
                news: result.rows
            }
        });

    } catch (error) {
        console.error('Get news error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch news',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get news by ID
 * GET /api/news/:id
 */
const getNewsById = async (req, res) => {
    try {
        const newsId = parseInt(req.params.id);
        const query = `
            SELECT n.*, u.full_name as author_name
            FROM news n
            LEFT JOIN users u ON n.author_id = u.id
            WHERE n.id = $1
        `;
        const result = await pool.query(query, [newsId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'News not found'
            });
        }

        res.status(200).json({
            success: true,
            data: {
                news: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Get news error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch news',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Create news
 * POST /api/news
 */
const createNews = async (req, res) => {
    try {
        const {
            title,
            content,
            category,
            image_url,
            published = false
        } = req.body;

        // Validate required fields
        if (!title || !content) {
            return res.status(400).json({
                success: false,
                message: 'Title and content are required'
            });
        }

        const query = `
            INSERT INTO news (
                title, content, category, image_url,
                published, author_id, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
            RETURNING *
        `;

        const values = [
            title.trim(),
            content.trim(),
            category || 'General',
            image_url || null,
            published,
            req.user.id
        ];

        const result = await pool.query(query, values);

        res.status(201).json({
            success: true,
            message: 'News created successfully',
            data: {
                news: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Create news error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create news',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update news
 * PUT /api/news/:id
 */
const updateNews = async (req, res) => {
    try {
        const newsId = parseInt(req.params.id);
        const {
            title,
            content,
            category,
            image_url,
            published
        } = req.body;

        // Check if news exists
        const checkQuery = 'SELECT id FROM news WHERE id = $1';
        const checkResult = await pool.query(checkQuery, [newsId]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'News not found'
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
        if (content !== undefined) {
            fields.push(`content = $${paramCount}`);
            values.push(content.trim());
            paramCount++;
        }
        if (category !== undefined) {
            fields.push(`category = $${paramCount}`);
            values.push(category);
            paramCount++;
        }
        if (image_url !== undefined) {
            fields.push(`image_url = $${paramCount}`);
            values.push(image_url);
            paramCount++;
        }
        if (published !== undefined) {
            fields.push(`published = $${paramCount}`);
            values.push(published);
            paramCount++;
        }

        if (fields.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No fields to update'
            });
        }

        values.push(newsId);
        const query = `
            UPDATE news 
            SET ${fields.join(', ')}, updated_at = NOW()
            WHERE id = $${paramCount}
            RETURNING *
        `;

        const result = await pool.query(query, values);

        res.status(200).json({
            success: true,
            message: 'News updated successfully',
            data: {
                news: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Update news error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update news',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Delete news
 * DELETE /api/news/:id
 */
const deleteNews = async (req, res) => {
    try {
        const newsId = parseInt(req.params.id);

        const query = 'DELETE FROM news WHERE id = $1 RETURNING id';
        const result = await pool.query(query, [newsId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'News not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'News deleted successfully'
        });

    } catch (error) {
        console.error('Delete news error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete news',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

module.exports = {
    getAllNews,
    getNewsById,
    createNews,
    updateNews,
    deleteNews
};