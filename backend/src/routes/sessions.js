const express = require('express');
const router = express.Router();
const { userController } = require('../controllers/user');
const { authenticateToken } = require('../middlewares/auth');

/**
 * Session routes
 * Alias paths kept for mobile clients that call /sessions/*
 */

// End the current user session
// Body: { userId? }  — userId is taken from JWT when present
router.post('/logout', authenticateToken, userController.logout);

module.exports = router;
