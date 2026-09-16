const pool = require('../config/database');
const bcrypt = require('bcryptjs');
const FranchiseModel = require('../models/franchiseModel');
const User = require('../models/user');
const Admin = require('../models/admin');
const TransactionFunction = require('../models/transactionFunctions');
const Transaction = require('../models/transactions');
const Person = require('../models/moiPersons');
const logger = require('../config/logger');

const FranchiseService = {
  // ==========================================
  // SUPER ADMIN FRANCHISE MANAGEMENT
  // ==========================================
  async createFranchise(franchiseData, superAdminId, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const existing = await FranchiseModel.findFranchiseByCode(franchiseData.code, connection);
      if (existing) {
        const error = new Error('Franchise code already exists.');
        error.statusCode = 409;
        throw error;
      }

      const franchiseId = await FranchiseModel.createFranchise(franchiseData, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: 'ADMIN',
        actor_admin_id: superAdminId,
        action: 'CREATE_FRANCHISE',
        entity_type: 'FRANCHISE',
        entity_id: franchiseId,
        description: `Franchise '${franchiseData.name}' created with code '${franchiseData.code}'.`,
        new_values: franchiseData,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return await FranchiseModel.findFranchiseById(franchiseId);
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  async updateFranchise(franchiseId, franchiseData, superAdminId, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const franchise = await FranchiseModel.findFranchiseById(franchiseId, connection);
      if (!franchise) {
        const error = new Error('Franchise not found.');
        error.statusCode = 404;
        throw error;
      }

      await FranchiseModel.updateFranchise(franchiseId, franchiseData, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: 'ADMIN',
        actor_admin_id: superAdminId,
        action: 'UPDATE_FRANCHISE',
        entity_type: 'FRANCHISE',
        entity_id: franchiseId,
        description: `Franchise '${franchise.name}' updated.`,
        old_values: franchise,
        new_values: franchiseData,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return await FranchiseModel.findFranchiseById(franchiseId);
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  async assignFranchiseAdmin(franchiseId, adminId, superAdminId, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const franchise = await FranchiseModel.findFranchiseById(franchiseId, connection);
      if (!franchise) {
        const error = new Error('Franchise not found.');
        error.statusCode = 404;
        throw error;
      }

      const admin = await Admin.findById(adminId, connection);
      if (!admin || admin.is_deleted) {
        const error = new Error('Admin account not found.');
        error.statusCode = 404;
        throw error;
      }

      await FranchiseModel.assignFranchiseAdmin(franchiseId, adminId, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: 'ADMIN',
        actor_admin_id: superAdminId,
        action: 'ASSIGN_FRANCHISE_ADMIN',
        entity_type: 'ADMIN',
        entity_id: adminId,
        description: `Admin '${admin.full_name}' assigned as Franchise Admin for '${franchise.name}'.`,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return true;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  async removeFranchiseAdmin(franchiseId, adminId, superAdminId, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      await FranchiseModel.removeFranchiseAdmin(franchiseId, adminId, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: 'ADMIN',
        actor_admin_id: superAdminId,
        action: 'REMOVE_FRANCHISE_ADMIN',
        entity_type: 'ADMIN',
        entity_id: adminId,
        description: `Admin ID ${adminId} removed from Franchise ID ${franchiseId}.`,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return true;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  // ==========================================
  // FRANCHISE CUSTOMER MANAGEMENT
  // ==========================================
  async addExistingUserAsCustomer(franchiseId, userId, customerCode, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const user = await User.findById(userId, connection);
      if (!user || user.is_deleted) {
        const error = new Error('User not found.');
        error.statusCode = 404;
        throw error;
      }

      await FranchiseModel.linkFranchiseCustomer(franchiseId, userId, customerCode, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || null,
        action: 'ADD_FRANCHISE_CUSTOMER',
        entity_type: 'USER',
        entity_id: userId,
        description: `Existing user '${user.full_name}' (ID: ${userId}) linked as customer to franchise ID ${franchiseId}.`,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return true;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  async createNewUserAsCustomer(franchiseId, userData, customerCode, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const existingMobile = await User.findByMobile(userData.mobile, connection);
      if (existingMobile) {
        const error = new Error('Mobile number already registered. Please link existing user instead.');
        error.statusCode = 409;
        throw error;
      }

      const passwordHash = await bcrypt.hash(userData.password || 'MoiKanakku@123', 10);
      const user = await User.create({
        full_name: userData.full_name,
        email: userData.email,
        mobile: userData.mobile,
        password: passwordHash
      }, connection);

      await FranchiseModel.linkFranchiseCustomer(franchiseId, user.id, customerCode, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || null,
        action: 'CREATE_FRANCHISE_CUSTOMER',
        entity_type: 'USER',
        entity_id: user.id,
        description: `New user customer '${userData.full_name}' created and linked to franchise.`,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return user;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  // ==========================================
  // FRANCHISE STAFF MANAGEMENT
  // ==========================================
  async addStaff(franchiseId, userId, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const user = await User.findById(userId, connection);
      if (!user || user.is_deleted) {
        const error = new Error('User not found.');
        error.statusCode = 404;
        throw error;
      }

      await FranchiseModel.assignFranchiseStaff(franchiseId, userId, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || null,
        action: 'ADD_FRANCHISE_STAFF',
        entity_type: 'USER',
        entity_id: userId,
        description: `User '${user.full_name}' added as staff to franchise ID ${franchiseId}.`,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return true;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  async createNewUserAsStaff(franchiseId, userData, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const existingMobile = await User.findByMobile(userData.mobile, connection);
      if (existingMobile) {
        const error = new Error('Mobile number already registered. Please add existing user as staff instead.');
        error.statusCode = 409;
        throw error;
      }

      const passwordHash = await bcrypt.hash(userData.password || 'StaffPass@123', 10);
      const user = await User.create({
        full_name: userData.full_name,
        email: userData.email,
        mobile: userData.mobile,
        password: passwordHash
      }, connection);

      await FranchiseModel.assignFranchiseStaff(franchiseId, user.id, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || null,
        action: 'CREATE_FRANCHISE_STAFF',
        entity_type: 'USER',
        entity_id: user.id,
        description: `New staff user '${userData.full_name}' created and assigned to franchise.`,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return user;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  async updateStaffStatus(franchiseId, userId, status, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      await FranchiseModel.updateStaffStatus(franchiseId, userId, status, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || null,
        action: 'UPDATE_STAFF_STATUS',
        entity_type: 'USER',
        entity_id: userId,
        description: `Staff ID ${userId} status updated to '${status}'.`,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return true;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  // ==========================================
  // FRANCHISE FUNCTION MANAGEMENT
  // ==========================================
  async createFranchiseFunction(franchiseId, customerUserId, functionData, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const customer = await User.findById(customerUserId, connection);
      if (!customer || customer.is_deleted) {
        const error = new Error('Customer user not found.');
        error.statusCode = 404;
        throw error;
      }

      const newFunction = await TransactionFunction.create({
        user_id: customerUserId,
        function_name: functionData.function_name,
        function_date: functionData.function_date,
        location: functionData.location || null,
        notes: functionData.notes || null,
        image_url: functionData.image_url || null
      }, connection);

      const functionId = newFunction.id || newFunction;

      await FranchiseModel.linkFranchiseFunction(
        franchiseId,
        functionId,
        customerUserId,
        actorInfo.adminId || null,
        connection
      );

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || null,
        action: 'CREATE_FRANCHISE_FUNCTION',
        entity_type: 'FUNCTION',
        entity_id: functionId,
        description: `Function '${functionData.function_name}' created for customer '${customer.full_name}'.`,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return await FranchiseModel.findFranchiseFunction(franchiseId, functionId);
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  // ==========================================
  // STAFF FUNCTION PERMISSION MANAGEMENT
  // ==========================================
  async setStaffFunctionPermissions(franchiseId, staffUserId, functionId, permissions, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const staff = await FranchiseModel.findStaffByUserId(staffUserId, connection);
      if (!staff || staff.franchise_id !== Number(franchiseId)) {
        const error = new Error('Staff user does not belong to this franchise.');
        error.statusCode = 403;
        throw error;
      }

      const func = await FranchiseModel.findFranchiseFunction(franchiseId, functionId, connection);
      if (!func) {
        const error = new Error('Function does not belong to this franchise.');
        error.statusCode = 404;
        throw error;
      }

      await FranchiseModel.setStaffFunctionAccess({
        franchise_id: franchiseId,
        staff_user_id: staffUserId,
        function_id: functionId,
        ...permissions,
        created_by_admin_id: actorInfo.adminId || null
      }, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || null,
        action: 'STAFF_FUNCTION_ACCESS_GRANTED',
        entity_type: 'FUNCTION_PERMISSION',
        entity_id: functionId,
        description: `Staff user ID ${staffUserId} granted permissions for function ID ${functionId}.`,
        new_values: permissions,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return true;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  async revokeStaffFunctionAccess(franchiseId, staffUserId, functionId, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      await FranchiseModel.revokeStaffFunctionAccess(franchiseId, staffUserId, functionId, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || null,
        action: 'STAFF_FUNCTION_ACCESS_REVOKED',
        entity_type: 'FUNCTION_PERMISSION',
        entity_id: functionId,
        description: `Staff user ID ${staffUserId} access revoked for function ID ${functionId}. Data preserved.`,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return true;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  // ==========================================
  // TRANSACTION OPERATIONS
  // ==========================================
  async addFranchiseTransaction(franchiseId, staffUserId, functionId, txData, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const ff = await FranchiseModel.findFranchiseFunction(franchiseId, functionId, connection);
      if (!ff) {
        const error = new Error('Function not associated with this franchise.');
        error.statusCode = 404;
        throw error;
      }

      let personId = txData.person_id;
      if (!personId && txData.first_name) {
        const newPerson = await Person.create({
          user_id: ff.customer_user_id,
          first_name: txData.first_name,
          last_name: txData.last_name || null,
          mobile: txData.mobile || null,
          city: txData.city || 'Tamil Nadu',
          occupation: txData.occupation || null
        }, connection);
        personId = newPerson.id || newPerson;
      }

      if (!personId) {
        const error = new Error('Person ID or first_name is required.');
        error.statusCode = 400;
        throw error;
      }

      const txResult = await Transaction.create({
        user_id: ff.customer_user_id,
        person_id: personId,
        transaction_function_id: functionId,
        transaction_function_name: ff.function_name,
        transaction_date: txData.transaction_date || ff.function_date,
        type: txData.type || 'RETURN',
        amount: txData.amount,
        item_name: txData.item_name || null,
        notes: txData.notes || null
      }, connection);

      const txId = txResult.id || txResult;

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || staffUserId,
        action: 'ADD_FRANCHISE_TRANSACTION',
        entity_type: 'TRANSACTION',
        entity_id: txId,
        description: `Transaction of amount ₹${txData.amount} added to function ID ${functionId}.`,
        new_values: txData,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return txId;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  async editFranchiseTransaction(franchiseId, staffUserId, functionId, txId, txData, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      await FranchiseModel.updateTransaction(txId, txData, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || staffUserId,
        action: 'EDIT_FRANCHISE_TRANSACTION',
        entity_type: 'TRANSACTION',
        entity_id: txId,
        description: `Transaction ID ${txId} updated.`,
        new_values: txData,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return true;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  },

  async deleteFranchiseTransaction(franchiseId, staffUserId, functionId, txId, actorInfo, requestMetadata = {}) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      await FranchiseModel.deleteTransaction(txId, connection);

      await FranchiseModel.createAuditLog({
        franchise_id: franchiseId,
        actor_type: actorInfo.actorType,
        actor_admin_id: actorInfo.adminId || null,
        actor_user_id: actorInfo.userId || staffUserId,
        action: 'DELETE_FRANCHISE_TRANSACTION',
        entity_type: 'TRANSACTION',
        entity_id: txId,
        description: `Transaction ID ${txId} soft-deleted.`,
        ip_address: requestMetadata.ip,
        user_agent: requestMetadata.userAgent
      }, connection);

      await connection.commit();
      return true;
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  }
};

module.exports = FranchiseService;
