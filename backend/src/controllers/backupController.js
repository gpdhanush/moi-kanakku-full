const fs = require("fs");
const backupService = require("../services/databaseBackupService");
const logger = require("../config/logger");

function sendFile(res, filePath, filename) {
  res.setHeader("Content-Type", "application/gzip");
  res.setHeader(
    "Content-Disposition",
    `attachment; filename="${filename}"`
  );
  res.setHeader("Cache-Control", "no-store");
  const stream = fs.createReadStream(filePath);
  stream.on("error", (error) => {
    logger.error("Backup download stream failed", error);
    if (!res.headersSent) {
      res.status(500).json({
        responseType: "F",
        responseValue: { message: "Unable to download backup file." },
      });
    } else {
      res.end();
    }
  });
  stream.pipe(res);
}

exports.backupController = {
  createAndDownload: async (req, res) => {
    try {
      const backup = await backupService.createBackup();
      sendFile(res, backup.path, backup.filename);
    } catch (error) {
      const status = error.code === "BACKUP_IN_PROGRESS" ? 409 : 500;
      logger.error("Database backup failed", error);
      return res.status(status).json({
        responseType: "F",
        responseValue: {
          message: error.message || "Failed to create database backup.",
        },
      });
    }
  },

  list: async (_req, res) => {
    try {
      const files = await backupService.listBackupFiles();
      return res.status(200).json({
        responseType: "S",
        responseValue: {
          database: process.env.DB_NAME,
          count: files.length,
          files,
        },
      });
    } catch (error) {
      logger.error("Failed to list database backups", error);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: "Failed to list backups." },
      });
    }
  },

  download: async (req, res) => {
    try {
      const filename = String(req.params.filename || "");
      const filePath = backupService.getBackupPath(filename);
      if (!fs.existsSync(filePath)) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Backup file not found." },
        });
      }
      sendFile(res, filePath, filename);
    } catch (error) {
      const status = error.code === "INVALID_FILENAME" ? 400 : 500;
      return res.status(status).json({
        responseType: "F",
        responseValue: {
          message: error.message || "Failed to download backup.",
        },
      });
    }
  },

  remove: async (req, res) => {
    try {
      const filename = String(req.params.filename || "");
      await backupService.deleteBackup(filename);
      return res.status(200).json({
        responseType: "S",
        responseValue: { message: "Backup deleted.", filename },
      });
    } catch (error) {
      const status =
        error.code === "INVALID_FILENAME"
          ? 400
          : error.code === "ENOENT"
            ? 404
            : 500;
      return res.status(status).json({
        responseType: "F",
        responseValue: {
          message:
            status === 404
              ? "Backup file not found."
              : error.message || "Failed to delete backup.",
        },
      });
    }
  },
};
