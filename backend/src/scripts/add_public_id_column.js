const pool = require('../config/database');

async function addPublicIdColumn() {
    try {
        // Check if public_id column exists
        const checkQuery = `
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'report_evidence' AND column_name = 'public_id'
        `;
        const checkResult = await pool.query(checkQuery);
        
        if (checkResult.rows.length === 0) {
            // Add public_id column
            await pool.query(`
                ALTER TABLE report_evidence 
                ADD COLUMN public_id VARCHAR(255)
            `);
            console.log('✅ public_id column added to report_evidence table');
        } else {
            console.log('✅ public_id column already exists');
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error adding public_id column:', error.message);
        process.exit(1);
    }
}

addPublicIdColumn();