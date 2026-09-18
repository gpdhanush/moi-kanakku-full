/**
 * Background job queue (isolate-style) for email / FCM work.
 *
 * HTTP handlers enqueue work and return immediately so admin/mobile clients
 * are not blocked by SMTP or Firebase round-trips.
 *
 * Uses an in-process concurrent runner (Node I/O equivalent of Dart isolates).
 * Optional worker_threads path for bulk jobs when BG_USE_WORKER_THREADS=true.
 */
const { Worker } = require('worker_threads');
const path = require('path');
const crypto = require('crypto');
const logger = require('../config/logger');

const EMAIL_CONCURRENCY = Math.max(1, Number(process.env.BG_EMAIL_CONCURRENCY) || 3);
const FCM_CONCURRENCY = Math.max(1, Number(process.env.BG_FCM_CONCURRENCY) || 8);
const GENERAL_CONCURRENCY = Math.max(1, Number(process.env.BG_GENERAL_CONCURRENCY) || 4);
const USE_WORKER_THREADS =
  process.env.BG_USE_WORKER_THREADS === 'true' ||
  process.env.BG_USE_WORKER_THREADS === '1';

class BackgroundJobQueue {
  /**
   * @param {{ name: string, concurrency?: number }} options
   */
  constructor({ name, concurrency = 2 }) {
    this.name = name;
    this.concurrency = Math.max(1, concurrency);
    this.queue = [];
    this.active = 0;
    this.stats = {
      enqueued: 0,
      completed: 0,
      failed: 0,
      inFlight: 0,
      pending: 0,
    };
  }

  /**
   * @param {string} label
   * @param {() => Promise<unknown>} task
   * @returns {string} jobId
   */
  enqueue(label, task) {
    const jobId = crypto.randomUUID();
    this.queue.push({ jobId, label, task, enqueuedAt: Date.now() });
    this.stats.enqueued += 1;
    this.stats.pending = this.queue.length;
    setImmediate(() => this.#pump());
    return jobId;
  }

  getStats() {
    return {
      name: this.name,
      concurrency: this.concurrency,
      ...this.stats,
      pending: this.queue.length,
      inFlight: this.active,
    };
  }

  async #pump() {
    while (this.active < this.concurrency && this.queue.length > 0) {
      const job = this.queue.shift();
      this.stats.pending = this.queue.length;
      this.active += 1;
      this.stats.inFlight = this.active;

      Promise.resolve()
        .then(() => job.task())
        .then(() => {
          this.stats.completed += 1;
          logger.info(
            `[bg:${this.name}] job ${job.jobId} (${job.label}) completed in ${Date.now() - job.enqueuedAt}ms`,
          );
        })
        .catch((err) => {
          this.stats.failed += 1;
          logger.error(
            `[bg:${this.name}] job ${job.jobId} (${job.label}) failed:`,
            err,
          );
        })
        .finally(() => {
          this.active -= 1;
          this.stats.inFlight = this.active;
          setImmediate(() => this.#pump());
        });
    }
  }
}

const emailQueue = new BackgroundJobQueue({
  name: 'email',
  concurrency: EMAIL_CONCURRENCY,
});
const fcmQueue = new BackgroundJobQueue({
  name: 'fcm',
  concurrency: FCM_CONCURRENCY,
});
const generalQueue = new BackgroundJobQueue({
  name: 'general',
  concurrency: GENERAL_CONCURRENCY,
});

/**
 * Queue an email send task. Returns jobId immediately.
 * @param {string} label
 * @param {() => Promise<unknown>} task
 */
function enqueueEmail(label, task) {
  return emailQueue.enqueue(label, task);
}

/**
 * Queue an FCM / push notification task. Returns jobId immediately.
 * @param {string} label
 * @param {() => Promise<unknown>} task
 */
function enqueueFcm(label, task) {
  return fcmQueue.enqueue(label, task);
}

/**
 * Queue general background work (mixed / bulk orchestration).
 * @param {string} label
 * @param {() => Promise<unknown>} task
 */
function enqueueBackground(label, task) {
  return generalQueue.enqueue(label, task);
}

/**
 * Run a bulk messaging job in a worker thread when enabled; otherwise
 * fall back to the in-process general queue.
 *
 * @param {'bulk_email' | 'bulk_fcm'} type
 * @param {object} payload - must be structured-clone serializable
 * @returns {{ jobId: string, mode: 'worker' | 'queue' }}
 */
function enqueueBulkIsolate(type, payload) {
  const jobId = crypto.randomUUID();
  const label = `${type}:${jobId}`;

  if (!USE_WORKER_THREADS) {
    const queuedId = enqueueBackground(label, async () => {
      const runner = require('../workers/messagingIsolateRunner');
      await runner.runBulkJob({ type, payload, jobId });
    });
    return { jobId: queuedId, mode: 'queue' };
  }

  setImmediate(() => {
    const workerPath = path.join(__dirname, '../workers/messagingIsolateWorker.js');
    let worker;
    try {
      worker = new Worker(workerPath, {
        workerData: { type, payload, jobId },
        env: process.env,
      });
    } catch (err) {
      logger.error(`[bg:isolate] Failed to start worker for ${label}, falling back:`, err);
      enqueueBackground(label, async () => {
        const runner = require('../workers/messagingIsolateRunner');
        await runner.runBulkJob({ type, payload, jobId });
      });
      return;
    }

    worker.on('message', (msg) => {
      if (msg?.type === 'log') {
        logger.info(`[bg:isolate:${jobId}] ${msg.message}`);
      } else if (msg?.type === 'done') {
        logger.info(`[bg:isolate:${jobId}] finished`, msg.summary || {});
      } else if (msg?.type === 'error') {
        logger.error(`[bg:isolate:${jobId}] error:`, msg.error);
      }
    });
    worker.on('error', (err) => {
      logger.error(`[bg:isolate:${jobId}] worker error:`, err);
    });
    worker.on('exit', (code) => {
      if (code !== 0) {
        logger.error(`[bg:isolate:${jobId}] worker exited with code ${code}`);
      }
    });
  });

  return { jobId, mode: 'worker' };
}

function getBackgroundQueueStats() {
  return {
    email: emailQueue.getStats(),
    fcm: fcmQueue.getStats(),
    general: generalQueue.getStats(),
    useWorkerThreads: USE_WORKER_THREADS,
  };
}

module.exports = {
  enqueueEmail,
  enqueueFcm,
  enqueueBackground,
  enqueueBulkIsolate,
  getBackgroundQueueStats,
};
