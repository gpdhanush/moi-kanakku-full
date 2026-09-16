const express = require('express');
const router = express.Router();
const FranchiseController = require('../controllers/franchiseController');
const { authenticateToken, authenticateAdminToken } = require('../middlewares/auth');
const {
  resolveFranchiseContext,
  requireSuperAdmin,
  requireFranchiseAdmin,
  requireStaffFunctionPermission
} = require('../middlewares/franchiseAuth');

// ========================================================
// SUPER ADMIN ROUTES (Requires Admin Token + Super Admin Role)
// ========================================================
router.post(
  '/super-admin',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireSuperAdmin,
  FranchiseController.createFranchise
);

router.get(
  '/super-admin',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireSuperAdmin,
  FranchiseController.listFranchises
);

router.get(
  '/super-admin/:id',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireSuperAdmin,
  FranchiseController.getFranchise
);

router.put(
  '/super-admin/:id',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireSuperAdmin,
  FranchiseController.updateFranchise
);

router.patch(
  '/super-admin/:id/status',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireSuperAdmin,
  FranchiseController.updateFranchiseStatus
);

router.post(
  '/super-admin/:id/admins',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireSuperAdmin,
  FranchiseController.assignFranchiseAdmin
);

router.delete(
  '/super-admin/:id/admins/:adminId',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireSuperAdmin,
  FranchiseController.removeFranchiseAdmin
);

// ========================================================
// FRANCHISE ADMIN ROUTES (Requires Admin Token + Franchise Admin Context)
// ========================================================
router.get(
  '/admin/dashboard',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.getDashboard
);

router.get(
  '/admin/customers',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.listCustomers
);

router.get(
  '/admin/customers/search-user',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.searchUsersForLinking
);

router.post(
  '/admin/customers/link-user',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.linkExistingCustomer
);

router.post(
  '/admin/customers/create',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.createCustomerAccount
);

router.patch(
  '/admin/customers/:userId/status',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.updateCustomerStatus
);

router.get(
  '/admin/staff',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.listStaff
);

router.post(
  '/admin/staff',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.addStaff
);

router.post(
  '/admin/staff/create',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.createStaffAccount
);

router.patch(
  '/admin/staff/:userId/status',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.updateStaffStatus
);

router.get(
  '/admin/functions',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.listFunctions
);

router.post(
  '/admin/functions',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.createFunction
);

router.post(
  '/admin/staff-permissions',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.setStaffPermissions
);

router.delete(
  '/admin/staff-permissions',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.revokeStaffPermissions
);

router.get(
  '/admin/reports',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.getReports
);

router.get(
  '/admin/audit-logs',
  authenticateAdminToken,
  resolveFranchiseContext,
  requireFranchiseAdmin,
  FranchiseController.getAuditLogs
);

// ========================================================
// FRANCHISE STAFF ROUTES (Requires User Token + Staff Role + Function Permissions)
// ========================================================
router.get(
  '/staff/functions',
  authenticateToken,
  resolveFranchiseContext,
  FranchiseController.getAssignedFunctions
);

router.get(
  '/staff/functions/:functionId',
  authenticateToken,
  resolveFranchiseContext,
  requireStaffFunctionPermission('can_view'),
  FranchiseController.getFunctionDetails
);

router.get(
  '/staff/functions/:functionId/persons',
  authenticateToken,
  resolveFranchiseContext,
  requireStaffFunctionPermission('can_view'),
  FranchiseController.getFunctionPersons
);

router.post(
  '/staff/functions/:functionId/persons',
  authenticateToken,
  resolveFranchiseContext,
  requireStaffFunctionPermission('can_add_customer'),
  FranchiseController.addFunctionPerson
);

router.post(
  '/staff/functions/:functionId/transactions',
  authenticateToken,
  resolveFranchiseContext,
  requireStaffFunctionPermission('can_add_transaction'),
  FranchiseController.addTransaction
);

router.put(
  '/staff/functions/:functionId/transactions/:txId',
  authenticateToken,
  resolveFranchiseContext,
  requireStaffFunctionPermission('can_edit_transaction'),
  FranchiseController.editTransaction
);

router.delete(
  '/staff/functions/:functionId/transactions/:txId',
  authenticateToken,
  resolveFranchiseContext,
  requireStaffFunctionPermission('can_delete_transaction'),
  FranchiseController.deleteTransaction
);

router.get(
  '/staff/functions/:functionId/transactions',
  authenticateToken,
  resolveFranchiseContext,
  requireStaffFunctionPermission('can_view'),
  FranchiseController.getFunctionTransactions
);

router.get(
  '/staff/functions/:functionId/reports',
  authenticateToken,
  resolveFranchiseContext,
  requireStaffFunctionPermission('can_view_report'),
  FranchiseController.getFunctionReport
);

// ========================================================
// FRANCHISE CUSTOMER ROUTES (Requires User Token + Customer Role)
// ========================================================
router.get(
  '/customer/me',
  authenticateToken,
  resolveFranchiseContext,
  FranchiseController.getCustomerProfile
);

router.get(
  '/customer/functions',
  authenticateToken,
  resolveFranchiseContext,
  FranchiseController.getCustomerFunctions
);

router.get(
  '/customer/functions/:functionId/summary',
  authenticateToken,
  resolveFranchiseContext,
  FranchiseController.getCustomerFunctionSummary
);

router.get(
  '/customer/functions/:functionId/transactions',
  authenticateToken,
  resolveFranchiseContext,
  FranchiseController.getCustomerFunctionTransactions
);

module.exports = router;
