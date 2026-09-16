const FranchiseModel = require('../models/franchiseModel');
const Admin = require('../models/admin');
const logger = require('../config/logger');

/**
 * Middleware to resolve franchise role and active context from database.
 * NEVER trusts client-submitted roles or franchise IDs.
 */
async function resolveFranchiseContext(req, res, next) {
  try {
    if (!req.user) {
      return res.status(401).json({
        responseType: 'F',
        responseValue: { message: 'Authentication required.' }
      });
    }

    const { userId, accountType } = req.user;

    if (accountType === 'admin') {
      const adminId = Number(userId);
      const admin = await Admin.findById(adminId);

      if (!admin || admin.is_deleted || admin.status !== 'ACTIVE') {
        return res.status(403).json({
          responseType: 'F',
          responseValue: { message: 'Admin account is inactive or deleted.' }
        });
      }

      // Admin ID = 1 is designated Super Admin, or check if admin has no franchise restriction
      const franchiseAdmin = await FranchiseModel.findFranchiseAdminByAdminId(adminId);

      if (franchiseAdmin) {
        req.franchise = {
          role: 'FRANCHISE_ADMIN',
          franchiseId: franchiseAdmin.franchise_id,
          franchiseName: franchiseAdmin.franchise_name,
          franchiseCode: franchiseAdmin.franchise_code,
          adminId
        };
      } else {
        // If not assigned to specific franchise, treats as Super Admin
        req.franchise = {
          role: 'SUPER_ADMIN',
          franchiseId: null,
          adminId
        };
      }
      return next();
    }

    if (accountType === 'user') {
      const numericUserId = Number(userId);

      // Check if user is active Franchise Staff
      const staffRecord = await FranchiseModel.findStaffByUserId(numericUserId);
      if (staffRecord) {
        req.franchise = {
          role: 'FRANCHISE_STAFF',
          franchiseId: staffRecord.franchise_id,
          franchiseName: staffRecord.franchise_name,
          franchiseCode: staffRecord.franchise_code,
          userId: numericUserId
        };
        return next();
      }

      // Check if user is active Franchise Customer
      const customerRecord = await FranchiseModel.findCustomerByUserId(numericUserId);
      if (customerRecord) {
        req.franchise = {
          role: 'FRANCHISE_CUSTOMER',
          franchiseId: customerRecord.franchise_id,
          franchiseName: customerRecord.franchise_name,
          franchiseCode: customerRecord.franchise_code,
          customerCode: customerRecord.customer_code,
          userId: numericUserId
        };
        return next();
      }

      // Direct Play Store User
      req.franchise = {
        role: 'DIRECT_USER',
        franchiseId: null,
        userId: numericUserId
      };
      return next();
    }

    return res.status(403).json({
      responseType: 'F',
      responseValue: { message: 'Unknown account type.' }
    });
  } catch (err) {
    logger.error('Error in resolveFranchiseContext middleware:', err);
    return res.status(500).json({
      responseType: 'F',
      responseValue: { message: 'Authorization error.' }
    });
  }
}

/**
 * Require Super Admin Access
 */
function requireSuperAdmin(req, res, next) {
  if (req.franchise && req.franchise.role === 'SUPER_ADMIN') {
    return next();
  }
  return res.status(403).json({
    responseType: 'F',
    responseValue: { message: 'Super Admin privileges required.' }
  });
}

/**
 * Require Franchise Admin Access (Super Admin or assigned Franchise Admin)
 */
function requireFranchiseAdmin(req, res, next) {
  if (req.franchise && (req.franchise.role === 'SUPER_ADMIN' || req.franchise.role === 'FRANCHISE_ADMIN')) {
    return next();
  }
  return res.status(403).json({
    responseType: 'F',
    responseValue: { message: 'Franchise Admin privileges required.' }
  });
}

/**
 * Require Staff Function Permission
 * @param {string} permissionName - Flag in franchise_staff_function_access (e.g. 'can_view', 'can_add_transaction')
 */
function requireStaffFunctionPermission(permissionName) {
  return async (req, res, next) => {
    try {
      const role = req.franchise?.role;

      // Super Admin and Franchise Admin bypass individual function permission locks for their franchise
      if (role === 'SUPER_ADMIN' || role === 'FRANCHISE_ADMIN') {
        return next();
      }

      if (role !== 'FRANCHISE_STAFF') {
        return res.status(403).json({
          responseType: 'F',
          responseValue: { message: 'Franchise Staff privileges required.' }
        });
      }

      const franchiseId = req.franchise.franchiseId;
      const staffUserId = req.franchise.userId;
      const functionId = Number(req.params.functionId || req.body.function_id || req.body.functionId || req.query.functionId);

      if (!functionId) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Target function ID is required.' }
        });
      }

      const access = await FranchiseModel.getStaffFunctionAccess(franchiseId, staffUserId, functionId);

      if (!access || access.status !== 'ACTIVE' || access.staff_status !== 'ACTIVE') {
        return res.status(403).json({
          responseType: 'F',
          responseValue: { message: 'Access denied: You are not assigned to this function or access has been revoked.' }
        });
      }

      if (permissionName && !access[permissionName]) {
        return res.status(403).json({
          responseType: 'F',
          responseValue: { message: `Access denied: Insufficient permission '${permissionName}' for this function.` }
        });
      }

      req.functionAccess = access;
      return next();
    } catch (err) {
      logger.error('Error in requireStaffFunctionPermission middleware:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Permission verification failed.' }
      });
    }
  };
}

module.exports = {
  resolveFranchiseContext,
  requireSuperAdmin,
  requireFranchiseAdmin,
  requireStaffFunctionPermission
};
