// Import express-validator functions
const { body, param, query, validationResult } = require('express-validator');

/**
 * Middleware to check validation results
 * If there are validation errors, return a 400 response with the errors
 */
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: 'Validation failed',
            errors: errors.array().map(err => ({
                field: err.param,
                message: err.msg
            }))
        });
    }
    next();
};

// ==================== AUTHENTICATION VALIDATION RULES ====================

/**
 * Validation rules for user registration
 */
const registerValidation = [
    body('full_name')
        .notEmpty().withMessage('Full name is required')
        .isLength({ min: 2, max: 100 }).withMessage('Full name must be between 2 and 100 characters')
        .trim(),

    body('email')
        .notEmpty().withMessage('Email is required')
        .isEmail().withMessage('Please provide a valid email address')
        .normalizeEmail()
        .trim(),

    body('password')
        .notEmpty().withMessage('Password is required')
        .isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),

    body('confirm_password')
        .notEmpty().withMessage('Please confirm your password')
        .custom((value, { req }) => value === req.body.password)
        .withMessage('Passwords do not match'),

    body('phone')
        .optional()
        .isLength({ min: 10, max: 15 }).withMessage('Phone number must be between 10 and 15 characters')
        .trim(),

    body('region')
        .optional()
        .trim(),

    body('district')
        .optional()
        .trim()
];

/**
 * Validation rules for user login
 */
const loginValidation = [
    body('email')
        .notEmpty().withMessage('Email is required')
        .isEmail().withMessage('Please provide a valid email address')
        .normalizeEmail()
        .trim(),

    body('password')
        .notEmpty().withMessage('Password is required')
];

/**
 * Validation rules for password change
 */
const changePasswordValidation = [
    body('current_password')
        .notEmpty().withMessage('Current password is required'),

    body('new_password')
        .notEmpty().withMessage('New password is required')
        .isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),

    body('confirm_password')
        .notEmpty().withMessage('Please confirm your new password')
        .custom((value, { req }) => value === req.body.new_password)
        .withMessage('Passwords do not match')
];

/**
 * Validation rules for password reset request
 */
const forgotPasswordValidation = [
    body('email')
        .notEmpty().withMessage('Email is required')
        .isEmail().withMessage('Please provide a valid email address')
        .normalizeEmail()
        .trim()
];

/**
 * Validation rules for password reset
 */
const resetPasswordValidation = [
    body('token')
        .notEmpty().withMessage('Reset token is required'),

    body('new_password')
        .notEmpty().withMessage('New password is required')
        .isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),

    body('confirm_password')
        .notEmpty().withMessage('Please confirm your new password')
        .custom((value, { req }) => value === req.body.new_password)
        .withMessage('Passwords do not match')
];

// ==================== REPORT VALIDATION RULES ====================

/**
 * Validation rules for creating a report
 * Relaxed constraints to accept short but meaningful descriptions
 */
const createReportValidation = [
    body('title')
        .notEmpty().withMessage('Report title is required')
        .isLength({ min: 3, max: 255 }).withMessage('Title must be between 3 and 255 characters')
        .trim(),

    body('description')
        .notEmpty().withMessage('Description is required')
        .isLength({ min: 3 }).withMessage('Description must be at least 3 characters long')
        .trim(),

    body('category_id')
        .notEmpty().withMessage('Category is required')
        .isInt({ min: 1 }).withMessage('Invalid category ID'),

    body('severity')
        .notEmpty().withMessage('Severity is required')
        .isIn(['Low', 'Medium', 'High', 'Critical'])
        .withMessage('Severity must be Low, Medium, High, or Critical'),

    body('observed_at')
        .optional()
        .isISO8601().withMessage('Invalid date format'),

    body('latitude')
        .optional()
        .isFloat({ min: -90, max: 90 }).withMessage('Latitude must be between -90 and 90'),

    body('longitude')
        .optional()
        .isFloat({ min: -180, max: 180 }).withMessage('Longitude must be between -180 and 180'),

    body('region')
        .optional()
        .trim(),

    body('district')
        .optional()
        .trim(),

    body('community')
        .optional()
        .trim(),

    body('anonymous')
        .optional()
        .isBoolean().withMessage('Anonymous must be true or false')
];

/**
 * Validation rules for updating a report status
 */
const updateReportStatusValidation = [
    body('status')
        .notEmpty().withMessage('Status is required')
        .isIn([
            'pending',
            'under_review',
            'verified',
            'under_investigation',
            'resolved',
            'rejected',
            'closed'
        ])
        .withMessage('Invalid status value'),

    body('comment')
        .optional()
        .trim()
];

/**
 * Validation rules for report ID parameter
 */
const reportIdValidation = [
    param('id')
        .notEmpty().withMessage('Report ID is required')
        .isInt({ min: 1 }).withMessage('Invalid report ID')
];

// ==================== USER VALIDATION RULES ====================

/**
 * Validation rules for updating user profile
 */
const updateProfileValidation = [
    body('full_name')
        .optional()
        .isLength({ min: 2, max: 100 }).withMessage('Full name must be between 2 and 100 characters')
        .trim(),

    body('phone')
        .optional()
        .isLength({ min: 10, max: 15 }).withMessage('Phone number must be between 10 and 15 characters')
        .trim(),

    body('region')
        .optional()
        .trim(),

    body('district')
        .optional()
        .trim(),

    body('profile_image')
        .optional()
        .trim()
];

/**
 * Validation rules for creating an officer (admin only)
 */
const createOfficerValidation = [
    body('full_name')
        .notEmpty().withMessage('Full name is required')
        .isLength({ min: 2, max: 100 }).withMessage('Full name must be between 2 and 100 characters')
        .trim(),

    body('email')
        .notEmpty().withMessage('Email is required')
        .isEmail().withMessage('Please provide a valid email address')
        .normalizeEmail()
        .trim(),

    body('password')
        .notEmpty().withMessage('Password is required')
        .isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),

    body('phone')
        .optional()
        .isLength({ min: 10, max: 15 }).withMessage('Phone number must be between 10 and 15 characters')
        .trim(),

    body('region')
        .optional()
        .trim(),

    body('district')
        .optional()
        .trim()
];

// ==================== CATEGORY VALIDATION RULES ====================

/**
 * Validation rules for creating a category (admin only)
 */
const createCategoryValidation = [
    body('name')
        .notEmpty().withMessage('Category name is required')
        .isLength({ min: 2, max: 50 }).withMessage('Category name must be between 2 and 50 characters')
        .trim(),

    body('description')
        .optional()
        .trim(),

    body('icon')
        .optional()
        .trim()
];

/**
 * Validation rules for updating a category (admin only)
 */
const updateCategoryValidation = [
    body('name')
        .optional()
        .isLength({ min: 2, max: 50 }).withMessage('Category name must be between 2 and 50 characters')
        .trim(),

    body('description')
        .optional()
        .trim(),

    body('icon')
        .optional()
        .trim(),

    body('is_active')
        .optional()
        .isBoolean().withMessage('is_active must be true or false')
];

// ==================== PAGINATION VALIDATION ====================

/**
 * Validation rules for pagination query parameters
 */
const paginationValidation = [
    query('limit')
        .optional()
        .isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),

    query('offset')
        .optional()
        .isInt({ min: 0 }).withMessage('Offset must be 0 or greater'),

    query('sortBy')
        .optional()
        .isIn(['created_at', 'updated_at', 'title', 'severity', 'status'])
        .withMessage('Invalid sort field'),

    query('sortOrder')
        .optional()
        .isIn(['ASC', 'DESC']).withMessage('Sort order must be ASC or DESC')
];

// Export all validation rules and the validate middleware
module.exports = {
    validate,
    registerValidation,
    loginValidation,
    changePasswordValidation,
    forgotPasswordValidation,
    resetPasswordValidation,
    createReportValidation,
    updateReportStatusValidation,
    reportIdValidation,
    updateProfileValidation,
    createOfficerValidation,
    createCategoryValidation,
    updateCategoryValidation,
    paginationValidation
};