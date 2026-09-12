const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');
const { validate, updateProfileValidation, changePasswordValidation, createOfficerValidation, paginationValidation } = require('../middleware/validation.middleware');

// ==================== USER ROUTES (Authenticated) ====================

// Get current user profile
router.get('/me', authenticate, userController.getProfile);

// Update current user profile
router.put('/me', authenticate, updateProfileValidation, validate, userController.updateProfile);

// Change password
router.post('/change-password', authenticate, changePasswordValidation, validate, userController.changePassword);

// Get user statistics
router.get('/stats', authenticate, userController.getUserStats);

// ==================== ADMIN ROUTES ====================

// Get all users (admin only)
router.get('/admin/all', authenticate, isAdmin, paginationValidation, validate, userController.getAllUsers);

// Get user by ID (admin only)
router.get('/admin/:id', authenticate, isAdmin, userController.getUserById);

// Update user (admin only)
router.put('/admin/:id', authenticate, isAdmin, updateProfileValidation, validate, userController.updateUserByAdmin);

// Delete user (admin only)
router.delete('/admin/:id', authenticate, isAdmin, userController.deleteUser);

// Create officer (admin only)
router.post('/admin/officer', authenticate, isAdmin, createOfficerValidation, validate, userController.createOfficer);

// Test route
router.get('/test', (req, res) => {
    res.json({
        success: true,
        message: 'User routes are working!'
    });
});

module.exports = router;