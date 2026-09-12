// Import the database connection
const pool = require('../config/database');

/**
 * Get all education articles
 * GET /api/education
 */
const getAllArticles = async (req, res) => {
    try {
        const { category, published, search } = req.query;

        let query = `
            SELECT e.*, u.full_name as author_name
            FROM education_articles e
            LEFT JOIN users u ON e.created_by = u.id
            WHERE 1=1
        `;
        const values = [];
        let paramCount = 1;

        if (category) {
            query += ` AND e.category = $${paramCount}`;
            values.push(category);
            paramCount++;
        }

        if (published !== undefined) {
            query += ` AND e.published = $${paramCount}`;
            values.push(published === 'true');
            paramCount++;
        }

        if (search) {
            query += ` AND (e.title ILIKE $${paramCount} OR e.description ILIKE $${paramCount})`;
            values.push(`%${search}%`);
            paramCount++;
        }

        query += ' ORDER BY e.created_at DESC';

        const result = await pool.query(query, values);

        res.status(200).json({
            success: true,
            data: {
                articles: result.rows
            }
        });

    } catch (error) {
        console.error('Get articles error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch articles',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get article by ID
 * GET /api/education/:id
 */
const getArticleById = async (req, res) => {
    try {
        const articleId = parseInt(req.params.id);
        const query = `
            SELECT e.*, u.full_name as author_name
            FROM education_articles e
            LEFT JOIN users u ON e.created_by = u.id
            WHERE e.id = $1
        `;
        const result = await pool.query(query, [articleId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Article not found'
            });
        }

        res.status(200).json({
            success: true,
            data: {
                article: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Get article error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch article',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get articles by category
 * GET /api/education/category/:category
 */
const getArticlesByCategory = async (req, res) => {
    try {
        const { category } = req.params;
        const query = `
            SELECT e.*, u.full_name as author_name
            FROM education_articles e
            LEFT JOIN users u ON e.created_by = u.id
            WHERE e.category = $1 AND e.published = true
            ORDER BY e.created_at DESC
        `;
        const result = await pool.query(query, [category]);

        res.status(200).json({
            success: true,
            data: {
                articles: result.rows
            }
        });

    } catch (error) {
        console.error('Get articles by category error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch articles',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Create a new education article
 * POST /api/education
 */
const createArticle = async (req, res) => {
    try {
        const {
            title,
            description,
            content,
            category,
            image_url,
            published = false
        } = req.body;

        // Validate required fields
        if (!title || !description || !content) {
            return res.status(400).json({
                success: false,
                message: 'Title, description, and content are required'
            });
        }

        const query = `
            INSERT INTO education_articles (
                title, description, content, category,
                image_url, published, created_by, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
            RETURNING *
        `;

        const values = [
            title.trim(),
            description.trim(),
            content.trim(),
            category || 'General',
            image_url || null,
            published,
            req.user.id
        ];

        const result = await pool.query(query, values);

        res.status(201).json({
            success: true,
            message: 'Article created successfully',
            data: {
                article: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Create article error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create article',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update an education article
 * PUT /api/education/:id
 */
const updateArticle = async (req, res) => {
    try {
        const articleId = parseInt(req.params.id);
        const {
            title,
            description,
            content,
            category,
            image_url,
            published
        } = req.body;

        // Check if article exists
        const checkQuery = 'SELECT id FROM education_articles WHERE id = $1';
        const checkResult = await pool.query(checkQuery, [articleId]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Article not found'
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

        values.push(articleId);
        const query = `
            UPDATE education_articles 
            SET ${fields.join(', ')}, updated_at = NOW()
            WHERE id = $${paramCount}
            RETURNING *
        `;

        const result = await pool.query(query, values);

        res.status(200).json({
            success: true,
            message: 'Article updated successfully',
            data: {
                article: result.rows[0]
            }
        });

    } catch (error) {
        console.error('Update article error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update article',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Delete an education article
 * DELETE /api/education/:id
 */
const deleteArticle = async (req, res) => {
    try {
        const articleId = parseInt(req.params.id);

        const query = 'DELETE FROM education_articles WHERE id = $1 RETURNING id';
        const result = await pool.query(query, [articleId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Article not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Article deleted successfully'
        });

    } catch (error) {
        console.error('Delete article error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete article',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

module.exports = {
    getAllArticles,
    getArticleById,
    getArticlesByCategory,
    createArticle,
    updateArticle,
    deleteArticle
};