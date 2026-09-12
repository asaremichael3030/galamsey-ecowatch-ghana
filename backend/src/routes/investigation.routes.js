const express = require('express');
const router = express.Router();
const investigationController = require('../controllers/investigation.controller');
const { authenticate, isAdmin, isAdminOrOfficer } = require('../middleware/auth.middleware');

// All investigation routes require authentication
router.use(authenticate);

// Get all investigations (admin sees all, officers see assigned)
router.get('/', isAdminOrOfficer, investigationController.getAllInvestigations);

// Get investigation by ID
router.get('/:id', isAdminOrOfficer, investigationController.getInvestigationById);

// Create investigation (admin only)
router.post('/', isAdmin, investigationController.createInvestigation);

// Update investigation (admin only)
router.put('/:id', isAdmin, investigationController.updateInvestigation);

// Update investigation status (admin or assigned officer)
router.patch('/:id/status', isAdminOrOfficer, investigationController.updateInvestigationStatus);

// Delete investigation (admin only)
router.delete('/:id', isAdmin, investigationController.deleteInvestigation);

module.exports = router;