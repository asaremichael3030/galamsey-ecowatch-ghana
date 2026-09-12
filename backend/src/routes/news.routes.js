const express = require('express');
const router = express.Router();
const newsController = require('../controllers/news.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

// Public routes - anyone can view news
router.get('/', newsController.getAllNews);
router.get('/:id', newsController.getNewsById);

// Admin only routes
router.post('/', authenticate, isAdmin, newsController.createNews);
router.put('/:id', authenticate, isAdmin, newsController.updateNews);
router.delete('/:id', authenticate, isAdmin, newsController.deleteNews);

module.exports = router;