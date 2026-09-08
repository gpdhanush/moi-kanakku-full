const path = require('path');
const fs = require('fs');
const winston = require('winston');

// Ensure logs directory exists
const logsDir = path.join(process.cwd(), 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

const { combine, timestamp, printf, errors, json } = winston.format;

// Custom readable log format for console and file logs
const customFormat = printf(({ level, message, timestamp: ts, stack, ...meta }) => {
  let logLine = `${ts} [${level.toUpperCase()}]: ${message}`;
  if (stack) {
    logLine += `\nStack: ${stack}`;
  }
  if (Object.keys(meta).length > 0) {
    logLine += ` | Meta: ${JSON.stringify(meta)}`;
  }
  return logLine;
});

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: combine(
    errors({ stack: true }),
    timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    customFormat
  ),
  transports: [
    // Console transport (Colored output)
    new winston.transports.Console({
      format: combine(
        winston.format.colorize(),
        timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        customFormat
      )
    }),
    // Error log transport
    new winston.transports.File({
      filename: path.join(logsDir, 'error.log'),
      level: 'error',
      maxsize: 10 * 1024 * 1024, // 10MB
      maxFiles: 5,
      tailable: true
    }),
    // Combined log transport (All application logs)
    new winston.transports.File({
      filename: path.join(logsDir, 'combined.log'),
      maxsize: 10 * 1024 * 1024, // 10MB
      maxFiles: 5,
      tailable: true
    }),
    // Server / HTTP access log transport
    new winston.transports.File({
      filename: path.join(logsDir, 'server.log'),
      maxsize: 10 * 1024 * 1024, // 10MB
      maxFiles: 5,
      tailable: true
    })
  ]
});

// Stream for Morgan HTTP request logging into server.log & combined.log
logger.stream = {
  write: (message) => {
    logger.info(message.trim());
  }
};

/**
 * Enhanced error logging helper
 */
function logError(message, errOrMeta) {
  if (errOrMeta instanceof Error) {
    logger.error(message, { error: errOrMeta.message, stack: errOrMeta.stack });
  } else if (errOrMeta && typeof errOrMeta === 'object') {
    logger.error(message, errOrMeta);
  } else {
    logger.error(message);
  }
}

// Preserve original error handling for Error objects passed directly
const originalError = logger.error.bind(logger);
logger.error = (msg, meta) => {
  if (meta instanceof Error) {
    logError(msg, meta);
  } else {
    originalError(msg, meta);
  }
};

module.exports = logger;
module.exports.logError = logError;
