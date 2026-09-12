// Import the JWT library
const jwt = require('jsonwebtoken');

/**
 * Generate a JWT token for a user
 * @param {Object} user - User object containing id, email, and role
 * @returns {string} JWT token
 */
const generateToken = (user) => {
    // Create the payload - the data we want to store in the token
    const payload = {
        id: user.id,
        email: user.email,
        role: user.role
    };

    // Sign the token with our secret key and set expiration
    // The secret key comes from the .env file
    const token = jwt.sign(
        payload,
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    return token;
};

/**
 * Verify a JWT token and return the decoded data
 * @param {string} token - JWT token to verify
 * @returns {Object} Decoded token data (user id, email, role)
 * @throws {Error} If token is invalid or expired
 */
const verifyToken = (token) => {
    try {
        // Verify the token using our secret key
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        return decoded;
    } catch (error) {
        // If token is invalid, throw an error with a clear message
        if (error.name === 'TokenExpiredError') {
            throw new Error('Token has expired. Please login again.');
        }
        if (error.name === 'JsonWebTokenError') {
            throw new Error('Invalid token. Please login again.');
        }
        throw error;
    }
};

/**
 * Decode a JWT token without verifying it (for debugging only)
 * @param {string} token - JWT token
 * @returns {Object|null} Decoded token data or null if invalid
 */
const decodeToken = (token) => {
    try {
        return jwt.decode(token);
    } catch (error) {
        return null;
    }
};

/**
 * Generate a password reset token (short-lived)
 * @param {Object} user - User object
 * @returns {string} Password reset token
 */
const generateResetToken = (user) => {
    const payload = {
        id: user.id,
        email: user.email
    };

    // Reset tokens expire in 1 hour
    const token = jwt.sign(
        payload,
        process.env.JWT_SECRET + user.password_hash, // Add password hash to secret for extra security
        { expiresIn: '1h' }
    );

    return token;
};

/**
 * Verify a password reset token
 * @param {string} token - Reset token
 * @param {string} passwordHash - User's password hash (for extra validation)
 * @returns {Object} Decoded token data
 * @throws {Error} If token is invalid
 */
const verifyResetToken = (token, passwordHash) => {
    try {
        // Verify using the user's password hash as part of the secret
        const decoded = jwt.verify(token, process.env.JWT_SECRET + passwordHash);
        return decoded;
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            throw new Error('Password reset link has expired. Please request a new one.');
        }
        throw new Error('Invalid password reset token.');
    }
};

// Export all functions so other files can use them
module.exports = {
    generateToken,
    verifyToken,
    decodeToken,
    generateResetToken,
    verifyResetToken
};