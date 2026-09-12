const pool = require('../config/database');

async function createTables() {
    try {
        // Create users table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                full_name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                phone VARCHAR(20),
                password_hash VARCHAR(255) NOT NULL,
                role VARCHAR(20) DEFAULT 'citizen',
                region VARCHAR(50),
                district VARCHAR(50),
                profile_image TEXT,
                is_active BOOLEAN DEFAULT true,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('✅ Users table created');

        // Create report categories table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS report_categories (
                id SERIAL PRIMARY KEY,
                name VARCHAR(50) NOT NULL UNIQUE,
                description TEXT,
                icon VARCHAR(50),
                is_active BOOLEAN DEFAULT true,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('✅ Report categories table created');

        // Create reports table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS reports (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                report_code VARCHAR(20) UNIQUE NOT NULL,
                title VARCHAR(255) NOT NULL,
                description TEXT NOT NULL,
                category_id INTEGER REFERENCES report_categories(id),
                severity VARCHAR(20) NOT NULL,
                observed_at TIMESTAMP,
                latitude DECIMAL(10, 8),
                longitude DECIMAL(11, 8),
                region VARCHAR(50),
                district VARCHAR(50),
                community VARCHAR(100),
                anonymous BOOLEAN DEFAULT false,
                status VARCHAR(30) DEFAULT 'pending',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('✅ Reports table created');

        // Create report status history table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS report_status_history (
                id SERIAL PRIMARY KEY,
                report_id INTEGER REFERENCES reports(id) ON DELETE CASCADE,
                previous_status VARCHAR(30),
                new_status VARCHAR(30) NOT NULL,
                changed_by INTEGER REFERENCES users(id),
                comment TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('✅ Report status history table created');

        // Insert default categories
        await pool.query(`
            INSERT INTO report_categories (name, description, icon)
            VALUES 
                ('Illegal Excavation', 'Unauthorized digging or mining activities', 'excavation'),
                ('River Pollution', 'Pollution of rivers and water bodies', 'water'),
                ('Forest Destruction', 'Illegal logging or deforestation', 'forest'),
                ('Land Degradation', 'Damage to land and soil', 'land'),
                ('Mercury Use', 'Use of mercury in mining operations', 'toxic'),
                ('Other', 'Other environmental violations', 'other')
            ON CONFLICT (name) DO NOTHING;
        `);
        console.log('✅ Default categories inserted');

        console.log('✅ All tables created successfully');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating tables:', error.message);
        process.exit(1);
    }
}

createTables();