const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const cron = require("node-cron");
const path = require("path");
require("dotenv").config();

// Optional until production runs `npm install` after deploy.
let cookieParser;
try {
  cookieParser = require("cookie-parser");
} catch (err) {
  console.error(
    "cookie-parser is not installed. Run npm install in backend/. Cookie auth disabled until then.",
  );
  cookieParser = () => (req, _res, next) => {
    req.cookies = req.cookies || {};
    next();
  };
}

const routes = require("./src/routes");
const healthRoutes = require("./src/routes/health");
const logger = require("./src/config/logger");
const {
  checkAndNotifyPasswordExpiration,
} = require("./src/services/passwordExpirationService");
const {
  sendUpcomingFunctionReminders,
} = require("./src/services/upcomingFunctionReminderService");
const {
  runFcmTokenHealthCheck,
} = require("./src/services/fcmTokenHealthService");

const app = express();

/* =========================
   REVERSE PROXY (cPanel / nginx)
   Required for express-rate-limit when X-Forwarded-For is set.
   Set TRUST_PROXY=false to disable (local dev only).
========================= */
if (process.env.TRUST_PROXY !== "false" && process.env.TRUST_PROXY !== "0") {
  const hops = Number(process.env.TRUST_PROXY);
  app.set("trust proxy", Number.isFinite(hops) && hops > 0 ? hops : 1);
}

/* =========================
   GLOBAL ERROR SAFETY
========================= */
process.on("unhandledRejection", (err) => {
  logger.error("Unhandled Rejection:", err);
});

process.on("uncaughtException", (err) => {
  logger.error("Uncaught Exception:", err);
});

/* =========================
   MIDDLEWARE
========================= */

// CORS Configuration (placed first so preflight OPTIONS requests are answered before security headers)
// IMPORTANT: With credentials:true, never use callback(new Error(...)) — that yields 500s without
// Access-Control-Allow-Origin and the browser reports a misleading CORS failure.
function isLocalDevOrigin(origin) {
  try {
    const url = new URL(origin);
    return (
      url.hostname === "localhost" ||
      url.hostname === "127.0.0.1" ||
      url.hostname === "[::1]"
    );
  } catch {
    return (
      typeof origin === "string" &&
      (origin.includes("localhost") || origin.includes("127.0.0.1"))
    );
  }
}

function isAllowedCorsOrigin(origin) {
  if (!origin) return true;
  if (isLocalDevOrigin(origin)) return true;

  const originsList = process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(",").map((o) => o.trim()).filter(Boolean)
    : [];

  if (originsList.includes(origin)) return true;

  // Explicit wildcard only outside production (incompatible with credentialed cookies).
  if (originsList.includes("*") && process.env.NODE_ENV !== "production") {
    return true;
  }

  // Dev server with no allowlist configured.
  if (originsList.length === 0 && process.env.NODE_ENV !== "production") {
    return true;
  }

  return false;
}

const corsOptions = {
  origin: (origin, callback) => {
    // Reflect allowed origin (required when credentials: true). Never throw.
    if (isAllowedCorsOrigin(origin)) {
      return callback(null, origin || true);
    }
    logger.warn("CORS blocked origin", { origin });
    return callback(null, false);
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: [
    "Origin",
    "X-Requested-With",
    "Content-Type",
    "Accept",
    "Authorization",
    "X-API-Key",
    "x-api-key",
    "X-CSRF-Token",
    "x-csrf-token",
  ],
  optionsSuccessStatus: 204,
};

app.use(cors(corsOptions));

// Handle preflight OPTIONS requests for all routes
app.options("*", cors(corsOptions));

// Secure headers — allow uploaded images/files to be embedded by the admin
// app and other allowed frontends (default CORP "same-origin" blocks <img>).
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" },
  }),
);

// Request logging (Console + File logging via Winston stream)
app.use(morgan(":method :url :status :res[content-length] - :response-time ms", { stream: logger.stream }));
app.use(morgan("dev"));

// Body parsing
// Increase payload size for bulk endpoints (default is 100kb)
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cookieParser());

/* =========================
   STATIC UPLOAD DIRECTORY
========================= */

const uploadPath = process.env.UPLOAD_DIR
  ? path.resolve(process.env.UPLOAD_DIR)
  : path.join(__dirname, "uploads");

// Explicit CORP on static uploads (defense in depth if helmet config changes).
app.use("/uploads", (req, res, next) => {
  res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
  next();
});
app.use("/uploads", express.static(uploadPath));

// App branding assets used by email verification pages and public screens.
app.use("/assets", (req, res, next) => {
  res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
  next();
});
app.use("/assets", express.static(path.join(__dirname, "assets")));

/* =========================
   ROUTES
========================= */

// Health route (no auth)
app.use("/health", healthRoutes);

// API routes
app.use("/apis", routes);

/* =========================
   SERVER START
========================= */

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, "0.0.0.0", () => {
  logger.info(`Server running on port ${PORT}`);
});

/* =========================
   CRON JOB (Daily 9 AM IST)
========================= */

let isDailyCronRunning = false;

cron.schedule(
  "0 9 * * *",
  async () => {
    if (isDailyCronRunning) {
      logger.warn("Daily cron already running, skipping.");
      return;
    }

    isDailyCronRunning = true;

    try {
      logger.info("Running scheduled daily jobs...");
      await checkAndNotifyPasswordExpiration();
      await runFcmTokenHealthCheck();
      logger.info("Daily cron jobs completed successfully.");
    } catch (err) {
      logger.error("Error in daily cron:", err);
    } finally {
      isDailyCronRunning = false;
    }
  },
  {
    timezone: "Asia/Kolkata",
  },
);

logger.info("Daily cron scheduled at 9:00 AM (Asia/Kolkata)");

/* =========================
   UPCOMING FUNCTION REMINDERS (Daily 6 AM IST)
========================= */

let isUpcomingReminderRunning = false;

cron.schedule(
  "0 6 * * *",
  async () => {
    if (isUpcomingReminderRunning) {
      logger.warn("Upcoming function reminder already running, skipping.");
      return;
    }

    isUpcomingReminderRunning = true;

    try {
      await sendUpcomingFunctionReminders();
    } catch (err) {
      logger.error("Error sending upcoming function reminders:", err);
    } finally {
      isUpcomingReminderRunning = false;
    }
  },
  {
    timezone: "Asia/Kolkata",
  },
);

logger.info("Upcoming function reminder scheduled at 6:00 AM (Asia/Kolkata)");

/* =========================
   GLOBAL ERROR HANDLER
========================= */

// JSON parse error handler
app.use((err, req, res, next) => {
  // body-parser will set err.type === 'entity.too.large' when payload exceeds limit
  if (err.type === 'entity.too.large') {
    logger.warn('Payload too large:', {
      size: req.headers['content-length'],
      path: req.path,
      method: req.method,
    });
    return res.status(413).json({
      responseType: 'F',
      responseValue: { message: 'Request payload too large.' }
    });
  }

  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    logger.error('JSON Parse Error:', {
      message: err.message,
      body: err.body,
      path: req.path,
      method: req.method,
    });
    return res.status(400).json({
      responseType: 'F',
      responseValue: { message: `Invalid JSON: ${err.message}` }
    });
  }
  next(err);
});

// General error handler
app.use((err, req, res, next) => {
  logger.error("Unhandled error", {
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    query: req.query,
    body: req.body && Object.keys(req.body).length ? "[present]" : undefined,
  });

  res.status(500).json({
    // keep response structure consistent with other endpoints
    responseType: 'F',
    responseValue: { message: "Something went wrong!" }
  });
});

/* =========================
   GRACEFUL SHUTDOWN
========================= */

process.on("SIGTERM", () => {
  logger.info("SIGTERM received. Shutting down gracefully...");
  server.close(() => {
    logger.info("Server closed.");
    process.exit(0);
  });
});

module.exports = app;
