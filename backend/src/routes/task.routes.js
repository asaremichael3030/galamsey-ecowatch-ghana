const express = require('express');
const router = express.Router();
const taskController = require('../controllers/task.controller');
const { authenticate, isAdmin, isAdminOrOfficer } = require('../middleware/auth.middleware');

// All task routes require authentication
router.use(authenticate);

// Get all tasks (admin sees all, officers see assigned)
router.get('/', isAdminOrOfficer, taskController.getAllTasks);

// Get task by ID
router.get('/:id', isAdminOrOfficer, taskController.getTaskById);

// Create task (admin only)
router.post('/', isAdmin, taskController.createTask);

// Update task (admin only)
router.put('/:id', isAdmin, taskController.updateTask);

// Update task status (admin or assigned officer)
router.patch('/:id/status', isAdminOrOfficer, taskController.updateTaskStatus);

// Delete task (admin only)
router.delete('/:id', isAdmin, taskController.deleteTask);

module.exports = router;