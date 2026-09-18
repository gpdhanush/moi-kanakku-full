const express = require('express');
const { controller } = require('../controllers/appAlertController');
const { authenticateToken, authenticateAdminToken } = require('../middlewares/auth');

const router = express.Router();

// Mobile (logged-in user)
router.get('/active', authenticateToken, controller.getActive);
router.post('/active', authenticateToken, controller.getActive);
router.post('/action', authenticateToken, controller.action);

// Admin
router.post('/admin/create', authenticateAdminToken, controller.create);
router.get('/admin/list', authenticateAdminToken, controller.list);
router.post('/admin/list', authenticateAdminToken, controller.list);
router.post('/admin/update', authenticateAdminToken, controller.update);
router.post('/admin/delete', authenticateAdminToken, controller.remove);

module.exports = router;
