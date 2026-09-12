const pool = require('../config/database');

async function addDeviceTokensTable() {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS device_tokens (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                token TEXT NOT NULL,
                last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(token, user_id)
            );
        `);
        console.log('✅ device_tokens table created successfully');

        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
            CREATE INDEX IF NOT EXISTS idx_device_tokens_last_used ON device_tokens(last_used);
        `);
        console.log('✅ indexes created successfully');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating device_tokens table:', error.message);
        process.exit(1);
    }
}

addDeviceTokensTable();