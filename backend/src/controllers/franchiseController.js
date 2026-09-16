const FranchiseModel = require('../models/franchiseModel');
const FranchiseService = require('../services/franchiseService');
const logger = require('../config/logger');

const FranchiseController = {
  // ==========================================
  // SUPER ADMIN ENDPOINTS
  // ==========================================
  async createFranchise(req, res) {
    try {
      const { name, code, mobile, email, address, city, state, pincode } = req.body;

      if (!name || !code) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Franchise name and code are required.' }
        });
      }

      const superAdminId = req.franchise.adminId;
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      const newFranchise = await FranchiseService.createFranchise(
        { name, code, mobile, email, address, city, state, pincode },
        superAdminId,
        metadata
      );

      return res.status(201).json({
        responseType: 'S',
        responseValue: {
          message: 'Franchise branch created successfully.',
          franchise: newFranchise
        }
      });
    } catch (err) {
      logger.error('Error creating franchise:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to create franchise.' }
      });
    }
  },

  async listFranchises(req, res) {
    try {
      const { limit = 20, offset = 0, search = '' } = req.query;
      const result = await FranchiseModel.findAllFranchises({ limit, offset, search });

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          franchises: result.data,
          total: result.total,
          limit: Number(limit),
          offset: Number(offset)
        }
      });
    } catch (err) {
      logger.error('Error listing franchises:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to list franchises.' }
      });
    }
  },

  async getFranchise(req, res) {
    try {
      const id = Number(req.params.id);
      const franchise = await FranchiseModel.findFranchiseById(id);

      if (!franchise) {
        return res.status(404).json({
          responseType: 'F',
          responseValue: { message: 'Franchise not found.' }
        });
      }

      const admins = await FranchiseModel.findAdminsByFranchiseId(id);
      const report = await FranchiseModel.getFranchiseReport(id);

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          franchise,
          admins,
          summary: report
        }
      });
    } catch (err) {
      logger.error('Error getting franchise details:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to retrieve franchise details.' }
      });
    }
  },

  async updateFranchise(req, res) {
    try {
      const id = Number(req.params.id);
      const superAdminId = req.franchise.adminId;
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      const updated = await FranchiseService.updateFranchise(id, req.body, superAdminId, metadata);

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          message: 'Franchise updated successfully.',
          franchise: updated
        }
      });
    } catch (err) {
      logger.error('Error updating franchise:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to update franchise.' }
      });
    }
  },

  async assignFranchiseAdmin(req, res) {
    try {
      const franchiseId = Number(req.params.id);
      const { adminId } = req.body;

      if (!adminId) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'adminId is required.' }
        });
      }

      const superAdminId = req.franchise.adminId;
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      await FranchiseService.assignFranchiseAdmin(franchiseId, Number(adminId), superAdminId, metadata);

      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: 'Franchise Admin assigned successfully.' }
      });
    } catch (err) {
      logger.error('Error assigning franchise admin:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to assign admin.' }
      });
    }
  },

  async removeFranchiseAdmin(req, res) {
    try {
      const franchiseId = Number(req.params.id);
      const adminId = Number(req.params.adminId);
      const superAdminId = req.franchise.adminId;
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      await FranchiseService.removeFranchiseAdmin(franchiseId, adminId, superAdminId, metadata);

      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: 'Franchise Admin removed successfully.' }
      });
    } catch (err) {
      logger.error('Error removing franchise admin:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to remove admin.' }
      });
    }
  },

  // ==========================================
  // FRANCHISE ADMIN ENDPOINTS
  // ==========================================
  async getDashboard(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const franchise = await FranchiseModel.findFranchiseById(franchiseId);
      const report = await FranchiseModel.getFranchiseReport(franchiseId);
      const staffList = await FranchiseModel.findStaffByFranchiseId(franchiseId);
      const recentFunctions = await FranchiseModel.findFunctionsByFranchiseId(franchiseId, { limit: 5, offset: 0 });

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          franchise,
          metrics: report,
          totalStaffCount: staffList.length,
          recentFunctions: recentFunctions.data
        }
      });
    } catch (err) {
      logger.error('Error loading dashboard:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to load franchise dashboard.' }
      });
    }
  },

  async listCustomers(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const { limit = 50, offset = 0, search = '' } = req.query;
      const result = await FranchiseModel.findCustomersByFranchiseId(franchiseId, { limit, offset, search });

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          customers: result.data,
          total: result.total
        }
      });
    } catch (err) {
      logger.error('Error listing customers:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to fetch customer list.' }
      });
    }
  },

  async searchUsersForLinking(req, res) {
    try {
      const { search } = req.query;
      if (!search || search.trim().length < 3) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Please provide at least 3 characters for search.' }
        });
      }

      const users = await FranchiseModel.searchUsersForCustomerLinking(search);
      return res.status(200).json({
        responseType: 'S',
        responseValue: { users }
      });
    } catch (err) {
      logger.error('Error searching users:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to search users.' }
      });
    }
  },

  async linkExistingCustomer(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const { userId, customerCode } = req.body;

      if (!userId) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'userId is required.' }
        });
      }

      const actorInfo = { actorType: 'ADMIN', adminId: req.franchise.adminId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      await FranchiseService.addExistingUserAsCustomer(franchiseId, Number(userId), customerCode, actorInfo, metadata);

      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: 'Customer linked successfully.' }
      });
    } catch (err) {
      logger.error('Error linking customer:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to link customer.' }
      });
    }
  },

  async createCustomerAccount(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const { full_name, email, mobile, password, customerCode } = req.body;

      if (!full_name || !mobile) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Full name and mobile are required.' }
        });
      }

      const actorInfo = { actorType: 'ADMIN', adminId: req.franchise.adminId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      const user = await FranchiseService.createNewUserAsCustomer(
        franchiseId,
        { full_name, email, mobile, password },
        customerCode,
        actorInfo,
        metadata
      );

      return res.status(201).json({
        responseType: 'S',
        responseValue: {
          message: 'New customer account created and linked successfully.',
          customer: user
        }
      });
    } catch (err) {
      logger.error('Error creating customer account:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to create customer account.' }
      });
    }
  },

  async listStaff(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const staffList = await FranchiseModel.findStaffByFranchiseId(franchiseId);

      return res.status(200).json({
        responseType: 'S',
        responseValue: { staff: staffList }
      });
    } catch (err) {
      logger.error('Error listing staff:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to list staff.' }
      });
    }
  },

  async addStaff(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const { userId } = req.body;

      if (!userId) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'userId is required.' }
        });
      }

      const actorInfo = { actorType: 'ADMIN', adminId: req.franchise.adminId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      await FranchiseService.addStaff(franchiseId, Number(userId), actorInfo, metadata);

      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: 'Staff member added successfully.' }
      });
    } catch (err) {
      logger.error('Error adding staff:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to add staff.' }
      });
    }
  },

  async createStaffAccount(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const { full_name, email, mobile, password } = req.body;

      if (!full_name || !mobile) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Full name and mobile are required.' }
        });
      }

      const actorInfo = { actorType: 'ADMIN', adminId: req.franchise.adminId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      const user = await FranchiseService.createNewUserAsStaff(
        franchiseId,
        { full_name, email, mobile, password },
        actorInfo,
        metadata
      );

      return res.status(201).json({
        responseType: 'S',
        responseValue: {
          message: 'Staff account created successfully.',
          staff: user
        }
      });
    } catch (err) {
      logger.error('Error creating staff account:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to create staff account.' }
      });
    }
  },

  async updateStaffStatus(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const userId = Number(req.params.userId);
      const { status } = req.body;

      if (!['ACTIVE', 'INACTIVE', 'REVOKED'].includes(status)) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Invalid status value.' }
        });
      }

      const actorInfo = { actorType: 'ADMIN', adminId: req.franchise.adminId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      await FranchiseService.updateStaffStatus(franchiseId, userId, status, actorInfo, metadata);

      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: `Staff status updated to ${status}.` }
      });
    } catch (err) {
      logger.error('Error updating staff status:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to update staff status.' }
      });
    }
  },

  async listFunctions(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const { limit = 50, offset = 0, search = '' } = req.query;
      const result = await FranchiseModel.findFunctionsByFranchiseId(franchiseId, { limit, offset, search });

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          functions: result.data,
          total: result.total
        }
      });
    } catch (err) {
      logger.error('Error listing franchise functions:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to list functions.' }
      });
    }
  },

  async createFunction(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const { customerUserId, function_name, function_date, location, notes, image_url } = req.body;

      if (!customerUserId || !function_name || !function_date) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'customerUserId, function_name, and function_date are required.' }
        });
      }

      const actorInfo = { actorType: 'ADMIN', adminId: req.franchise.adminId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      const func = await FranchiseService.createFranchiseFunction(
        franchiseId,
        Number(customerUserId),
        { function_name, function_date, location, notes, image_url },
        actorInfo,
        metadata
      );

      return res.status(201).json({
        responseType: 'S',
        responseValue: {
          message: 'Franchise function created successfully.',
          function: func
        }
      });
    } catch (err) {
      logger.error('Error creating franchise function:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to create function.' }
      });
    }
  },

  async setStaffPermissions(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const { staffUserId, functionId, permissions } = req.body;

      if (!staffUserId || !functionId) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'staffUserId and functionId are required.' }
        });
      }

      const actorInfo = { actorType: 'ADMIN', adminId: req.franchise.adminId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      await FranchiseService.setStaffFunctionPermissions(
        franchiseId,
        Number(staffUserId),
        Number(functionId),
        permissions || {},
        actorInfo,
        metadata
      );

      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: 'Staff function permissions set successfully.' }
      });
    } catch (err) {
      logger.error('Error setting staff permissions:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to set permissions.' }
      });
    }
  },

  async revokeStaffPermissions(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const { staffUserId, functionId } = req.body;

      if (!staffUserId || !functionId) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'staffUserId and functionId are required.' }
        });
      }

      const actorInfo = { actorType: 'ADMIN', adminId: req.franchise.adminId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      await FranchiseService.revokeStaffFunctionAccess(
        franchiseId,
        Number(staffUserId),
        Number(functionId),
        actorInfo,
        metadata
      );

      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: 'Staff function access revoked. Data preserved.' }
      });
    } catch (err) {
      logger.error('Error revoking staff permissions:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to revoke permissions.' }
      });
    }
  },

  async getReports(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const report = await FranchiseModel.getFranchiseReport(franchiseId);

      return res.status(200).json({
        responseType: 'S',
        responseValue: { report }
      });
    } catch (err) {
      logger.error('Error getting franchise reports:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to fetch report.' }
      });
    }
  },

  async getAuditLogs(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const { limit = 50, offset = 0 } = req.query;
      const logs = await FranchiseModel.getAuditLogsByFranchiseId(franchiseId, { limit, offset });

      return res.status(200).json({
        responseType: 'S',
        responseValue: { logs: logs.data, total: logs.total }
      });
    } catch (err) {
      logger.error('Error fetching audit logs:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to fetch audit logs.' }
      });
    }
  },

  // ==========================================
  // STAFF ENDPOINTS
  // ==========================================
  async getAssignedFunctions(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const staffUserId = req.franchise.userId;
      const functions = await FranchiseModel.getAssignedFunctionsForStaff(franchiseId, staffUserId);

      return res.status(200).json({
        responseType: 'S',
        responseValue: { functions }
      });
    } catch (err) {
      logger.error('Error fetching assigned staff functions:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to fetch assigned functions.' }
      });
    }
  },

  async getFunctionDetails(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const functionId = Number(req.params.functionId);

      const func = await FranchiseModel.findFranchiseFunction(franchiseId, functionId);
      if (!func) {
        return res.status(404).json({
          responseType: 'F',
          responseValue: { message: 'Function not found.' }
        });
      }

      return res.status(200).json({
        responseType: 'S',
        responseValue: { function: func, permissions: req.functionAccess }
      });
    } catch (err) {
      logger.error('Error fetching staff function details:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to fetch function details.' }
      });
    }
  },

  async addTransaction(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const staffUserId = req.franchise.userId;
      const functionId = Number(req.params.functionId);
      const { amount, type, person_id, first_name, last_name, mobile, city, occupation, notes, item_name, transaction_date } = req.body;

      if (!amount || Number(amount) <= 0) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Valid transaction amount is required.' }
        });
      }

      const actorInfo = { actorType: 'STAFF', userId: staffUserId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      const txId = await FranchiseService.addFranchiseTransaction(
        franchiseId,
        staffUserId,
        functionId,
        { amount, type, person_id, first_name, last_name, mobile, city, occupation, notes, item_name, transaction_date },
        actorInfo,
        metadata
      );

      return res.status(201).json({
        responseType: 'S',
        responseValue: {
          message: 'Moi transaction recorded successfully.',
          transactionId: txId
        }
      });
    } catch (err) {
      logger.error('Error adding transaction:', err);
      const status = err.statusCode || 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to record transaction.' }
      });
    }
  },

  async editTransaction(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const staffUserId = req.franchise.userId;
      const functionId = Number(req.params.functionId);
      const txId = Number(req.params.txId);

      const actorInfo = { actorType: 'STAFF', userId: staffUserId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      await FranchiseService.editFranchiseTransaction(
        franchiseId,
        staffUserId,
        functionId,
        txId,
        req.body,
        actorInfo,
        metadata
      );

      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: 'Transaction updated successfully.' }
      });
    } catch (err) {
      logger.error('Error editing transaction:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to update transaction.' }
      });
    }
  },

  async deleteTransaction(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const staffUserId = req.franchise.userId;
      const functionId = Number(req.params.functionId);
      const txId = Number(req.params.txId);

      const actorInfo = { actorType: 'STAFF', userId: staffUserId };
      const metadata = { ip: req.ip, userAgent: req.get('user-agent') };

      await FranchiseService.deleteFranchiseTransaction(
        franchiseId,
        staffUserId,
        functionId,
        txId,
        actorInfo,
        metadata
      );

      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: 'Transaction soft-deleted successfully.' }
      });
    } catch (err) {
      logger.error('Error deleting transaction:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: err.message || 'Failed to delete transaction.' }
      });
    }
  },

  async getFunctionTransactions(req, res) {
    try {
      const functionId = Number(req.params.functionId);
      const { limit = 50, offset = 0, type } = req.query;

      const result = await FranchiseModel.getTransactionsByFunctionId(functionId, { limit, offset, type });

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          transactions: result.data,
          total: result.total
        }
      });
    } catch (err) {
      logger.error('Error listing function transactions:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to list transactions.' }
      });
    }
  },

  async updateFranchiseStatus(req, res) {
    try {
      const id = Number(req.params.id);
      const { status } = req.body;
      if (!['ACTIVE', 'INACTIVE', 'SUSPENDED', 'CLOSED'].includes(status)) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Invalid status value.' }
        });
      }
      await FranchiseModel.updateFranchiseStatus(id, status);
      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: `Franchise status updated to ${status}.` }
      });
    } catch (err) {
      logger.error('Error updating franchise status:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to update franchise status.' }
      });
    }
  },

  async updateCustomerStatus(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const userId = Number(req.params.userId);
      const { status } = req.body;
      if (!['ACTIVE', 'INACTIVE', 'BLOCKED', 'REMOVED'].includes(status)) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Invalid status value.' }
        });
      }
      await FranchiseModel.updateCustomerStatus(franchiseId, userId, status);
      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: `Customer status updated to ${status}.` }
      });
    } catch (err) {
      logger.error('Error updating customer status:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to update customer status.' }
      });
    }
  },

  async getFunctionPersons(req, res) {
    try {
      const functionId = Number(req.params.functionId);
      const persons = await FranchiseModel.getPersonsForFunction(functionId);
      return res.status(200).json({
        responseType: 'S',
        responseValue: { persons }
      });
    } catch (err) {
      logger.error('Error fetching function persons:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to fetch function persons.' }
      });
    }
  },

  async addFunctionPerson(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const functionId = Number(req.params.functionId);
      const { first_name, last_name, mobile, city, occupation } = req.body;

      if (!first_name) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'first_name is required.' }
        });
      }

      const func = await FranchiseModel.findFranchiseFunction(franchiseId, functionId);
      if (!func) {
        return res.status(404).json({
          responseType: 'F',
          responseValue: { message: 'Function not found.' }
        });
      }

      const Person = require('../models/moiPersons');
      const newPerson = await Person.create({
        user_id: func.customer_user_id,
        first_name,
        last_name: last_name || null,
        mobile: mobile || null,
        city: city || 'Tamil Nadu',
        occupation: occupation || null
      });

      return res.status(201).json({
        responseType: 'S',
        responseValue: {
          message: 'Person created successfully.',
          person: newPerson
        }
      });
    } catch (err) {
      logger.error('Error adding person:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to create person.' }
      });
    }
  },

  async getFunctionReport(req, res) {
    try {
      const functionId = Number(req.params.functionId);
      const txResult = await FranchiseModel.getTransactionsByFunctionId(functionId, { limit: 1000, offset: 0 });

      let totalInvest = 0;
      let totalReturn = 0;
      for (const tx of txResult.data) {
        const amt = Number(tx.amount) || 0;
        if (tx.type === 'INVEST') totalInvest += amt;
        else if (tx.type === 'RETURN') totalReturn += amt;
      }

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          functionId,
          totalTransactions: txResult.total,
          totalInvestAmount: totalInvest,
          totalReturnAmount: totalReturn,
          netBalance: totalReturn - totalInvest
        }
      });
    } catch (err) {
      logger.error('Error fetching function report:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to fetch function report.' }
      });
    }
  },

  // ==========================================
  // CUSTOMER ENDPOINTS
  // ==========================================
  async getCustomerProfile(req, res) {
    try {
      const userId = req.franchise.userId;
      const customer = await FranchiseModel.findCustomerByUserId(userId);

      return res.status(200).json({
        responseType: 'S',
        responseValue: { customerProfile: customer }
      });
    } catch (err) {
      logger.error('Error getting customer profile:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to load customer profile.' }
      });
    }
  },

  async getCustomerFunctions(req, res) {
    try {
      const franchiseId = req.franchise.franchiseId;
      const userId = req.franchise.userId;
      const functions = await FranchiseModel.findFunctionsByCustomerUserId(franchiseId, userId);

      return res.status(200).json({
        responseType: 'S',
        responseValue: { functions }
      });
    } catch (err) {
      logger.error('Error getting customer functions:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to fetch customer functions.' }
      });
    }
  },

  async getCustomerFunctionSummary(req, res) {
    try {
      const functionId = Number(req.params.functionId);
      const txResult = await FranchiseModel.getTransactionsByFunctionId(functionId, { limit: 1000, offset: 0 });

      let totalInvest = 0;
      let totalReturn = 0;
      for (const tx of txResult.data) {
        const amt = Number(tx.amount) || 0;
        if (tx.type === 'INVEST') totalInvest += amt;
        else if (tx.type === 'RETURN') totalReturn += amt;
      }

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          functionId,
          totalTransactions: txResult.total,
          totalReceived: totalReturn,
          totalGiven: totalInvest
        }
      });
    } catch (err) {
      logger.error('Error getting customer function summary:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to fetch summary.' }
      });
    }
  },

  async getCustomerFunctionTransactions(req, res) {
    try {
      const functionId = Number(req.params.functionId);
      const { limit = 50, offset = 0, type } = req.query;

      const result = await FranchiseModel.getTransactionsByFunctionId(functionId, { limit, offset, type });

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          transactions: result.data,
          total: result.total
        }
      });
    } catch (err) {
      logger.error('Error getting customer transactions:', err);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to fetch transactions.' }
      });
    }
  }
};

module.exports = FranchiseController;
