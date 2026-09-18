const express = require('express');
const router = express.Router();
const { adminControllers } = require('../controllers/adminControllers');
const { backupController } = require('../controllers/backupController');
const { authenticateAdminToken } = require('../middlewares/auth');

// All admin routes require admin authentication

/**
 * GET /apis/admin/otps
 * List all OTPs with user details
 * Query params: ?page=1&limit=25&type=LOGIN&is_used=0
 */
router.get('/otps', authenticateAdminToken, adminControllers.listOTPs);

/**
 * GET /apis/admin/audit-logs
 * List mobile user audit logs
 * Query: ?page=1&limit=25&userId=&action=&q=
 */
router.get('/audit-logs', authenticateAdminToken, adminControllers.listAuditLogs);

/**
 * POST /apis/admin/audit-logs/delete-bulk
 * Body: { ids: number[] }
 */
router.post(
  '/audit-logs/delete-bulk',
  authenticateAdminToken,
  adminControllers.deleteAuditLogsBulk
);

/**
 * DELETE /apis/admin/otps/cleanup
 * Delete expired OTPs (admin maintenance)
 */
router.delete('/otps/cleanup', authenticateAdminToken, adminControllers.deleteExpiredOTPs);
router.post('/otps/clear', authenticateAdminToken, adminControllers.clearOTPs);

/**
 * Database backup (admin only)
 * POST   /apis/admin/database/backup           create + download .sql.gz
 * GET    /apis/admin/database/backups           list saved backups
 * GET    /apis/admin/database/backups/:filename download a saved backup
 * DELETE /apis/admin/database/backups/:filename delete a saved backup
 */
router.post('/database/backup', authenticateAdminToken, backupController.createAndDownload);
router.get('/database/backups', authenticateAdminToken, backupController.list);
router.get('/database/backups/:filename', authenticateAdminToken, backupController.download);
router.delete('/database/backups/:filename', authenticateAdminToken, backupController.remove);

module.exports = router;
