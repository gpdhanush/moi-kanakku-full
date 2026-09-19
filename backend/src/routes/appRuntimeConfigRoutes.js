const express = require('express');
const { appRuntimeConfigController } = require('../controllers/appRuntimeConfigController');
const { authenticateAdminToken } = require('../middlewares/auth');

const router = express.Router();

// Public mobile startup configuration. Never include server secrets here.
router.get('/public', appRuntimeConfigController.getPublic);

// Admin management.
router.get('/admin', authenticateAdminToken, appRuntimeConfigController.getAdmin);
router.put('/admin', authenticateAdminToken, appRuntimeConfigController.updateAdmin);
router.post('/admin', authenticateAdminToken, appRuntimeConfigController.updateAdmin);

module.exports = router;
