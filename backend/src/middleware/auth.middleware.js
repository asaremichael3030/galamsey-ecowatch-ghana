// Import JWT utility functions
const jwtUtils = require('../utils/jwt.utils');
// Import User model to look up user data
const User = require('../models/user.model');

/**
 * Middleware to verify that a user is authenticated
 * This checks if the request has a valid JWT token
 * If valid, it adds the user data to req.user for use in route handlers
 */
const authenticate = async (req, res, next) => {
    try {
        // Get the token from the Authorization header
        const authHeader = req.headers.authorization;
        
        if (!authHeader) {
            return res.status(401).json({
                success: false,
                message: 'No token provided. Please login first.'
            });
        }

        // Check if the header has the correct format: "Bearer <token>"
        const parts = authHeader.split(' ');
        if (parts.length !== 2 || parts[0] !== 'Bearer') {
            return res.status(401).json({
                success: false,
                message: 'Invalid token format. Use: Bearer <token>'
            });
        }

        const token = parts[1];

        // Verify the token
        let decoded;
        try {
            decoded = jwtUtils.verifyToken(token);
        } catch (error) {
            return res.status(401).json({
                success: false,
                message: error.message || 'Invalid or expired token.'
            });
        }

        // Get the user from the database to make sure they still exist and are active
        const user = await User.findById(decoded.id);
        
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'User no longer exists.'
            });
        }

        if (!user.is_active) {
            return res.status(401).json({
                success: false,
                message: 'Account has been deactivated.'
            });
        }

        // Add user data to the request object so route handlers can access it
        req.user = user;
        req.userId = user.id;
        req.userRole = user.role;

        // Continue to the next middleware or route handler
        next();
    } catch (error) {
        console.error('Authentication error:', error);
        return res.status(500).json({
            success: false,
            message: 'Authentication failed due to server error.'
        });
    }
};

/**
 * Middleware to check if the user has one of the allowed roles
 * This is used after authenticate to restrict access based on roles
 * @param {...string} roles - List of allowed roles
 */
const authorize = (...roles) => {
    return (req, res, next) => {
        // Make sure the user is authenticated first
        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: 'User not authenticated.'
            });
        }

        // Check if the user's role is in the allowed roles list
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Access denied. Required role: ${roles.join(' or ')}`
            });
        }

        // User has the required role, continue
        next();
    };
};

/**
 * Middleware to check if the user is accessing their own data
 * This is used for routes like /users/:id where users should only access their own data
 * @param {string} paramName - The name of the parameter containing the user ID (default: 'id')
 */
const isOwnUser = (paramName = 'id') => {
    return (req, res, next) => {
        // Make sure the user is authenticated
        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: 'User not authenticated.'
            });
        }

        // Get the ID from the request parameters
        const requestedId = parseInt(req.params[paramName]);
        
        // If the requested ID doesn't match the logged-in user's ID,
        // check if the user is an admin (admins can access any user)
        if (requestedId !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'You can only access your own data.'
            });
        }

        // User is authorized, continue
        next();
    };
};

/**
 * Middleware to check if the user is an admin
 * This is a convenience shortcut for authorize('admin')
 */
const isAdmin = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({
            success: false,
            message: 'User not authenticated.'
        });
    }

    if (req.user.role !== 'admin') {
        return res.status(403).json({
            success: false,
            message: 'Admin access required.'
        });
    }

    next();
};

/**
 * Middleware to check if the user is an admin or officer
 * This is a convenience shortcut for authorize('admin', 'officer')
 */
const isAdminOrOfficer = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({
            success: false,
            message: 'User not authenticated.'
        });
    }

    if (req.user.role !== 'admin' && req.user.role !== 'officer') {
        return res.status(403).json({
            success: false,
            message: 'Admin or Officer access required.'
        });
    }

    next();
};

// Export all middleware functions
module.exports = {
    authenticate,
    authorize,
    isOwnUser,
    isAdmin,
    isAdminOrOfficer
};