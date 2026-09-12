// Import bcrypt for password hashing
const bcrypt = require('bcryptjs');
// Import User model
const User = require('../models/user.model');
// Import Report model for user statistics
const Report = require('../models/report.model');

/**
 * Get the current user's profile
 * GET /api/users/me
 * Requires authentication
 */
const getProfile = async (req, res) => {
    try {
        // req.user is set by the authenticate middleware
        res.status(200).json({
            success: true,
            data: {
                user: req.user
            }
        });

    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get profile.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update the current user's profile
 * PUT /api/users/me
 * Requires authentication
 */
const updateProfile = async (req, res) => {
    try {
        const { full_name, phone, region, district, profile_image } = req.body;
        const userId = req.user.id;

        // Build updates object with only provided fields
        const updates = {};
        if (full_name) updates.full_name = full_name.trim();
        if (phone) updates.phone = phone.trim();
        if (region) updates.region = region.trim();
        if (district) updates.district = district.trim();
        if (profile_image) updates.profile_image = profile_image;

        // Update the user
        const updatedUser = await User.update(userId, updates);

        if (!updatedUser) {
            return res.status(404).json({
                success: false,
                message: 'User not found.'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Profile updated successfully.',
            data: {
                user: updatedUser
            }
        });

    } catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update profile.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Change the current user's password
 * POST /api/users/change-password
 * Requires authentication
 */
const changePassword = async (req, res) => {
    try {
        const { current_password, new_password, confirm_password } = req.body;
        const userId = req.user.id;

        // Validate required fields
        if (!current_password || !new_password || !confirm_password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide current password, new password, and confirmation.'
            });
        }

        // Check if passwords match
        if (new_password !== confirm_password) {
            return res.status(400).json({
                success: false,
                message: 'New passwords do not match.'
            });
        }

        // Validate password strength
        if (new_password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'Password must be at least 6 characters long.'
            });
        }

        // Get the user with password hash
        const user = await User.findByIdWithPassword(userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found.'
            });
        }

        // Verify current password
        const isPasswordValid = await bcrypt.compare(current_password, user.password_hash);
        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Current password is incorrect.'
            });
        }

        // Hash the new password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(new_password, salt);

        // Update the password
        await User.update(userId, { password_hash: password_hash });

        res.status(200).json({
            success: true,
            message: 'Password changed successfully.'
        });

    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to change password.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get user statistics (reports count, etc.)
 * GET /api/users/stats
 * Requires authentication
 */
const getUserStats = async (req, res) => {
    try {
        const userId = req.user.id;

        // Get report statistics for this user
        const totalReports = await Report.countByUser(userId);
        const pendingReports = await Report.countByStatus(userId, 'pending');
        const verifiedReports = await Report.countByStatus(userId, 'verified');
        const resolvedReports = await Report.countByStatus(userId, 'resolved');
        const underReviewReports = await Report.countByStatus(userId, 'under_review');

        res.status(200).json({
            success: true,
            data: {
                stats: {
                    total_reports: totalReports,
                    pending: pendingReports,
                    under_review: underReviewReports,
                    verified: verifiedReports,
                    resolved: resolvedReports
                }
            }
        });

    } catch (error) {
        console.error('Get user stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get user statistics.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

// ==================== ADMIN ONLY CONTROLLERS ====================

/**
 * Get all users (admin only)
 * GET /api/users/admin/all
 * Requires admin authentication
 */
const getAllUsers = async (req, res) => {
    try {
        const { role, search, limit = 50, offset = 0 } = req.query;

        const users = await User.findAll({
            role: role || null,
            search: search || '',
            limit: parseInt(limit),
            offset: parseInt(offset)
        });

        const total = await User.count({
            role: role || null,
            search: search || ''
        });

        res.status(200).json({
            success: true,
            data: {
                users: users,
                pagination: {
                    total: total,
                    limit: parseInt(limit),
                    offset: parseInt(offset),
                    pages: Math.ceil(total / parseInt(limit))
                }
            }
        });

    } catch (error) {
        console.error('Get all users error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch users.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get a user by ID (admin only)
 * GET /api/users/admin/:id
 * Requires admin authentication
 */
const getUserById = async (req, res) => {
    try {
        const userId = parseInt(req.params.id);
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found.'
            });
        }

        res.status(200).json({
            success: true,
            data: {
                user: user
            }
        });

    } catch (error) {
        console.error('Get user by ID error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch user.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Update a user (admin only)
 * PUT /api/users/admin/:id
 * Requires admin authentication
 */
const updateUserByAdmin = async (req, res) => {
    try {
        const userId = parseInt(req.params.id);
        const { full_name, phone, role, region, district, is_active } = req.body;

        // Build updates object
        const updates = {};
        if (full_name) updates.full_name = full_name.trim();
        if (phone) updates.phone = phone.trim();
        if (role) updates.role = role;
        if (region) updates.region = region.trim();
        if (district) updates.district = district.trim();
        if (is_active !== undefined) updates.is_active = is_active;

        const updatedUser = await User.update(userId, updates);

        if (!updatedUser) {
            return res.status(404).json({
                success: false,
                message: 'User not found.'
            });
        }

        res.status(200).json({
            success: true,
            message: 'User updated successfully.',
            data: {
                user: updatedUser
            }
        });

    } catch (error) {
        console.error('Admin update user error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update user.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Delete a user (soft delete - admin only)
 * DELETE /api/users/admin/:id
 * Requires admin authentication
 */
const deleteUser = async (req, res) => {
    try {
        const userId = parseInt(req.params.id);

        // Don't allow deleting yourself
        if (userId === req.user.id) {
            return res.status(400).json({
                success: false,
                message: 'You cannot delete your own account.'
            });
        }

        const deleted = await User.delete(userId);

        if (!deleted) {
            return res.status(404).json({
                success: false,
                message: 'User not found.'
            });
        }

        res.status(200).json({
            success: true,
            message: 'User deactivated successfully.'
        });

    } catch (error) {
        console.error('Delete user error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete user.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Create a new officer (admin only)
 * POST /api/users/admin/officer
 * Requires admin authentication
 */
const createOfficer = async (req, res) => {
    try {
        const { full_name, email, phone, password, region, district } = req.body;

        // Validate required fields
        if (!full_name || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide full name, email, and password.'
            });
        }

        // Validate password strength
        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'Password must be at least 6 characters long.'
            });
        }

        // Check if email already exists
        const emailExists = await User.emailExists(email);
        if (emailExists) {
            return res.status(400).json({
                success: false,
                message: 'Email is already registered.'
            });
        }

        // Hash the password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(password, salt);

        // Create the officer
        const newOfficer = await User.create({
            full_name: full_name.trim(),
            email: email.trim(),
            phone: phone || null,
            password_hash: password_hash,
            role: 'officer',
            region: region || null,
            district: district || null,
            profile_image: null
        });

        res.status(201).json({
            success: true,
            message: 'Officer created successfully.',
            data: {
                user: newOfficer
            }
        });

    } catch (error) {
        console.error('Create officer error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create officer.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

// Export all controller functions
module.exports = {
    getProfile,
    updateProfile,
    changePassword,
    getUserStats,
    getAllUsers,
    getUserById,
    updateUserByAdmin,
    deleteUser,
    createOfficer
};