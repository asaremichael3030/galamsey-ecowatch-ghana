const pool = require('../config/database');

async function addEvidenceTable() {
    try {
        // Create report_evidence table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS report_evidence (
                id SERIAL PRIMARY KEY,
                report_id INTEGER NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
                file_url TEXT NOT NULL,
                file_type VARCHAR(100),
                file_size INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('✅ report_evidence table created successfully');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating evidence table:', error.message);
        process.exit(1);
    }
}

addEvidenceTable();