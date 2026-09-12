const cloudinary = require('cloudinary').v2;
const multer = require('multer');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Configure Cloudinary
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'demo',
    api_key: process.env.CLOUDINARY_API_KEY || '',
    api_secret: process.env.CLOUDINARY_API_SECRET || '',
});

// Local multer storage (for temporary files before Cloudinary upload)
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        const uploadDir = path.join(__dirname, '../../public/uploads/temp');
        // Create directory if it doesn't exist
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname);
        cb(null, 'evidence-' + uniqueSuffix + ext);
    }
});

// Multer upload configuration
const upload = multer({
    storage: storage,
    limits: {
        fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024, // 10MB
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4', 'video/quicktime'];
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only images and videos are allowed.'), false);
        }
    },
});

// Upload to Cloudinary
const uploadToCloudinary = async (filePath, folder = 'ecowatch_reports') => {
    try {
        // Check if Cloudinary is configured
        if (!process.env.CLOUDINARY_CLOUD_NAME || process.env.CLOUDINARY_CLOUD_NAME === 'demo') {
            console.log('Cloudinary not configured. File saved locally.');
            // Return local file path as URL
            return {
                secure_url: `/uploads/temp/${path.basename(filePath)}`,
                public_id: path.basename(filePath),
                is_local: true
            };
        }
        
        const result = await cloudinary.uploader.upload(filePath, {
            folder: folder,
            transformation: [
                { width: 1200, height: 1200, crop: 'limit' }
            ],
            resource_type: 'auto',
        });
        return result;
    } catch (error) {
        console.error('Cloudinary upload error:', error);
        // Fallback to local storage
        return {
            secure_url: `/uploads/temp/${path.basename(filePath)}`,
            public_id: path.basename(filePath),
            is_local: true
        };
    }
};

// Delete from Cloudinary
const deleteFromCloudinary = async (publicId) => {
    try {
        if (!publicId) return;
        // If it's a local file, just return
        if (publicId.startsWith('evidence-') || !publicId.includes('/')) {
            return { result: 'ok' };
        }
        const result = await cloudinary.uploader.destroy(publicId);
        return result;
    } catch (error) {
        console.error('Cloudinary delete error:', error);
        return { result: 'ok' };
    }
};

// Extract public_id from Cloudinary URL
const extractPublicId = (url) => {
    if (!url) return null;
    // Check if it's a local URL
    if (url.startsWith('/uploads/')) {
        return path.basename(url);
    }
    const parts = url.split('/');
    const filename = parts[parts.length - 1];
    const publicId = filename.split('.')[0];
    return publicId;
};

module.exports = {
    cloudinary,
    upload,
    uploadToCloudinary,
    deleteFromCloudinary,
    extractPublicId,
};