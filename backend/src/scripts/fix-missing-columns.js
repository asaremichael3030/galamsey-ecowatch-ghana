const pool = require('../config/database');

async function fixMissingColumns() {
    try {
        console.log('🔧 Running comprehensive schema fixes...\n');

        // ============ 1. Add assigned_to to reports ============
        console.log('1️⃣  Fixing reports table...');
        await pool.query(`
            ALTER TABLE reports 
            ADD COLUMN IF NOT EXISTS assigned_to INTEGER REFERENCES users(id)
        `);
        console.log('   ✅ assigned_to column verified on reports\n');

        // ============ 2. Create report_evidence table ============
        console.log('2️⃣  Fixing report_evidence table...');
        await pool.query(`
            CREATE TABLE IF NOT EXISTS report_evidence (
                id SERIAL PRIMARY KEY,
                report_id INTEGER NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
                file_url TEXT NOT NULL,
                file_type VARCHAR(100),
                file_size INTEGER,
                public_id VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log('   ✅ report_evidence table created');

        // Add public_id if the table existed already without it
        await pool.query(`
            ALTER TABLE report_evidence 
            ADD COLUMN IF NOT EXISTS public_id VARCHAR(255)
        `);
        console.log('   ✅ public_id column verified\n');

        // Create indexes
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_report_evidence_report_id 
            ON report_evidence(report_id)
        `);
        console.log('   ✅ report_evidence index created\n');

        // ============ 3. Verify all critical tables exist ============
        console.log('3️⃣  Verifying all tables...');
        const tables = [
            'users', 
            'reports', 
            'report_categories', 
            'report_status_history',
            'report_evidence',
            'notifications',
            'alerts',
            'tasks',
            'education_articles',
            'news',
            'investigations',
            'device_tokens'
        ];

        for (const table of tables) {
            const result = await pool.query(`
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = $1
                )
            `, [table]);
            
            const exists = result.rows[0].exists;
            console.log(`   ${exists ? '✅' : '❌'} ${table}`);
        }

        console.log('\n🎉 All schema fixes completed successfully');
        process.exit(0);
    } catch (error) {
        console.error('\n❌ Error:', error.message);
        process.exit(1);
    }
}

fixMissingColumns();