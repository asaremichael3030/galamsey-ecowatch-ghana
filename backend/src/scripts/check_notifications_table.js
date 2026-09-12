const pool = require('../config/database');

async function checkNotificationsTable() {
    try {
        // Check if notifications table exists
        const result = await pool.query(`
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'notifications'
            );
        `);
        
        if (result.rows[0].exists) {
            console.log('✅ notifications table exists');
            
            // Check columns
            const columns = await pool.query(`
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'notifications';
            `);
            console.log('Columns:', columns.rows.map(c => c.column_name).join(', '));
        } else {
            console.log('❌ notifications table does not exist - creating it');
            
            // Create notifications table
            await pool.query(`
                CREATE TABLE IF NOT EXISTS notifications (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                    title VARCHAR(255) NOT NULL,
                    message TEXT NOT NULL,
                    type VARCHAR(50) NOT NULL,
                    related_id INTEGER,
                    related_type VARCHAR(50),
                    is_read BOOLEAN DEFAULT false,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            `);
            console.log('✅ notifications table created');
        }
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error checking notifications table:', error.message);
        process.exit(1);
    }
}

checkNotificationsTable();