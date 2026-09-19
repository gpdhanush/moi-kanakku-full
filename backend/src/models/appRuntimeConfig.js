const db = require('../config/database');
const { toBinaryUUID, fromBinaryUUID } = require('../helpers/uuid');

const CONFIG_ID = 1;

function mapRow(row) {
  if (!row) return null;
  return {
    liveURL: row.live_url || '',
    imageUrl: row.image_url || '',
    maintenanceMode: row.maintenance_mode === 1 || row.maintenance_mode === true,
    minAppVersion: row.min_app_version || '',
    updatedBy: row.updated_by ? fromBinaryUUID(row.updated_by) : null,
    updatedAt: row.updated_at || null,
  };
}

const AppRuntimeConfig = {
  async get() {
    const [rows] = await db.query(
      `SELECT live_url, image_url, maintenance_mode, min_app_version,
              updated_by, updated_at
       FROM app_runtime_config
       WHERE id = ?
       LIMIT 1`,
      [CONFIG_ID]
    );
    return mapRow(rows[0]);
  },

  async upsert({ liveURL, imageUrl, maintenanceMode, minAppVersion, updatedBy }) {
    await db.query(
      `INSERT INTO app_runtime_config
         (id, live_url, image_url, maintenance_mode, min_app_version, updated_by)
       VALUES (?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
         live_url = VALUES(live_url),
         image_url = VALUES(image_url),
         maintenance_mode = VALUES(maintenance_mode),
         min_app_version = VALUES(min_app_version),
         updated_by = VALUES(updated_by),
         updated_at = CURRENT_TIMESTAMP`,
      [
        CONFIG_ID,
        liveURL,
        imageUrl,
        maintenanceMode ? 1 : 0,
        minAppVersion,
        updatedBy ? toBinaryUUID(updatedBy) : null,
      ]
    );
    return AppRuntimeConfig.get();
  },
};

module.exports = { AppRuntimeConfig };
