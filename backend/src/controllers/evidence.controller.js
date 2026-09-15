// Import required modules
const path = require('path');
const fs = require('fs');
const pool = require('../config/database');
const {
    upload,
    uploadToCloudinary,
    deleteFromCloudinary,
    cloudinaryConfigured,
} = require('../config/cloudinary');

// Ensure local upload directory exists (fallback)
const UPLOAD_DIR = path.join(__dirname, '../../public/uploads');
if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
    console.log(`📁 Created uploads directory: ${UPLOAD_DIR}`);
}

// ============================================================
// UPLOAD EVIDENCE FOR A REPORT
// POST /api/reports/:id/evidence
// ============================================================
const uploadEvidence = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);
        const userId = req.user?.id;
        const userRole = req.user?.role;

        console.log(`\n📸 Upload evidence request`);
        console.log(`   Report ID: ${reportId}`);
        console.log(`   User: ${userId} (${userRole})`);
        console.log(`   Files received: ${req.files?.length || 0}`);
        console.log(`   Cloudinary configured: ${cloudinaryConfigured}`);

        // ----- 1. Verify report exists -----
        const reportCheck = await pool.query(
            'SELECT user_id, anonymous FROM reports WHERE id = $1',
            [reportId]
        );

        if (reportCheck.rows.length === 0) {
            console.log(`   ❌ Report ${reportId} not found`);
            return res.status(404).json({
                success: false,
                message: 'Report not found.',
            });
        }

        const report = reportCheck.rows[0];

        // ----- 2. Authorization -----
        // Citizens can only upload to their own reports.
        // Admins and officers can upload to any report.
        if (userRole === 'citizen' && report.user_id !== userId) {
            console.log(`   ❌ Access denied (citizen, not owner)`);
            return res.status(403).json({
                success: false,
                message: 'You can only add evidence to your own reports.',
            });
        }

        // ----- 3. Validate files -----
        if (!req.files || req.files.length === 0) {
            console.log(`   ❌ No files uploaded`);
            return res.status(400).json({
                success: false,
                message: 'Please upload at least one file.',
            });
        }

        const maxFiles = parseInt(process.env.MAX_FILES_PER_REPORT) || 5;
        if (req.files.length > maxFiles) {
            console.log(`   ❌ Too many files (max ${maxFiles})`);
            return res.status(400).json({
                success: false,
                message: `You can upload a maximum of ${maxFiles} files.`,
            });
        }

        // ----- 4. Process each file -----
        const saved = [];

        for (const file of req.files) {
            console.log(`\n   📄 Processing: ${file.originalname}`);
            console.log(`      Type: ${file.mimetype}, Size: ${file.size}`);
            console.log(`      Temp path: ${file.path}`);

            let fileUrl = null;
            let publicId = null;
            let uploadedToCloudinary = false;

            // -------- 4a. Try Cloudinary first --------
            if (cloudinaryConfigured) {
                try {
                    const resourceType = file.mimetype.startsWith('video/')
                        ? 'video'
                        : 'image';
                    const result = await uploadToCloudinary(file.path, resourceType);
                    fileUrl = result.secure_url;
                    publicId = result.public_id;
                    uploadedToCloudinary = true;
                    console.log(`      ✅ Cloudinary: ${fileUrl}`);
                } catch (cloudErr) {
                    console.error(`      ⚠️  Cloudinary failed: ${cloudErr.message}`);
                }
            }

            // -------- 4b. Fallback to local storage --------
            if (!uploadedToCloudinary) {
                try {
                    const ext = path.extname(file.originalname);
                    const filename = `${Date.now()}-${Math.random()
                        .toString(36)
                        .substring(2, 8)}${ext}`;
                    const targetPath = path.join(UPLOAD_DIR, filename);

                    // Move from temp to permanent local folder
                    fs.renameSync(file.path, targetPath);

                    fileUrl = `/uploads/${filename}`;
                    publicId = null;
                    console.log(`      📁 Local fallback: ${fileUrl}`);
                } catch (localErr) {
                    console.error(`      ❌ Local save failed: ${localErr.message}`);
                    continue; // Skip this file
                }
            } else {
                // Delete temp file after successful Cloudinary upload
                try {
                    if (fs.existsSync(file.path)) fs.unlinkSync(file.path);
                } catch (unlinkErr) {
                    // Non-fatal
                }
            }

            // -------- 4c. Insert into database --------
            try {
                const insertResult = await pool.query(
                    `INSERT INTO report_evidence 
                        (report_id, file_url, file_type, file_size, public_id)
                     VALUES ($1, $2, $3, $4, $5)
                     RETURNING id, report_id, file_url, file_type, file_size, public_id, created_at`,
                    [reportId, fileUrl, file.mimetype, file.size, publicId]
                );

                saved.push(insertResult.rows[0]);
                console.log(`      ✅ DB record created: ID ${insertResult.rows[0].id}`);
            } catch (dbErr) {
                console.error(`      ❌ DB insert failed: ${dbErr.message}`);
            }
        }

        // ----- 5. Response -----
        if (saved.length === 0) {
            console.log(`\n   ❌ No files were saved successfully\n`);
            return res.status(500).json({
                success: false,
                message: 'Failed to save any files.',
            });
        }

        console.log(`\n🎉 Upload complete: ${saved.length} file(s) saved\n`);

        res.status(201).json({
            success: true,
            message: `Successfully uploaded ${saved.length} file(s).`,
            data: {
                evidence: saved,
            },
        });
    } catch (error) {
        console.error('❌ Upload evidence error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to upload evidence.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined,
        });
    }
};

// ============================================================
// GET ALL EVIDENCE FOR A REPORT
// GET /api/reports/:id/evidence
//
// IMPORTANT: Admin/officer can view evidence for ANY report,
// including reports created by other users.
// ============================================================
const getEvidence = async (req, res) => {
    try {
        const reportId = parseInt(req.params.id);
        const userId = req.user?.id;
        const userRole = req.user?.role;

        console.log(`\n📖 Evidence request`);
        console.log(`   Report ID: ${reportId}`);
        console.log(`   User: ${userId} (${userRole})`);

        // ----- 1. Verify report exists -----
        const reportCheck = await pool.query(
            'SELECT user_id, anonymous FROM reports WHERE id = $1',
            [reportId]
        );

        if (reportCheck.rows.length === 0) {
            console.log(`   ❌ Report not found`);
            return res.status(404).json({
                success: false,
                message: 'Report not found.',
            });
        }

        const reportOwnerId = reportCheck.rows[0].user_id;
        console.log(`   Report owner: ${reportOwnerId}`);

        // ----- 2. Access control -----
        // Admins and officers: see everything.
        // Citizens: only their own reports.
        if (userRole === 'citizen' && reportOwnerId !== userId) {
            console.log(`   ❌ Access denied (citizen, not owner)`);
            return res.status(403).json({
                success: false,
                message: 'You can only view evidence for your own reports.',
            });
        }

        // ----- 3. Fetch evidence (no user filter!) -----
        const result = await pool.query(
            `SELECT id, report_id, file_url, file_type, file_size, public_id, created_at
             FROM report_evidence
             WHERE report_id = $1
             ORDER BY created_at DESC`,
            [reportId]
        );

        console.log(`   ✅ Returning ${result.rows.length} evidence records\n`);

        res.status(200).json({
            success: true,
            data: {
                evidence: result.rows,
            },
        });
    } catch (error) {
        console.error('❌ Get evidence error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get evidence.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined,
        });
    }
};

// ============================================================
// DELETE EVIDENCE
// DELETE /api/evidence/:id
// ============================================================
const deleteEvidence = async (req, res) => {
    try {
        const evidenceId = parseInt(req.params.id);
        const userId = req.user?.id;
        const userRole = req.user?.role;

        console.log(`\n🗑️  Delete evidence ${evidenceId} by ${userId} (${userRole})`);

        // ----- 1. Get evidence details -----
        const evidenceResult = await pool.query(
            `SELECT e.*, r.user_id as report_user_id
             FROM report_evidence e
             JOIN reports r ON e.report_id = r.id
             WHERE e.id = $1`,
            [evidenceId]
        );

        if (evidenceResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Evidence not found.',
            });
        }

        const evidence = evidenceResult.rows[0];

        // ----- 2. Authorization -----
        // Citizens: only their own evidence.
        // Admins and officers: any evidence.
        if (userRole === 'citizen' && evidence.report_user_id !== userId) {
            console.log(`   ❌ Access denied`);
            return res.status(403).json({
                success: false,
                message: 'You can only delete evidence from your own reports.',
            });
        }

        // ----- 3. Delete from Cloudinary (if applicable) -----
        if (evidence.public_id) {
            try {
                await deleteFromCloudinary(evidence.public_id);
                console.log(`   ✅ Deleted from Cloudinary: ${evidence.public_id}`);
            } catch (cloudErr) {
                console.error(`   ⚠️  Cloudinary delete failed: ${cloudErr.message}`);
            }
        }

        // ----- 4. Delete local file (if applicable) -----
        if (evidence.file_url && evidence.file_url.startsWith('/uploads/')) {
            try {
                const localPath = path.join(
                    UPLOAD_DIR,
                    path.basename(evidence.file_url)
                );
                if (fs.existsSync(localPath)) {
                    fs.unlinkSync(localPath);
                    console.log(`   ✅ Deleted local file: ${localPath}`);
                }
            } catch (localErr) {
                console.error(`   ⚠️  Local file delete failed: ${localErr.message}`);
            }
        }

        // ----- 5. Delete from database -----
        await pool.query('DELETE FROM report_evidence WHERE id = $1', [evidenceId]);

        console.log(`   ✅ Evidence deleted from DB\n`);

        res.status(200).json({
            success: true,
            message: 'Evidence deleted successfully.',
        });
    } catch (error) {
        console.error('❌ Delete evidence error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete evidence.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined,
        });
    }
};

// ============================================================
// EXPORTS
// ============================================================
module.exports = {
    uploadEvidence,
    getEvidence,
    deleteEvidence,
};