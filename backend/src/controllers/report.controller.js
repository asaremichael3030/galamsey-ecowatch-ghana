// Import the Report model
const Report = require('../models/report.model');
// Import the User model (for officer assignment)
const User = require('../models/user.model');
// Import the database connection
const pool = require('../config/database');

/**
 * Create a new environmental report
 * POST /api/reports
 */
const createReport = async (req, res) => {
    try {
        const {
            title,
            description,
            category_id,
            severity,
            observed_at,
            latitude,
            longitude,
            region,
            district,
            community,
            anonymous = false
        } = req.body;

        // Validate required fields
        if (!title || !description || !category_id || !severity) {
            return res.status(400).json({
                success: false,
                message: 'Please provide title, description, category, and severity.'
            });
        }

        // Generate a unique report code
        const year = new Date().getFullYear();
        const count = await Report.count({});
        const reportCode = `ECO-${year}-${String(count + 1).padStart(6, '0')}`;

        // Create the report
        const newReport = await Report.create({
            user_id: req.user.id,
            report_code: reportCode,
            title: title.trim(),
            description: description.trim(),
            category_id: parseInt(category_id),
            severity: severity,
            observed_at: observed_at || new Date(),
            latitude: latitude || null,
            longitude: longitude || null,
            region: region || null,
            district: district || null,
            community: community || null,
            anonymous: anonymous
        });

        // ====== NOTIFICATION: Notify all admins about new report ======
        try {
            // Get all admin users
            const adminQuery = 'SELECT id FROM users WHERE role = $1 AND is_active = true';
            const adminResult = await pool.query(adminQuery, ['admin']);
            
            // Create notification for each admin
            for (const admin of adminResult.rows) {
                await pool.query(`
                    INSERT INTO notifications (user_id, title, message, type, related_id, related_type, is_read, created_at)
                    VALUES ($1, $2, $3, $4, $5, $6, false, NOW())
                `, [
                    admin.id,
                    'New Report Submitted',
                    `A new report "${title}" has been submitted by ${anonymous ? 'Anonymous User' : req.user.full_name}`,
                    'new_report',
                    newReport.id,
                    'report'
                ]);
            }
            console.log(`✅ Notification sent to ${adminResult.rows.length} admins about new report`);
        } catch (notifError) {
            console.error('Error sending admin notification:', notifError);
            // Don't fail the request if notification fails
        }

        res.status(201).json({
            success: true,
            message: 'Report submitted successfully!',
            data: {
                report: newReport
            }
        });

    } catch (error) {
        console.error('Create report error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create report. Please try again.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get all reports with filters
 * GET /api/reports
 */
const getAllReports = async (req, res) => {
    try {
        const {
            status,
            category_id,
            severity,
            region,
            search,
            limit = 20,
            offset = 0,
            sortBy = 'created_at',
            sortOrder = 'DESC'
        } = req.query;

        // Prepare filter options
        const options = {
            status: status || null,
            category_id: category_id ? parseInt(category_id) : null,
            severity: severity || null,
            region: region || null,
            search: search || '',
            limit: parseInt(limit),
            offset: parseInt(offset),
            sortBy: sortBy || 'created_at',
            sortOrder: sortOrder || 'DESC'
        };

        // Get reports - pass userId for access control
        // Regular users only see their own reports (and non-anonymous ones)
        // Admins and officers see all reports
        let userId = null;
        if (req.user.role === 'citizen') {
            userId = req.user.id;
        }

        const reports = await Report.findAll(options, userId);
        const total = await Report.count(options, userId);

        res.status(200).json({
            success: true,
            data: {
                reports: reports,
                pagination: {
                    total: total,
                    limit: options.limit,
                    offset: options.offset,
                    pages: Math.ceil(total / options.limit)
                }
            }
        });

    } catch (error) {
        console.error('Get reports error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch reports.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get a specific report by ID
 * GET /api/reports/:id
 */
const getReportById = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);

        // Check access control
        let userId = null;
        if (req.user.role === 'citizen') {
            userId = req.user.id;
        }

        const report = await Report.findById(reportId, userId);

        if (!report) {
            return res.status(404).json({
                success: false,
                message: 'Report not found or you do not have access to it.'
            });
        }

        // If the report is anonymous and the user is not the owner, hide reporter info
        if (report.anonymous && req.user.role === 'citizen' && report.user_id !== req.user.id) {
            delete report.reporter_name;
            delete report.reporter_email;
            delete report.user_id;
        }

        res.status(200).json({
            success: true,
            data: {
                report: report
            }
        });

    } catch (error) {
        console.error('Get report error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch report details.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get a report by its code (public access)
 * GET /api/reports/code/:code
 */
const getReportByCode = async (req, res) => {
    try {
        const { code } = req.params;
        const report = await Report.findByCode(code);

        if (!report) {
            return res.status(404).json({
                success: false,
                message: 'Report not found.'
            });
        }

        // Only show limited information for public access
        // Remove sensitive information
        delete report.user_id;
        delete report.reporter_name;

        res.status(200).json({
            success: true,
            data: {
                report: report
            }
        });

    } catch (error) {
        console.error('Get report by code error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch report.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update a report
 * PUT /api/reports/:id
 */
const updateReport = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);
        const updates = req.body;

        // Check if report exists and user has access
        const existingReport = await Report.findById(reportId);
        if (!existingReport) {
            return res.status(404).json({
                success: false,
                message: 'Report not found.'
            });
        }

        // Check permissions: only the owner, admin, or officer can update
        if (req.user.role === 'citizen' && existingReport.user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'You can only update your own reports.'
            });
        }

        // Citizens can only update certain fields
        if (req.user.role === 'citizen') {
            // Citizens can't update status, that's for admin/officer
            delete updates.status;
            delete updates.assigned_to;
        }

        // Update the report
        const updatedReport = await Report.update(reportId, updates);

        res.status(200).json({
            success: true,
            message: 'Report updated successfully.',
            data: {
                report: updatedReport
            }
        });

    } catch (error) {
        console.error('Update report error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update report.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Delete a report (admin only)
 * DELETE /api/reports/:id
 */
const deleteReport = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);

        // Check if report exists
        const existingReport = await Report.findById(reportId);
        if (!existingReport) {
            return res.status(404).json({
                success: false,
                message: 'Report not found.'
            });
        }

        // Delete the report
        const deletedReport = await Report.updateStatus(reportId, 'closed', req.user.id, 'Report deleted by admin');

        res.status(200).json({
            success: true,
            message: 'Report deleted successfully.',
            data: {
                report: deletedReport
            }
        });

    } catch (error) {
        console.error('Delete report error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete report.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update report status (admin/officer only)
 * PATCH /api/reports/:id/status
 */
const updateReportStatus = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);
        const { status, comment } = req.body;

        if (!status) {
            return res.status(400).json({
                success: false,
                message: 'Please provide a status.'
            });
        }

        // Validate status
        const validStatuses = ['pending', 'under_review', 'verified', 'under_investigation', 'resolved', 'rejected', 'closed'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid status. Valid statuses: ' + validStatuses.join(', ')
            });
        }

        // Check if report exists and get user_id, title, and report_code
        const reportQuery = 'SELECT user_id, title, report_code FROM reports WHERE id = $1';
        const reportResult = await pool.query(reportQuery, [reportId]);
        
        if (reportResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Report not found.'
            });
        }

        const report = reportResult.rows[0];

        // Update the status
        const updatedReport = await Report.updateStatus(reportId, status, req.user.id, comment || null);

        // ====== NOTIFICATION: Notify report owner about status change ======
        try {
            const statusDisplay = status.split('_').map(word => 
                word[0].toUpperCase() + word.substring(1)
            ).join(' ');
            
            await pool.query(`
                INSERT INTO notifications (user_id, title, message, type, related_id, related_type, is_read, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, false, NOW())
            `, [
                report.user_id,
                'Report Status Updated',
                `Your report "${report.title}" (${report.report_code}) status has been updated to ${statusDisplay}${comment ? `: ${comment}` : ''}`,
                'report_status',
                reportId,
                'report'
            ]);
            console.log(`✅ Notification sent to user ${report.user_id} about report status change`);
        } catch (notifError) {
            console.error('Error sending user notification:', notifError);
            // Don't fail the request if notification fails
        }

        res.status(200).json({
            success: true,
            message: 'Report status updated successfully.',
            data: {
                report: updatedReport
            }
        });

    } catch (error) {
        console.error('Update status error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update report status.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get report status history
 * GET /api/reports/:id/status-history
 */
const getStatusHistory = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);

        // Check if report exists and user has access
        let userId = null;
        if (req.user.role === 'citizen') {
            userId = req.user.id;
        }

        const report = await Report.findById(reportId, userId);
        if (!report) {
            return res.status(404).json({
                success: false,
                message: 'Report not found or you do not have access.'
            });
        }

        // Get status history from database
        const query = `
            SELECT h.*, u.full_name as changed_by_name
            FROM report_status_history h
            LEFT JOIN users u ON h.changed_by = u.id
            WHERE h.report_id = $1
            ORDER BY h.created_at DESC
        `;
        const result = await pool.query(query, [reportId]);

        res.status(200).json({
            success: true,
            data: {
                history: result.rows
            }
        });

    } catch (error) {
        console.error('Get status history error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch status history.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get reports for map view
 * GET /api/reports/map
 */
const getMapReports = async (req, res) => {
    try {
        const { status, region, severity } = req.query;

        const filters = {
            status: status || null,
            region: region || null,
            severity: severity || null
        };

        const reports = await Report.getMapReports(filters);

        res.status(200).json({
            success: true,
            data: {
                reports: reports,
                count: reports.length
            }
        });

    } catch (error) {
        console.error('Get map reports error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch map reports.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get all reports for admin view
 * GET /api/reports/admin/all
 */
const getAdminReports = async (req, res) => {
    try {
        const {
            status,
            category_id,
            severity,
            region,
            search,
            limit = 50,
            offset = 0
        } = req.query;

        const options = {
            status: status || null,
            category_id: category_id ? parseInt(category_id) : null,
            severity: severity || null,
            region: region || null,
            search: search || '',
            limit: parseInt(limit),
            offset: parseInt(offset)
        };

        // Admins and officers see all reports
        const reports = await Report.findAll(options);
        const total = await Report.count(options);

        res.status(200).json({
            success: true,
            data: {
                reports: reports,
                pagination: {
                    total: total,
                    limit: options.limit,
                    offset: options.offset,
                    pages: Math.ceil(total / options.limit)
                }
            }
        });

    } catch (error) {
        console.error('Get admin reports error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch reports.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get dashboard statistics
 * GET /api/reports/stats/dashboard
 */
const getDashboardStats = async (req, res) => {
    try {
        const stats = await Report.getStats();

        // Get additional stats for the dashboard
        const categoryStats = await Report.getStatsByCategory();
        const regionStats = await Report.getStatsByRegion();

        res.status(200).json({
            success: true,
            data: {
                stats: stats,
                categories: categoryStats,
                regions: regionStats
            }
        });

    } catch (error) {
        console.error('Get dashboard stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch dashboard statistics.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get report statistics by category
 * GET /api/reports/stats/categories
 */
const getCategoryStats = async (req, res) => {
    try {
        const stats = await Report.getStatsByCategory();

        res.status(200).json({
            success: true,
            data: {
                categories: stats
            }
        });

    } catch (error) {
        console.error('Get category stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch category statistics.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get report statistics by region
 * GET /api/reports/stats/regions
 */
const getRegionStats = async (req, res) => {
    try {
        const stats = await Report.getStatsByRegion();

        res.status(200).json({
            success: true,
            data: {
                regions: stats
            }
        });

    } catch (error) {
        console.error('Get region stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch region statistics.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Assign officer to a report
 * PATCH /api/reports/:id/assign
 */
const assignOfficer = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);
        const { officer_id } = req.body;

        if (!officer_id) {
            return res.status(400).json({
                success: false,
                message: 'Please provide officer_id.'
            });
        }

        // Check if report exists
        const existingReport = await Report.findById(reportId);
        if (!existingReport) {
            return res.status(404).json({
                success: false,
                message: 'Report not found.'
            });
        }

        // Check if officer exists and has officer role
        const officer = await User.findById(officer_id);
        if (!officer) {
            return res.status(404).json({
                success: false,
                message: 'Officer not found.'
            });
        }

        if (officer.role !== 'officer') {
            return res.status(400).json({
                success: false,
                message: 'The specified user is not an officer.'
            });
        }

        // Assign officer to report
        const updatedReport = await Report.assignOfficer(reportId, officer_id, req.user.id);

        res.status(200).json({
            success: true,
            message: `Officer assigned to report successfully.`,
            data: {
                report: updatedReport
            }
        });

    } catch (error) {
        console.error('Assign officer error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to assign officer.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Add a note to a report (internal use)
 * POST /api/reports/:id/notes
 */
const addReportNote = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);
        const { note } = req.body;

        if (!note) {
            return res.status(400).json({
                success: false,
                message: 'Please provide a note.'
            });
        }

        // Check if report exists
        const existingReport = await Report.findById(reportId);
        if (!existingReport) {
            return res.status(404).json({
                success: false,
                message: 'Report not found.'
            });
        }

        // TODO: Create a report_notes table and insert the note
        // For now, return success

        res.status(200).json({
            success: true,
            message: 'Note added successfully.',
            data: {
                report_id: reportId,
                note: note,
                added_by: req.user.full_name,
                added_at: new Date()
            }
        });

    } catch (error) {
        console.error('Add note error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to add note.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get report notes
 * GET /api/reports/:id/notes
 */
const getReportNotes = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);

        // Check if report exists
        const existingReport = await Report.findById(reportId);
        if (!existingReport) {
            return res.status(404).json({
                success: false,
                message: 'Report not found.'
            });
        }

        // TODO: Fetch notes from report_notes table
        // For now, return empty array

        res.status(200).json({
            success: true,
            data: {
                notes: []
            }
        });

    } catch (error) {
        console.error('Get notes error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch notes.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

// Export all controller functions
module.exports = {
    createReport,
    getAllReports,
    getReportById,
    getReportByCode,
    updateReport,
    deleteReport,
    updateReportStatus,
    getStatusHistory,
    getMapReports,
    getAdminReports,
    getDashboardStats,
    getCategoryStats,
    getRegionStats,
    assignOfficer,
    addReportNote,
    getReportNotes
};