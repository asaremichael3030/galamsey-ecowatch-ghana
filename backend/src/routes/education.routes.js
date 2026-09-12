const express = require('express');
const router = express.Router();
const educationController = require('../controllers/education.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

// Public routes - anyone can view education content
router.get('/', educationController.getAllArticles);
router.get('/:id', educationController.getArticleById);
router.get('/category/:category', educationController.getArticlesByCategory);

// Admin only routes
router.post('/', authenticate, isAdmin, educationController.createArticle);
router.put('/:id', authenticate, isAdmin, educationController.updateArticle);
router.delete('/:id', authenticate, isAdmin, educationController.deleteArticle);

module.exports = router;