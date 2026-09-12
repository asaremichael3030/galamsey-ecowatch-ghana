// Import the Express framework
const express = require('express');
// Import CORS to allow cross-origin requests from our Flutter app
const cors = require('cors');
// Import helmet for security headers
const helmet = require('helmet');
// Import dotenv to load environment variables
require('dotenv').config();

// Import the database connection
const pool = require('./config/database');

// Import routes
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const reportRoutes = require('./routes/report.routes');
const categoryRoutes = require('./routes/category.routes');
const notificationRoutes = require('./routes/notification.routes');
const adminRoutes = require('./routes/admin.routes');
const alertRoutes = require('./routes/alert.routes');
const taskRoutes = require('./routes/task.routes');
const educationRoutes = require('./routes/education.routes');
const newsRoutes = require('./routes/news.routes');
const investigationRoutes = require('./routes/investigation.routes');

// Create the Express application
const app = express();

// Get the port from environment variables or use 5000 as default
const PORT = process.env.PORT || 5000;

// ==================== MIDDLEWARE ====================

// Security middleware - adds various security headers
app.use(helmet());

// Enable CORS - allows our Flutter app to communicate with this API
app.use(cors({
    origin: [
        'http://localhost:3000',
        'http://127.0.0.1:3000',
        'http://localhost:5000',
        'http://127.0.0.1:5000',
        '*'
    ],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
        'Content-Type',
        'Authorization',
        'Accept',
        'Origin',
        'X-Requested-With'
    ]
}));

// Parse JSON request bodies
app.use(express.json({ limit: '10mb' }));

// Parse URL-encoded request bodies
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files from public directory (for uploaded evidence)
app.use('/uploads', express.static('public/uploads'));

// ==================== ROUTES ====================

// Health check route
app.get('/api/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Galamsey EcoWatch Ghana API is running',
        timestamp: new Date().toISOString()
    });
});

// Public route - welcome message
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'Welcome to Galamsey EcoWatch Ghana API',
        version: '1.0.0'
    });
});

// Register all route modules
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/education', educationRoutes);
app.use('/api/news', newsRoutes);
app.use('/api/investigations', investigationRoutes);

// ==================== ERROR HANDLING ====================

// 404 handler - for routes that don't exist
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found'
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Error:', err.stack);
    
    const statusCode = err.statusCode || 500;
    
    res.status(statusCode).json({
        success: false,
        message: err.message || 'Something went wrong on the server',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// ==================== START SERVER ====================

app.listen(PORT, () => {
    console.log('========================================');
    console.log(`Server is running on port ${PORT}`);
    console.log(`API URL: http://localhost:${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/api/health`);
    console.log('========================================');
    console.log('Galamsey EcoWatch Ghana API is ready!');
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log('========================================');
});

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('Shutting down server gracefully...');
    pool.end(() => {
        console.log('Database connections closed.');
        process.exit(0);
    });
});