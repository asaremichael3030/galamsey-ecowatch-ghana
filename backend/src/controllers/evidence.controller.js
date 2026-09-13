const path = require('path');
const fs = require('fs');
const pool = require('../config/database');
const {
    upload,
    uploadToCloudinary,
    deleteFromCloudinary,
    cloudinaryConfigured,
} = require('../config/cloudinary');

// ==================== UPLOAD EVIDENCE ====================
const uploadEvidence = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);
        console.log(`\n📸 Upload evidence request for report ${reportId}`);
        console.log(`   User: ${req.user.id} (${req.user.role})`);
        console.log(`   Files received: ${req.files?.length || 0}`);
        console.log(`   Cloudinary configured: ${cloudinaryConfigured}`);

        // Verify report exists
        const reportCheck = await pool.query(
            'SELECT user_id FROM reports WHERE id = $1',
            [reportId]
        );
        if (reportCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Report not found' });
        }

        // Authorization
        if (req.user.role === 'citizen' && reportCheck.rows[0].user_id !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Access denied' });
        }

        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ success: false, message: 'No files uploaded' });
        }

        const saved = [];

        for (const file of req.files) {
            console.log(`\n📄 Processing: ${file.originalname}`);
            console.log(`   Type: ${file.mimetype}, Size: ${file.size}, Path: ${file.path}`);

            let fileUrl = null;
            let publicId = null;
            let usedCloudinary = false;

            // ---- Try Cloudinary first ----
            if (cloudinaryConfigured) {
                try {
                    const resourceType = file.mimetype.startsWith('video/') ? 'video' : 'image';
                    const result = await uploadToCloudinary(file.path, resourceType);
                    fileUrl = result.secure_url;
                    publicId = result.public_id;
                    usedCloudinary = true;
                    console.log(`   ✅ Cloudinary: ${fileUrl}`);
                } catch (cloudError) {
                    console.error(`   ⚠️  Cloudinary failed: ${cloudError.message}`);
                }
            }

            // ---- Fallback to local storage ----
            if (!fileUrl) {
                const uploadDir = path.join(__dirname, '../../public/uploads');
                if (!fs.existsSync(uploadDir)) {
                    fs.mkdirSync(uploadDir, { recursive: true });
                }
                const ext = path.extname(file.originalname);
                const filename = `${Date.now()}-${Math.random().toString(36).substring(2, 8)}${ext}`;
                const targetPath = path.join(uploadDir, filename);

                fs.renameSync(file.path, targetPath);
                fileUrl = `/uploads/${filename}`;
                publicId = null;
                console.log(`   📁 Local fallback: ${fileUrl}`);
            } else {
                // Clean up temp file after successful Cloudinary upload
                try { fs.unlinkSync(file.path); } catch {}
            }

            // ---- Insert into database ----
            const insertResult = await pool.query(
                `INSERT INTO report_evidence 
                    (report_id, file_url, file_type, file_size, public_id)
                 VALUES ($1, $2, $3, $4, $5)
                 RETURNING id, file_url, file_type, public_id, created_at`,
                [reportId, fileUrl, file.mimetype, file.size, publicId]
            );

            saved.push(insertResult.rows[0]);
            console.log(`   ✅ DB record created: ID ${insertResult.rows[0].id}`);
        }

        console.log(`\n🎉 Upload complete: ${saved.length} file(s) saved\n`);

        res.status(201).json({
            success: true,
            message: `Uploaded ${saved.length} file(s)`,
            data: { evidence: saved }
        });

    } catch (error) {
        console.error('❌ Upload error:', error);
        res.status(500).json({
            success: false,
            message: 'Upload failed',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

// ==================== GET EVIDENCE ====================
const getEvidence = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);

        const result = await pool.query(
            `SELECT id, file_url, file_type, file_size, public_id, created_at 
             FROM report_evidence 
             WHERE report_id = $1 
             ORDER BY created_at DESC`,
            [reportId]
        );

        console.log(`📖 Fetched ${result.rows.length} evidence for report ${reportId}`);

        res.status(200).json({
            success: true,
            data: { evidence: result.rows }
        });
    } catch (error) {
        console.error('❌ Get evidence error:', error);
        res.status(500).json({ success: false, message: 'Failed to get evidence' });
    }
};

// ==================== DELETE EVIDENCE ====================
const deleteEvidence = async (req, res) => {
    try {
        const id = parseInt(req.params.id);

        const result = await pool.query(
            'SELECT file_url, public_id FROM report_evidence WHERE id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Evidence not found' });
        }

        const { file_url, public_id } = result.rows[0];

        // Delete from Cloudinary
        if (public_id) {
            await deleteFromCloudinary(public_id);
        }

        // Delete local file if it exists
        if (file_url && file_url.startsWith('/uploads/')) {
            const filePath = path.join(__dirname, '../../public/uploads', path.basename(file_url));
            if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
        }

        await pool.query('DELETE FROM report_evidence WHERE id = $1', [id]);

        res.status(200).json({ success: true, message: 'Evidence deleted' });
    } catch (error) {
        console.error('❌ Delete error:', error);
        res.status(500).json({ success: false, message: 'Delete failed' });
    }
};

module.exports = { uploadEvidence, getEvidence, deleteEvidence };