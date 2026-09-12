const pool = require('../config/database');
const bcrypt = require('bcryptjs');
require('dotenv').config();

async function seedAdmin() {
    try {
        // Check if admin already exists
        const checkQuery = 'SELECT id FROM users WHERE email = $1';
        const checkResult = await pool.query(checkQuery, [process.env.ADMIN_EMAIL || 'admin@ecowatch.gh']);
        
        if (checkResult.rows.length > 0) {
            console.log('Admin user already exists.');
            process.exit(0);
        }

        // Hash the admin password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(process.env.ADMIN_PASSWORD || 'Admin@123456', salt);

        // Create admin user
        const query = `
            INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id, full_name, email, role
        `;
        
        const values = [
            'System Administrator',
            process.env.ADMIN_EMAIL || 'admin@ecowatch.gh',
            '0200000000',
            password_hash,
            'admin',
            true
        ];

        const result = await pool.query(query, values);
        console.log('Admin user created successfully:');
        console.log(result.rows[0]);
        console.log('Password:', process.env.ADMIN_PASSWORD || 'Admin@123456');
        
        process.exit(0);
    } catch (error) {
        console.error('Error creating admin user:', error.message);
        process.exit(1);
    }
}

seedAdmin();