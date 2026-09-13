const pool = require('../config/database');

async function fixNotifications() {
    try {
        console.log('🔧 Fixing notifications table...\n');

        // ============ 1. Create notifications table ============
        console.log('1️⃣  Creating notifications table if missing...');
        await pool.query(`
            CREATE TABLE IF NOT EXISTS notifications (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                title VARCHAR(255) NOT NULL,
                message TEXT NOT NULL,
                type VARCHAR(50) NOT NULL,
                related_id INTEGER,
                related_type VARCHAR(50),
                is_read BOOLEAN DEFAULT false,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log('   ✅ notifications table ready\n');

        // ============ 2. Add any missing columns ============
        console.log('2️⃣  Ensuring all columns exist...');
        
        const columnsToAdd = [
            { name: 'related_id', sql: 'INTEGER' },
            { name: 'related_type', sql: 'VARCHAR(50)' },
            { name: 'is_read', sql: 'BOOLEAN DEFAULT false' },
        ];

        for (const col of columnsToAdd) {
            await pool.query(`
                ALTER TABLE notifications 
                ADD COLUMN IF NOT EXISTS ${col.name} ${col.sql}
            `);
            console.log(`   ✅ ${col.name}`);
        }

        // ============ 3. Create indexes ============
        console.log('\n3️⃣  Creating indexes...');
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_notifications_user_id 
            ON notifications(user_id)
        `);
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_notifications_user_read 
            ON notifications(user_id, is_read)
        `);
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_notifications_created_at 
            ON notifications(created_at DESC)
        `);
        console.log('   ✅ All indexes created\n');

        // ============ 4. Verify ============
        console.log('4️⃣  Verifying table structure...');
        const cols = await pool.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'notifications'
            ORDER BY ordinal_position
        `);
        
        console.log('   Columns:');
        cols.rows.forEach(c => console.log(`     • ${c.column_name} (${c.data_type})`));

        const count = await pool.query('SELECT COUNT(*) FROM notifications');
        console.log(`\n   Total notifications: ${count.rows[0].count}`);

        console.log('\n🎉 Notifications table fixed successfully');
        process.exit(0);
    } catch (error) {
        console.error('\n❌ Error:', error.message);
        process.exit(1);
    }
}

fixNotifications();