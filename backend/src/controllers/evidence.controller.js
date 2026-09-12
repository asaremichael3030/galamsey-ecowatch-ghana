// Import required modules
const path = require('path');
const fs = require('fs');
const pool = require('../config/database');
const { upload } = require('../config/cloudinary');

/**
 * Upload evidence for a report - SIMPLIFIED LOCAL STORAGE ONLY
 * POST /api/reports/:id/evidence
 */
const uploadEvidence = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);
        console.log(`📸 Uploading evidence for report: ${reportId}`);

        // Check report exists
        const reportResult = await pool.query('SELECT user_id FROM reports WHERE id = $1', [reportId]);
        if (reportResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Report not found.' });
        }

        // Check authorization
        if (req.user.role === 'citizen' && reportResult.rows[0].user_id !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Access denied.' });
        }

        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ success: false, message: 'No files uploaded.' });
        }

        // Create uploads directory
        const uploadDir = path.join(__dirname, '../../public/uploads');
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }

        const saved = [];
        for (const file of req.files) {
            // Generate unique filename
            const ext = path.extname(file.originalname);
            const filename = `${Date.now()}-${Math.random().toString(36).substring(2, 8)}${ext}`;
            const localPath = path.join(uploadDir, filename);
            
            // Move file
            fs.renameSync(file.path, localPath);
            
            // URL to serve
            const fileUrl = `/uploads/${filename}`;

            // Save to DB
            const result = await pool.query(
                `INSERT INTO report_evidence (report_id, file_url, file_type, file_size)
                 VALUES ($1, $2, $3, $4)
                 RETURNING id, file_url`,
                [reportId, fileUrl, file.mimetype, file.size]
            );
            saved.push(result.rows[0]);
            console.log(`✅ Saved: ${fileUrl}`);
        }

        res.status(201).json({
            success: true,
            message: `Uploaded ${saved.length} file(s).`,
            data: { evidence: saved }
        });

    } catch (error) {
        console.error('Upload error:', error);
        res.status(500).json({ success: false, message: 'Upload failed.' });
    }
};

/**
 * Get evidence for a report
 * GET /api/reports/:id/evidence
 */
const getEvidence = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);
        const result = await pool.query(
            'SELECT id, file_url, file_type, file_size, created_at FROM report_evidence WHERE report_id = $1',
            [reportId]
        );
        res.status(200).json({
            success: true,
            data: { evidence: result.rows }
        });
    } catch (error) {
        console.error('Get evidence error:', error);
        res.status(500).json({ success: false, message: 'Failed to get evidence.' });
    }
};

/**
 * Delete evidence
 * DELETE /api/evidence/:id
 */
const deleteEvidence = async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        await pool.query('DELETE FROM report_evidence WHERE id = $1', [id]);
        res.status(200).json({ success: true, message: 'Deleted.' });
    } catch (error) {
        console.error('Delete error:', error);
        res.status(500).json({ success: false, message: 'Delete failed.' });
    }
};

module.exports = { uploadEvidence, getEvidence, deleteEvidence };