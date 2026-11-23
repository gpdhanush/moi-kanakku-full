#!/usr/bin/env node
/**
 * Standalone runner for scheduled jobs.
 *
 * Run from cPanel → Cron Jobs (or system cron) instead of node-cron inside the
 * web process. LiteSpeed starts several app workers and pauses them when idle,
 * so in-process crons both miss runs and run once per worker.
 *
 * Usage (from the backend/ folder):
 *   node scripts/run-scheduled-job.js daily       # password expiry + FCM token health (9 AM IST)
 *   node scripts/run-scheduled-job.js reminders   # upcoming function reminders (6 AM IST)
 */
const path = require("path");

// logger writes to <cwd>/logs and dotenv reads <cwd>/.env, so pin cwd to backend/.
process.chdir(path.join(__dirname, ".."));
require("dotenv").config();

const logger = require("../src/config/logger");

const JOBS = {
  daily: async () => {
    const {
      checkAndNotifyPasswordExpiration,
    } = require("../src/services/passwordExpirationService");
    const {
      runFcmTokenHealthCheck,
    } = require("../src/services/fcmTokenHealthService");
    await checkAndNotifyPasswordExpiration();
    await runFcmTokenHealthCheck();
  },
  reminders: async () => {
    const {
      sendUpcomingFunctionReminders,
    } = require("../src/services/upcomingFunctionReminderService");
    await sendUpcomingFunctionReminders();
  },
};

async function closeDbPool() {
  try {
    await require("../src/config/database").end();
  } catch (err) {
    logger.warn(`Could not close DB pool cleanly: ${err.message}`);
  }
}

async function main() {
  const name = process.argv[2];
  const job = JOBS[name];
  if (!job) {
    console.error(
      `Unknown job "${name || ""}". Use one of: ${Object.keys(JOBS).join(", ")}`,
    );
    process.exit(2);
  }

  const startedAt = Date.now();
  logger.info(`[scheduled-job:${name}] started`);
  let exitCode = 0;
  try {
    await job();
    logger.info(
      `[scheduled-job:${name}] completed in ${Math.round((Date.now() - startedAt) / 1000)}s`,
    );
  } catch (err) {
    exitCode = 1;
    logger.error(`[scheduled-job:${name}] failed`, err);
  }

  await closeDbPool();
  // firebase-admin and other clients can keep handles open; give the logger a
  // moment to flush, then exit explicitly so cron runs never pile up.
  setTimeout(() => process.exit(exitCode), 500);
}

main();
