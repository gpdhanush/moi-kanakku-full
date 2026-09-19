const { AppRuntimeConfig } = require('../models/appRuntimeConfig');
const logger = require('../config/logger');

function cleanUrl(value, field) {
  const url = String(value || '').trim();
  if (!url || !/^https:\/\//i.test(url)) {
    throw new Error(`${field} must be a valid HTTPS URL.`);
  }
  return url.slice(0, 500);
}

function cleanVersion(value) {
  return String(value || '').trim().slice(0, 32);
}

function publicValue(config) {
  if (!config) return null;
  return {
    liveURL: config.liveURL,
    imageUrl: config.imageUrl,
    maintenanceMode: config.maintenanceMode,
    minAppVersion: config.minAppVersion,
    updatedAt: config.updatedAt,
  };
}

exports.appRuntimeConfigController = {
  getPublic: async (req, res) => {
    try {
      const config = await AppRuntimeConfig.get();
      if (!config) {
        return res.status(404).json({
          responseType: 'F',
          responseValue: { message: 'Runtime configuration is not available.' },
        });
      }
      return res.status(200).json({ responseType: 'S', responseValue: publicValue(config) });
    } catch (error) {
      logger.error('Error reading public runtime config:', error);
      return res.status(503).json({
        responseType: 'F',
        responseValue: { message: 'Runtime configuration is unavailable.' },
      });
    }
  },

  getAdmin: async (req, res) => {
    try {
      const config = await AppRuntimeConfig.get();
      return res.status(200).json({ responseType: 'S', responseValue: config });
    } catch (error) {
      logger.error('Error reading admin runtime config:', error);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: 'Failed to load runtime configuration.' },
      });
    }
  },

  updateAdmin: async (req, res) => {
    try {
      const config = await AppRuntimeConfig.upsert({
        liveURL: cleanUrl(req.body?.liveURL, 'liveURL'),
        imageUrl: cleanUrl(req.body?.imageUrl, 'imageUrl'),
        maintenanceMode: req.body?.maintenanceMode === true,
        minAppVersion: cleanVersion(req.body?.minAppVersion),
        updatedBy: req.admin?.userId || req.user?.userId || null,
      });
      return res.status(200).json({ responseType: 'S', responseValue: config });
    } catch (error) {
      logger.error('Error updating runtime config:', error);
      const status = error.message?.includes('must be') ? 400 : 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: { message: error.message || 'Failed to update runtime configuration.' },
      });
    }
  },
};
