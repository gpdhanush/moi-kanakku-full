const express = require('express');
const { controller } = require('../controllers/exportPayments');
const { authenticateToken, authenticateAdminToken } = require('../middlewares/auth');

const router = express.Router();

// Mobile user endpoints (user id comes from the auth token, never the body)
router.get('/status', authenticateToken, controller.status);
router.post('/submit', authenticateToken, controller.submit);

// Admin review endpoints
router.get('/admin/list', authenticateAdminToken, controller.adminList);
router.post('/admin/review', authenticateAdminToken, controller.adminReview);

module.exports = router;
