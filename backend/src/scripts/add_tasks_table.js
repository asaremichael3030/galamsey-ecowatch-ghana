const pool = require('../config/database');

async function addTasksTable() {
    try {
        // Create tasks table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS tasks (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description TEXT NOT NULL,
                priority VARCHAR(20) DEFAULT 'Medium',
                status VARCHAR(30) DEFAULT 'pending',
                assigned_to INTEGER REFERENCES users(id) ON DELETE SET NULL,
                report_id INTEGER REFERENCES reports(id) ON DELETE SET NULL,
                due_date TIMESTAMP,
                completed_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('✅ tasks table created successfully');

        // Create indexes
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
            CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
            CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
        `);
        console.log('✅ indexes created successfully');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating tasks table:', error.message);
        process.exit(1);
    }
}

addTasksTable();