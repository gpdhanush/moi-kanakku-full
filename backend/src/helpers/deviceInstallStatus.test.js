const assert = require('assert');
const {
  DEVICE_STATUS,
  deriveDeviceStatus,
  deriveUserAppStatus,
  summarizeDevices,
} = require('./deviceInstallStatus');

const recent = new Date().toISOString();
const old = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

assert.strictEqual(deriveUserAppStatus([]), DEVICE_STATUS.UNKNOWN);
assert.strictEqual(deriveUserAppStatus(null), DEVICE_STATUS.UNKNOWN);

assert.strictEqual(
  deriveDeviceStatus({ token_status: 'active', is_active: 1, last_used_at: recent }),
  DEVICE_STATUS.ACTIVE
);
assert.strictEqual(
  deriveDeviceStatus({ token_status: 'active', is_active: 1, last_used_at: old }),
  DEVICE_STATUS.INACTIVE
);
assert.strictEqual(
  deriveDeviceStatus({ token_status: 'invalid', is_active: 0, last_used_at: recent }),
  DEVICE_STATUS.LIKELY_UNINSTALLED
);

assert.strictEqual(
  deriveUserAppStatus([
    { token_status: 'invalid', is_active: 0, last_used_at: old },
    { token_status: 'active', is_active: 1, last_used_at: recent, platform: 'android', app_version: '5.0.2' },
  ]),
  DEVICE_STATUS.ACTIVE
);

assert.strictEqual(
  deriveUserAppStatus([
    { token_status: 'invalid', is_active: 0 },
    { token_status: 'invalid', is_active: 0 },
  ]),
  DEVICE_STATUS.LIKELY_UNINSTALLED
);

const summary = summarizeDevices([
  { token_status: 'active', is_active: 1, last_used_at: recent, platform: 'android', app_version: '5.0.2' },
]);
assert.strictEqual(summary.app_status, DEVICE_STATUS.ACTIVE);
assert.strictEqual(summary.device_count, 1);
assert.deepStrictEqual(summary.platforms, ['android']);
assert.strictEqual(summary.app_version, '5.0.2');

console.log('deviceInstallStatus tests passed');
