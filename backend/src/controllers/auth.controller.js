// Import bcrypt for password hashing
const bcrypt = require('bcryptjs');
// Import JWT utilities
const jwtUtils = require('../utils/jwt.utils');
// Import User model
const User = require('../models/user.model');

/**
 * Register a new user
 * POST /api/auth/register
 */
const register = async (req, res) => {
    try {
        const { full_name, email, phone, password, confirm_password, region, district } = req.body;

        // Validate required fields
        if (!full_name || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide full name, email, and password.'
            });
        }

        // Check if passwords match
        if (password !== confirm_password) {
            return res.status(400).json({
                success: false,
                message: 'Passwords do not match.'
            });
        }

        // Validate password strength (minimum 6 characters)
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
                message: 'Email is already registered. Please login.'
            });
        }

        // Hash the password using bcrypt
        // The salt rounds determine how secure the hash is (10 is standard)
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(password, salt);

        // Create the user in the database
        const newUser = await User.create({
            full_name: full_name.trim(),
            email: email.trim(),
            phone: phone || null,
            password_hash: password_hash,
            role: 'citizen', // Default role for new registrations
            region: region || null,
            district: district || null,
            profile_image: null
        });

        // Generate a JWT token for the new user
        const token = jwtUtils.generateToken(newUser);

        // Return the user data and token (excluding the password hash)
        res.status(201).json({
            success: true,
            message: 'Registration successful! Welcome to Galamsey EcoWatch Ghana.',
            data: {
                user: {
                    id: newUser.id,
                    full_name: newUser.full_name,
                    email: newUser.email,
                    phone: newUser.phone,
                    role: newUser.role,
                    region: newUser.region,
                    district: newUser.district,
                    profile_image: newUser.profile_image
                },
                token: token
            }
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            message: 'Registration failed. Please try again.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Login a user
 * POST /api/auth/login
 */
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Validate required fields
        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide email and password.'
            });
        }

        // Find the user by email
        const user = await User.findByEmail(email.trim());
        
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password.'
            });
        }

        // Check if the account is active
        if (!user.is_active) {
            return res.status(401).json({
                success: false,
                message: 'Account has been deactivated. Please contact support.'
            });
        }

        // Compare the provided password with the stored hash
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);
        
        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password.'
            });
        }

        // Remove the password hash from the user object before sending response
        delete user.password_hash;

        // Generate a JWT token
        const token = jwtUtils.generateToken(user);

        // Return success with user data and token
        res.status(200).json({
            success: true,
            message: 'Login successful!',
            data: {
                user: user,
                token: token
            }
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Login failed. Please try again.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Get the currently authenticated user's profile
 * GET /api/auth/me
 * Requires authentication
 */
const getCurrentUser = async (req, res) => {
    try {
        // req.user is set by the authenticate middleware
        res.status(200).json({
            success: true,
            data: {
                user: req.user
            }
        });

    } catch (error) {
        console.error('Get current user error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get user data.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Logout a user (client-side only - just invalidate token)
 * POST /api/auth/logout
 * This is mostly a client-side operation, but we provide the endpoint
 */
const logout = async (req, res) => {
    try {
        // The actual logout happens on the client side by removing the token
        // This endpoint just confirms the logout
        res.status(200).json({
            success: true,
            message: 'Logout successful.'
        });

    } catch (error) {
        console.error('Logout error:', error);
        res.status(500).json({
            success: false,
            message: 'Logout failed.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Request a password reset
 * POST /api/auth/forgot-password
 */
const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                success: false,
                message: 'Please provide your email address.'
            });
        }

        // Find the user by email
        const user = await User.findByEmail(email.trim());
        
        if (!user) {
            // Don't reveal if email exists or not for security
            return res.status(200).json({
                success: true,
                message: 'If your email is registered, you will receive a password reset link.'
            });
        }

        // Generate a password reset token
        const resetToken = jwtUtils.generateResetToken(user);

        // In a production app, you would send this token via email
        // For now, we'll return it in the response (for testing)
        console.log(`Password reset token for ${email}: ${resetToken}`);

        // TODO: Send email with reset link
        // For now, just return success
        res.status(200).json({
            success: true,
            message: 'Password reset instructions have been sent to your email.',
            // Only include token in development for testing
            ...(process.env.NODE_ENV === 'development' && { resetToken: resetToken })
        });

    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to process password reset request.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Reset password using a token
 * POST /api/auth/reset-password
 */
const resetPassword = async (req, res) => {
    try {
        const { token, new_password, confirm_password } = req.body;

        if (!token || !new_password || !confirm_password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide token, new password, and confirmation.'
            });
        }

        if (new_password !== confirm_password) {
            return res.status(400).json({
                success: false,
                message: 'Passwords do not match.'
            });
        }

        if (new_password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'Password must be at least 6 characters long.'
            });
        }

        // First, decode the token to get the user ID without verifying
        // (we need the user's password hash to verify the token)
        const decoded = jwtUtils.decodeToken(token);
        
        if (!decoded || !decoded.id) {
            return res.status(400).json({
                success: false,
                message: 'Invalid reset token.'
            });
        }

        // Get the user with password hash
        const user = await User.findByIdWithPassword(decoded.id);
        
        if (!user) {
            return res.status(400).json({
                success: false,
                message: 'Invalid reset token.'
            });
        }

        // Verify the token using the user's password hash
        try {
            jwtUtils.verifyResetToken(token, user.password_hash);
        } catch (error) {
            return res.status(400).json({
                success: false,
                message: error.message || 'Invalid or expired reset token.'
            });
        }

        // Hash the new password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(new_password, salt);

        // Update the user's password
        await User.update(user.id, { password_hash: password_hash });

        res.status(200).json({
            success: true,
            message: 'Password has been reset successfully. Please login with your new password.'
        });

    } catch (error) {
        console.error('Reset password error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to reset password.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

// Export all controller functions
module.exports = {
    register,
    login,
    getCurrentUser,
    logout,
    forgotPassword,
    resetPassword
};