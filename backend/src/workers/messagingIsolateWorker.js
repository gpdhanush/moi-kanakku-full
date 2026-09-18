/**
 * Worker-thread entry for bulk email / FCM (true isolate when enabled).
 * Started by backgroundJobQueue.enqueueBulkIsolate when BG_USE_WORKER_THREADS=true.
 */
const { parentPort, workerData } = require('worker_threads');

async function main() {
  const { type, payload, jobId } = workerData || {};
  parentPort?.postMessage({
    type: 'log',
    message: `starting ${type}`,
  });

  try {
    const runner = require('./messagingIsolateRunner');
    const summary = await runner.runBulkJob({ type, payload, jobId });
    parentPort?.postMessage({ type: 'done', summary });
  } catch (err) {
    parentPort?.postMessage({
      type: 'error',
      error: err?.message || String(err),
    });
    process.exitCode = 1;
  }
}

main();
