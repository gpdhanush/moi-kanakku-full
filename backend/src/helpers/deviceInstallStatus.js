const DEVICE_STATUS = {
  ACTIVE: 'ACTIVE',
  INACTIVE: 'INACTIVE',
  LIKELY_UNINSTALLED: 'LIKELY_UNINSTALLED',
  UNKNOWN: 'UNKNOWN',
};

function getInactiveDays() {
  const days = Number(process.env.DEVICE_INACTIVE_DAYS);
  return Number.isFinite(days) && days > 0 ? days : 14;
}

function normalizeTokenStatus(device) {
  if (!device) return 'invalid';
  const status = String(device.token_status || '').toLowerCase();
  if (status === 'invalid' || status === 'active') return status;
  return Number(device.is_active) === 1 || device.is_active === true ? 'active' : 'invalid';
}

function deriveDeviceStatus(device, inactiveDays = getInactiveDays()) {
  if (!device) return DEVICE_STATUS.UNKNOWN;
  if (normalizeTokenStatus(device) === 'invalid') {
    return DEVICE_STATUS.LIKELY_UNINSTALLED;
  }
  const lastSeen = device.last_used_at || device.last_seen_at;
  if (!lastSeen) return DEVICE_STATUS.INACTIVE;
  const then = new Date(lastSeen).getTime();
  if (!Number.isFinite(then)) return DEVICE_STATUS.INACTIVE;
  const ageDays = (Date.now() - then) / (1000 * 60 * 60 * 24);
  return ageDays <= inactiveDays ? DEVICE_STATUS.ACTIVE : DEVICE_STATUS.INACTIVE;
}

function deriveUserAppStatus(devices, inactiveDays = getInactiveDays()) {
  if (!Array.isArray(devices) || devices.length === 0) {
    return DEVICE_STATUS.UNKNOWN;
  }
  const statuses = devices.map((device) => deriveDeviceStatus(device, inactiveDays));
  if (statuses.includes(DEVICE_STATUS.ACTIVE)) return DEVICE_STATUS.ACTIVE;
  if (statuses.includes(DEVICE_STATUS.INACTIVE)) return DEVICE_STATUS.INACTIVE;
  return DEVICE_STATUS.LIKELY_UNINSTALLED;
}

function summarizeDevices(devices, inactiveDays = getInactiveDays()) {
  const list = Array.isArray(devices) ? devices : [];
  let lastSeen = null;
  let latest = null;
  const platforms = new Set();

  for (const device of list) {
    if (device.platform) platforms.add(String(device.platform));
    const seen = device.last_used_at || device.last_seen_at;
    if (seen && (!lastSeen || new Date(seen) > new Date(lastSeen))) {
      lastSeen = seen;
      latest = device;
    }
  }

  return {
    app_status: deriveUserAppStatus(list, inactiveDays),
    last_seen_at: lastSeen,
    device_count: list.length,
    platforms: [...platforms],
    app_version: latest?.app_version || null,
  };
}

function toAdminDevice(device, inactiveDays = getInactiveDays()) {
  if (!device) return null;
  return {
    id: device.id || null,
    device_name: device.device_name || null,
    device_id: device.device_id || null,
    platform: device.platform || 'android',
    app_version: device.app_version || null,
    android_version: device.androidVersion || device.android_version || null,
    brand: device.brand || null,
    model: device.model || null,
    manufacturer: device.manufacturer || null,
    ram_size: device.ram_size || null,
    is_active: Number(device.is_active) === 1 || device.is_active === true,
    token_status: normalizeTokenStatus(device),
    last_used_at: device.last_used_at || null,
    uninstalled_at: device.uninstalled_at || null,
    created_at: device.created_at || null,
    install_status: deriveDeviceStatus(device, inactiveDays),
  };
}

module.exports = {
  DEVICE_STATUS,
  getInactiveDays,
  normalizeTokenStatus,
  deriveDeviceStatus,
  deriveUserAppStatus,
  summarizeDevices,
  toAdminDevice,
};
