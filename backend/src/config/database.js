const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config();

// Attempt to load logger if available, fallback to console
let logger;
try {
  logger = require('./logger');
} catch (e) {
  logger = console;
}

/* ==========================================================================
   OPTIMIZED MYSQL2 CONNECTION POOL FOR CPANEL SHARED HOSTING
   --------------------------------------------------------------------------
   Shared hosting plans (e.g. cPanel) enforce strict limits on:
   - Max user connections (often 10 - 30)
   - Connection idle timeout (silent socket drops by cPanel firewall)
   - Memory & process resource caps

   This pool configuration optimizes connection reuse, keeps sockets alive,
   and queued requests handling without exhausting cPanel connection limits.
   ========================================================================== */

const poolConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  
  // Connection Pool Limits (Optimized for Shared cPanel Hosting)
  waitForConnections: true,
  connectionLimit: Number(process.env.DB_CONNECTION_LIMIT) || 10,
  maxIdle: Number(process.env.DB_MAX_IDLE) || 10,
  idleTimeout: Number(process.env.DB_IDLE_TIMEOUT) || 60000, // 60s idle drop
  queueLimit: 0, // Queue requests instead of failing immediately

  // Socket & TCP Keep-Alive Protection (Prevents cPanel NAT firewall connection drops)
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000, // 10 seconds
  connectTimeout: 10000, // 10 seconds

  // Dates & Type Handling
  dateStrings: true,
  supportBigNumbers: true,
  bigNumberStrings: true
};

const pool = mysql.createPool(poolConfig);

// Monitor connection pool events for diagnostic logging
pool.on('connection', (connection) => {
  if (logger.debug) {
    logger.debug(`[MySQL Pool] New connection established (Thread ID: ${connection.threadId})`);
  }
});

pool.on('error', (err) => {
  logger.error('[MySQL Pool Error]:', err);
  if (err.code === 'PROTOCOL_CONNECTION_LOST' || err.code === 'ECONNRESET') {
    logger.warn('[MySQL Pool]: Re-establishing dropped database connection pool...');
  }
});

// Self-testing database connection status on startup
(async () => {
  try {
    const connection = await pool.getConnection();
    logger.info(`✅ [MySQL Database Connected Successfully] Host: ${poolConfig.host} | DB: ${poolConfig.database}`);
    connection.release();
  } catch (err) {
    logger.error(`❌ [MySQL Database Connection Failed] Host: ${poolConfig.host} | Error: ${err.message}`);
  }
})();

module.exports = pool;