// Import models
const User = require('../models/user.model');
const Report = require('../models/report.model');
const Notification = require('../models/notification.model');
const Category = require('../models/category.model');

/**
 * Get admin dashboard statistics
 * GET /api/admin/dashboard
 * Requires admin authentication
 */
const getDashboardStats = async (req, res) => {
    try {
        // Get report statistics
        const reportStats = await Report.getStats();
        
        // Get user statistics
        const totalUsers = await User.count({});
        const totalCitizens = await User.count({ role: 'citizen' });
        const totalOfficers = await User.count({ role: 'officer' });
        const totalAdmins = await User.count({ role: 'admin' });
        
        // Get category statistics
        const categoryStats = await Report.getStatsByCategory();
        
        // Get region statistics
        const regionStats = await Report.getStatsByRegion();
        
        // Get recent notifications count
        const recentNotifications = await Notification.countByUser(null, false);
        
        // Get active users (users who have created reports)
        const activeUsersQuery = `
            SELECT COUNT(DISTINCT user_id) as active_users
            FROM reports
            WHERE created_at >= NOW() - INTERVAL '30 days'
        `;
        const pool = require('../config/database');
        const activeResult = await pool.query(activeUsersQuery);
        const activeUsers = parseInt(activeResult.rows[0].active_users);

        // Get reports trend (last 7 days)
        const trendQuery = `
            SELECT 
                DATE(created_at) as date,
                COUNT(*) as count
            FROM reports
            WHERE created_at >= NOW() - INTERVAL '7 days'
            GROUP BY DATE(created_at)
            ORDER BY date ASC
        `;
        const trendResult = await pool.query(trendQuery);
        const trendData = trendResult.rows;

        res.status(200).json({
            success: true,
            data: {
                stats: {
                    total_reports: parseInt(reportStats.total) || 0,
                    pending: parseInt(reportStats.pending) || 0,
                    under_review: parseInt(reportStats.under_review) || 0,
                    verified: parseInt(reportStats.verified) || 0,
                    under_investigation: parseInt(reportStats.under_investigation) || 0,
                    resolved: parseInt(reportStats.resolved) || 0,
                    rejected: parseInt(reportStats.rejected) || 0,
                    closed: parseInt(reportStats.closed) || 0
                },
                users: {
                    total: totalUsers,
                    citizens: totalCitizens,
                    officers: totalOfficers,
                    admins: totalAdmins,
                    active_users: activeUsers
                },
                categories: categoryStats,
                regions: regionStats,
                trend: trendData,
                notifications: {
                    total: recentNotifications
                }
            }
        });

    } catch (error) {
        console.error('Get dashboard stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get dashboard statistics.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get system overview
 * GET /api/admin/overview
 * Requires admin authentication
 */
const getSystemOverview = async (req, res) => {
    try {
        // Get total counts
        const totalReports = await Report.count({});
        const totalUsers = await User.count({});
        const totalCategories = await Category.findAll({ is_active: true });
        
        // Get recent activity
        const recentReports = await Report.findAll({
            limit: 10,
            offset: 0,
            sortBy: 'created_at',
            sortOrder: 'DESC'
        });
        
        // Get recent users
        const recentUsers = await User.findAll({
            limit: 10,
            offset: 0
        });

        res.status(200).json({
            success: true,
            data: {
                totals: {
                    reports: totalReports,
                    users: totalUsers,
                    categories: totalCategories.length
                },
                recent_reports: recentReports,
                recent_users: recentUsers
            }
        });

    } catch (error) {
        console.error('Get system overview error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get system overview.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get weekly report statistics
 * GET /api/admin/weekly-stats
 * Requires admin authentication
 */
const getWeeklyStats = async (req, res) => {
    try {
        const query = `
            SELECT 
                DATE(created_at) as date,
                COUNT(*) as total,
                COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
                COUNT(CASE WHEN status = 'verified' THEN 1 END) as verified,
                COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved
            FROM reports
            WHERE created_at >= NOW() - INTERVAL '7 days'
            GROUP BY DATE(created_at)
            ORDER BY date ASC
        `;
        const pool = require('../config/database');
        const result = await pool.query(query);

        res.status(200).json({
            success: true,
            data: {
                weekly_stats: result.rows
            }
        });

    } catch (error) {
        console.error('Get weekly stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get weekly statistics.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get monthly report statistics
 * GET /api/admin/monthly-stats
 * Requires admin authentication
 */
const getMonthlyStats = async (req, res) => {
    try {
        const query = `
            SELECT 
                DATE_TRUNC('month', created_at) as month,
                COUNT(*) as total,
                COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved,
                COUNT(CASE WHEN status = 'verified' THEN 1 END) as verified
            FROM reports
            WHERE created_at >= NOW() - INTERVAL '6 months'
            GROUP BY DATE_TRUNC('month', created_at)
            ORDER BY month ASC
        `;
        const pool = require('../config/database');
        const result = await pool.query(query);

        res.status(200).json({
            success: true,
            data: {
                monthly_stats: result.rows
            }
        });

    } catch (error) {
        console.error('Get monthly stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get monthly statistics.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get officer performance statistics
 * GET /api/admin/officer-performance
 * Requires admin authentication
 */
const getOfficerPerformance = async (req, res) => {
    try {
        const query = `
            SELECT 
                u.id,
                u.full_name,
                u.email,
                u.region,
                COUNT(r.id) as assigned_reports,
                COUNT(CASE WHEN r.status = 'resolved' THEN 1 END) as resolved_reports,
                COUNT(CASE WHEN r.status = 'under_investigation' THEN 1 END) as investigating,
                AVG(CASE WHEN r.status = 'resolved' AND r.created_at IS NOT NULL THEN 
                    EXTRACT(EPOCH FROM (r.updated_at - r.created_at))/3600 
                END) as avg_resolution_hours
            FROM users u
            LEFT JOIN reports r ON r.assigned_to = u.id
            WHERE u.role = 'officer'
            GROUP BY u.id, u.full_name, u.email, u.region
            ORDER BY resolved_reports DESC
        `;
        const pool = require('../config/database');
        const result = await pool.query(query);

        res.status(200).json({
            success: true,
            data: {
                officers: result.rows
            }
        });

    } catch (error) {
        console.error('Get officer performance error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get officer performance data.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get alerts analytics
 * GET /api/admin/alerts-analytics
 * Requires admin authentication
 */
const getAlertsAnalytics = async (req, res) => {
    try {
        const query = `
            SELECT 
                type,
                COUNT(*) as count,
                DATE(created_at) as date
            FROM notifications
            WHERE type = 'alert'
            GROUP BY type, DATE(created_at)
            ORDER BY date DESC
            LIMIT 30
        `;
        const pool = require('../config/database');
        const result = await pool.query(query);

        res.status(200).json({
            success: true,
            data: {
                alert_analytics: result.rows
            }
        });

    } catch (error) {
        console.error('Get alerts analytics error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get alerts analytics.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

// Export all controller functions
module.exports = {
    getDashboardStats,
    getSystemOverview,
    getWeeklyStats,
    getMonthlyStats,
    getOfficerPerformance,
    getAlertsAnalytics
};