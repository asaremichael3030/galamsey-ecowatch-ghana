const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/category.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

// Public routes - anyone can view categories
router.get('/', categoryController.getAllCategories);
router.get('/:id', categoryController.getCategoryById);
router.get('/with-counts', categoryController.getCategoriesWithCounts);

// Admin only routes
router.post('/', authenticate, isAdmin, categoryController.createCategory);
router.put('/:id', authenticate, isAdmin, categoryController.updateCategory);
router.delete('/:id', authenticate, isAdmin, categoryController.deleteCategory);

module.exports = router;