const fs = require('fs');
const path = require('path');

/**
 * Automatically load all route files in this directory
 * This makes it easy to add new routes without manually updating server.js
 */
const loadRoutes = () => {
    const routes = {};
    const routeFiles = fs.readdirSync(__dirname);
    
    // Filter for .js files and exclude index.js itself
    const routeFileNames = routeFiles.filter(file => 
        file.endsWith('.js') && 
        file !== 'index.js' &&
        !file.startsWith('_')
    );
    
    for (const file of routeFileNames) {
        // Remove .js extension to get route name
        const routeName = file.replace('.js', '');
        // Load the route module
        const routeModule = require(`./${file}`);
        routes[routeName] = routeModule;
        console.log(`✅ Loaded route: /api/${routeName}`);
    }
    
    return routes;
};

// Export all routes
module.exports = loadRoutes;