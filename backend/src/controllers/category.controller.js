const Category = require('../models/category.model');

/**
 * Get all categories
 * GET /api/categories
 */
const getAllCategories = async (req, res) => {
    try {
        const { is_active, search } = req.query;
        const categories = await Category.findAll({
            is_active: is_active !== undefined ? is_active === 'true' : null,
            search: search || ''
        });

        res.status(200).json({
            success: true,
            data: {
                categories: categories
            }
        });

    } catch (error) {
        console.error('Get categories error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch categories.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get category by ID
 * GET /api/categories/:id
 */
const getCategoryById = async (req, res) => {
    try {
        const categoryId = parseInt(req.params.id);
        const category = await Category.findById(categoryId);

        if (!category) {
            return res.status(404).json({
                success: false,
                message: 'Category not found.'
            });
        }

        res.status(200).json({
            success: true,
            data: {
                category: category
            }
        });

    } catch (error) {
        console.error('Get category error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch category.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get categories with report counts
 * GET /api/categories/with-counts
 */
const getCategoriesWithCounts = async (req, res) => {
    try {
        const categories = await Category.getWithReportCount();

        res.status(200).json({
            success: true,
            data: {
                categories: categories
            }
        });

    } catch (error) {
        console.error('Get categories with counts error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch categories with counts.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Create a new category (admin only)
 * POST /api/categories
 */
const createCategory = async (req, res) => {
    try {
        const { name, description, icon } = req.body;

        if (!name) {
            return res.status(400).json({
                success: false,
                message: 'Category name is required.'
            });
        }

        // Check if category already exists
        const existing = await Category.findByName(name);
        if (existing) {
            return res.status(400).json({
                success: false,
                message: 'Category already exists.'
            });
        }

        const category = await Category.create({ name, description, icon });

        res.status(201).json({
            success: true,
            message: 'Category created successfully.',
            data: {
                category: category
            }
        });

    } catch (error) {
        console.error('Create category error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create category.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update a category (admin only)
 * PUT /api/categories/:id
 */
const updateCategory = async (req, res) => {
    try {
        const categoryId = parseInt(req.params.id);
        const { name, description, icon, is_active } = req.body;

        const category = await Category.update(categoryId, {
            name,
            description,
            icon,
            is_active
        });

        if (!category) {
            return res.status(404).json({
                success: false,
                message: 'Category not found.'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Category updated successfully.',
            data: {
                category: category
            }
        });

    } catch (error) {
        console.error('Update category error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update category.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Delete a category (admin only)
 * DELETE /api/categories/:id
 */
const deleteCategory = async (req, res) => {
    try {
        const categoryId = parseInt(req.params.id);
        const deleted = await Category.delete(categoryId);

        if (!deleted) {
            return res.status(404).json({
                success: false,
                message: 'Category not found.'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Category deleted successfully.'
        });

    } catch (error) {
        console.error('Delete category error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete category.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

module.exports = {
    getAllCategories,
    getCategoryById,
    getCategoriesWithCounts,
    createCategory,
    updateCategory,
    deleteCategory
};