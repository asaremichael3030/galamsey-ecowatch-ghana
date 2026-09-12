const express = require('express');
const router = express.Router();
const reportController = require('../controllers/report.controller');
const evidenceController = require('../controllers/evidence.controller');
const { authenticate, isAdmin, isAdminOrOfficer } = require('../middleware/auth.middleware');
const { 
    validate, 
    createReportValidation, 
    updateReportStatusValidation,
    reportIdValidation,
    paginationValidation 
} = require('../middleware/validation.middleware');

// Import Cloudinary upload configuration
const { upload } = require('../config/cloudinary');

// ==================== PUBLIC ROUTES ====================
// (No authentication required)

// Test route to verify reports routes are working
router.get('/test', (req, res) => {
    res.json({
        success: true,
        message: 'Report routes are working!'
    });
});

// Get reports for map view (public)
router.get('/map', reportController.getMapReports);

// Get report by code (public - but hides sensitive info)
router.get('/code/:code', reportController.getReportByCode);

// ==================== PROTECTED ROUTES ====================
// (Authentication required)

// Create a new report - citizens can create reports
router.post('/', authenticate, createReportValidation, validate, reportController.createReport);

// Get all reports with filters - citizens see their own, admins/officers see all
router.get('/', authenticate, paginationValidation, validate, reportController.getAllReports);

// Get a specific report by ID - users can see their own, admins/officers can see all
router.get('/:id', authenticate, reportIdValidation, validate, reportController.getReportById);

// Update a report - only the owner or admin/officer can update
router.put('/:id', authenticate, reportIdValidation, validate, reportController.updateReport);

// Delete a report - only admin can delete
router.delete('/:id', authenticate, reportIdValidation, validate, isAdmin, reportController.deleteReport);

// Update report status - admins and officers can update status
router.patch('/:id/status', authenticate, reportIdValidation, validate, isAdminOrOfficer, updateReportStatusValidation, validate, reportController.updateReportStatus);

// Get report status history
router.get('/:id/status-history', authenticate, reportIdValidation, validate, reportController.getStatusHistory);

// ==================== EVIDENCE ROUTES ====================

// Upload evidence for a report using Cloudinary - owner or admin/officer
router.post('/:id/evidence', 
    authenticate, 
    reportIdValidation, 
    validate,
    upload.array('evidence', 5),
    evidenceController.uploadEvidence
);

// Get all evidence for a report
router.get('/:id/evidence', authenticate, reportIdValidation, validate, evidenceController.getEvidence);

// Delete evidence - owner or admin
router.delete('/evidence/:id', authenticate, evidenceController.deleteEvidence);

// ==================== ADMIN/REPORT MANAGEMENT ROUTES ====================

// Get all reports for admin/officer view with advanced filtering
router.get('/admin/all', authenticate, isAdminOrOfficer, paginationValidation, validate, reportController.getAdminReports);

// Get report statistics for dashboard
router.get('/stats/dashboard', authenticate, isAdminOrOfficer, reportController.getDashboardStats);

// Get reports by category for analytics
router.get('/stats/categories', authenticate, isAdminOrOfficer, reportController.getCategoryStats);

// Get reports by region for analytics
router.get('/stats/regions', authenticate, isAdminOrOfficer, reportController.getRegionStats);

// Assign officer to a report
router.patch('/:id/assign', authenticate, reportIdValidation, validate, isAdminOrOfficer, reportController.assignOfficer);

// Add note to a report (internal use)
router.post('/:id/notes', authenticate, reportIdValidation, validate, isAdminOrOfficer, reportController.addReportNote);

// Get report notes
router.get('/:id/notes', authenticate, reportIdValidation, validate, isAdminOrOfficer, reportController.getReportNotes);

module.exports = router;