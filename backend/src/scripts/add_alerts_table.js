const pool = require('../config/database');

async function addAlertsTable() {
    try {
        // Create alerts table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS alerts (
                id SERIAL PRIMARY KEY,
                created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
                title VARCHAR(255) NOT NULL,
                description TEXT NOT NULL,
                category VARCHAR(50) DEFAULT 'General',
                severity VARCHAR(20) DEFAULT 'Medium',
                region VARCHAR(100),
                start_date TIMESTAMP,
                end_date TIMESTAMP,
                is_active BOOLEAN DEFAULT true,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('✅ alerts table created successfully');

        // Create indexes
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_alerts_is_active ON alerts(is_active);
            CREATE INDEX IF NOT EXISTS idx_alerts_created_at ON alerts(created_at DESC);
        `);
        console.log('✅ indexes created successfully');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating alerts table:', error.message);
        process.exit(1);
    }
}

addAlertsTable();