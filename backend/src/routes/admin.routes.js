const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

// All admin routes require authentication and admin role
router.use(authenticate);
router.use(isAdmin);

// Dashboard statistics
router.get('/dashboard', adminController.getDashboardStats);

// System overview
router.get('/overview', adminController.getSystemOverview);

// Weekly statistics
router.get('/weekly-stats', adminController.getWeeklyStats);

// Monthly statistics
router.get('/monthly-stats', adminController.getMonthlyStats);

// Officer performance
router.get('/officer-performance', adminController.getOfficerPerformance);

// Alerts analytics
router.get('/alerts-analytics', adminController.getAlertsAnalytics);

module.exports = router;