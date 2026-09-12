const pool = require('../config/database');

async function addInvestigationsTable() {
    try {
        // Create investigations table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS investigations (
                id SERIAL PRIMARY KEY,
                report_id INTEGER REFERENCES reports(id) ON DELETE CASCADE,
                officer_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
                title VARCHAR(255) NOT NULL,
                findings TEXT,
                notes TEXT,
                recommendation TEXT,
                status VARCHAR(30) DEFAULT 'not_started',
                started_at TIMESTAMP,
                completed_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('✅ investigations table created successfully');

        // Create indexes
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_investigations_status ON investigations(status);
            CREATE INDEX IF NOT EXISTS idx_investigations_officer_id ON investigations(officer_id);
            CREATE INDEX IF NOT EXISTS idx_investigations_report_id ON investigations(report_id);
        `);
        console.log('✅ indexes created successfully');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating investigations table:', error.message);
        process.exit(1);
    }
}

addInvestigationsTable();