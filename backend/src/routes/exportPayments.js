const express = require('express');
const { controller } = require('../controllers/exportPayments');
const { authenticateToken, authenticateAdminToken } = require('../middlewares/auth');

const router = express.Router();

// Mobile user endpoints (user id comes from the auth token, never the body)
router.get('/status', authenticateToken, controller.status);
router.post('/submit', authenticateToken, controller.submit);
router.post('/consume', authenticateToken, controller.consume);

// Admin review endpoints
router.get('/admin/list', authenticateAdminToken, controller.adminList);
router.post('/admin/review', authenticateAdminToken, controller.adminReview);
router.get('/admin/settings', authenticateAdminToken, controller.adminGetSettings);
router.put('/admin/settings', authenticateAdminToken, controller.adminSaveSettings);
router.post('/admin/settings/qr', authenticateAdminToken, controller.adminUploadQr);
router.delete('/admin/settings/qr', authenticateAdminToken, controller.adminRemoveQr);

module.exports = router;
