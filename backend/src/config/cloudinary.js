const cloudinary = require('cloudinary').v2;
const multer = require('multer');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// ============ CONFIGURE CLOUDINARY ============
const cloudinaryConfigured = 
    process.env.CLOUDINARY_CLOUD_NAME &&
    process.env.CLOUDINARY_API_KEY &&
    process.env.CLOUDINARY_API_SECRET;

if (cloudinaryConfigured) {
    cloudinary.config({
        cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
        api_key: process.env.CLOUDINARY_API_KEY,
        api_secret: process.env.CLOUDINARY_API_SECRET,
        secure: true,
    });
    console.log('✅ Cloudinary configured successfully');
} else {
    console.warn('⚠️  Cloudinary credentials missing. Falling back to local storage.');
    console.warn('   Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET');
}

// ============ MULTER TEMPORARY STORAGE ============
// Multer saves to a temp folder first, then we upload to Cloudinary
const tempDir = path.join(__dirname, '../../public/temp');
if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, tempDir),
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname);
        cb(null, `upload-${uniqueSuffix}${ext}`);
    }
});

const upload = multer({
    storage: storage,
    limits: {
        fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024, // 10MB
    },
    fileFilter: (req, file, cb) => {
        const allowed = [
            'image/jpeg', 'image/png', 'image/gif', 'image/webp',
            'video/mp4', 'video/quicktime'
        ];
        if (allowed.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only images and videos allowed.'), false);
        }
    },
});

// ============ UPLOAD TO CLOUDINARY ============
const uploadToCloudinary = async (filePath, resourceType = 'auto') => {
    if (!cloudinaryConfigured) {
        throw new Error('Cloudinary not configured');
    }

    try {
        const result = await cloudinary.uploader.upload(filePath, {
            folder: 'ecowatch_reports',
            resource_type: resourceType,
            transformation: resourceType === 'image' 
                ? [{ width: 1200, height: 1200, crop: 'limit', quality: 'auto' }]
                : undefined,
        });
        return result;
    } catch (error) {
        console.error('Cloudinary upload error:', error.message);
        throw error;
    }
};

// ============ DELETE FROM CLOUDINARY ============
const deleteFromCloudinary = async (publicId) => {
    if (!publicId || !cloudinaryConfigured) return null;
    try {
        return await cloudinary.uploader.destroy(publicId);
    } catch (error) {
        console.error('Cloudinary delete error:', error.message);
        return null;
    }
};

// ============ HELPER: Extract public_id from URL ============
const extractPublicId = (url) => {
    if (!url) return null;
    try {
        // Cloudinary URLs look like:
        // https://res.cloudinary.com/<cloud>/image/upload/v123/ecowatch_reports/abc.jpg
        const parts = url.split('/');
        const uploadIndex = parts.indexOf('upload');
        if (uploadIndex === -1) return null;
        // Skip the version segment (v123...)
        const afterUpload = parts.slice(uploadIndex + 2);
        const filename = afterUpload.join('/').split('.')[0];
        return filename;
    } catch {
        return null;
    }
};

module.exports = {
    cloudinary,
    upload,
    uploadToCloudinary,
    deleteFromCloudinary,
    extractPublicId,
    cloudinaryConfigured,
};