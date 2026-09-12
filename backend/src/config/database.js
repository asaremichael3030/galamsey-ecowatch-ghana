// Import the PostgreSQL client library
const { Pool } = require('pg');
// Import dotenv to load environment variables from .env file
require('dotenv').config();

// Determine which configuration to use:
// - If DATABASE_URL is set (Render, Heroku, etc.), use that.
// - Otherwise, fall back to individual DB_* variables for local development.
let poolConfig;

if (process.env.DATABASE_URL) {
    // Production (Render) provides a single DATABASE_URL
    poolConfig = {
        connectionString: process.env.DATABASE_URL,
        // Render's internal database requires SSL when accessed externally,
        // but not internally. Setting rejectUnauthorized to false is safe
        // for Render and many cloud providers.
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    };
    console.log('Using DATABASE_URL for database connection.');
} else {
    // Local development configuration
    poolConfig = {
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        database: process.env.DB_NAME || 'galamsey_ecowatch_db',
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'postgres',
        max: 20, // Maximum number of clients in the pool
        idleTimeoutMillis: 30000, // How long a client can be idle before being closed
        connectionTimeoutMillis: 2000, // How long to wait for a connection
    };
    console.log('Using individual DB_* variables for database connection.');
}

// Create a new connection pool to PostgreSQL
const pool = new Pool(poolConfig);

// Test the database connection when the application starts
pool.connect((err, client, release) => {
    if (err) {
        console.error('Error connecting to the database:', err.stack);
        console.error('Please check your database credentials.');
    } else {
        console.log('Database connected successfully!');
        if (!process.env.DATABASE_URL) {
            console.log(`Connected to database: ${process.env.DB_NAME}`);
        }
        release(); // Release the client back to the pool
    }
});

// Export the pool so other files can use it to run queries
module.exports = pool;