const express = require('express');
const router = express.Router();
const alertController = require('../controllers/alert.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

// Public routes - anyone can view alerts
router.get('/', alertController.getAllAlerts);
router.get('/:id', alertController.getAlertById);

// Admin only routes
router.post('/', authenticate, isAdmin, alertController.createAlert);
router.put('/:id', authenticate, isAdmin, alertController.updateAlert);
router.patch('/:id', authenticate, isAdmin, alertController.updateAlert);
router.delete('/:id', authenticate, isAdmin, alertController.deleteAlert);

module.exports = router;