// Import the PostgreSQL client library
const { Pool } = require('pg');
// Import dotenv to load environment variables from .env file
require('dotenv').config();

// Create a new connection pool to PostgreSQL
// A pool manages multiple database connections efficiently
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'galamsey_ecowatch_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    max: 20, // Maximum number of clients in the pool
    idleTimeoutMillis: 30000, // How long a client can be idle before being closed
    connectionTimeoutMillis: 2000, // How long to wait for a connection
});

// Test the database connection when the application starts
pool.connect((err, client, release) => {
    if (err) {
        // If there's an error connecting, log it with details
        console.error('Error connecting to the database:', err.stack);
        console.error('Please check your database credentials in .env file');
        console.error('Make sure PostgreSQL is running on your computer');
        return;
    }
    // If connection is successful, log a success message
    console.log('Database connected successfully!');
    console.log(`Connected to database: ${process.env.DB_NAME}`);
    release(); // Release the client back to the pool
});

// Export the pool so other files can use it to run queries
module.exports = pool;