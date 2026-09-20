const express = require('express');
const { controller } = require('../controllers/dashboardController');

const router = express.Router();

// Get dashboard statistics
// GET /dashboard
router.get('/', controller.getDashboard);

// Get detailed dashboard statistics with trends and metrics
// GET /dashboard/detailed
router.get('/detailed', controller.getDashboardDetailed);

// Get user growth, activity, and city analytics
router.get('/analytics', controller.getDashboardAnalytics);

module.exports = router;
