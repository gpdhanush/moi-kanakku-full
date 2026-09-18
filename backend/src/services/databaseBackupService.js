const fs = require("fs");
const fsp = require("fs/promises");
const os = require("os");
const path = require("path");
const zlib = require("zlib");
const { spawn } = require("child_process");
const db = require("../config/database");
const logger = require("../config/logger");

const BACKUP_DIR =
  process.env.DB_BACKUP_DIR || path.join(__dirname, "../../backups");
const MAX_BACKUPS = Number(process.env.DB_BACKUP_KEEP || 10);
const DUMP_TIMEOUT_MS = Number(process.env.DB_BACKUP_TIMEOUT_MS || 5 * 60 * 1000);
const FILE_NAME_RE = /^moi-kanakku-\d{8}-\d{6}\.sql\.gz$/;

let backupInProgress = false;

function pad(value) {
  return String(value).padStart(2, "0");
}

function timestampLabel(date = new Date()) {
  return (
    `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}-` +
    `${pad(date.getHours())}${pad(date.getMinutes())}${pad(date.getSeconds())}`
  );
}

function backupFileName(date = new Date()) {
  return `moi-kanakku-${timestampLabel(date)}.sql.gz`;
}

function isSafeBackupName(filename) {
  return FILE_NAME_RE.test(filename);
}

async function ensureBackupDir() {
  await fsp.mkdir(BACKUP_DIR, { recursive: true });
}

function writeMysqlCnf() {
  const host = process.env.DB_HOST || "localhost";
  const port = Number(process.env.DB_PORT) || 3306;
  const user = process.env.DB_USER || "root";
  const password = process.env.DB_PASSWORD || "";
  const lines = [
    "[client]",
    `host=${host}`,
    `port=${port}`,
    `user=${user}`,
  ];
  if (password) {
    lines.push(`password=${password}`);
  }
  const filePath = path.join(
    os.tmpdir(),
    `moi-mysqldump-${process.pid}-${Date.now()}.cnf`
  );
  fs.writeFileSync(filePath, `${lines.join("\n")}\n`, { mode: 0o600 });
  return filePath;
}

function runMysqldump(outputPath) {
  return new Promise((resolve, reject) => {
    const dbName = process.env.DB_NAME;
    if (!dbName) {
      reject(new Error("DB_NAME is not configured."));
      return;
    }

    const dumpBin = process.env.MYSQLDUMP_PATH || "mysqldump";
    const cnfPath = writeMysqlCnf();
    const gzip = zlib.createGzip({ level: 9 });
    const out = fs.createWriteStream(outputPath);
    let stderr = "";
    let settled = false;

    const child = spawn(
      dumpBin,
      [
        `--defaults-extra-file=${cnfPath}`,
        "--single-transaction",
        "--quick",
        "--routines",
        "--triggers",
        "--hex-blob",
        "--default-character-set=utf8mb4",
        dbName,
      ],
      { stdio: ["ignore", "pipe", "pipe"] }
    );

    const cleanup = () => {
      try {
        fs.unlinkSync(cnfPath);
      } catch {
        // ignore
      }
    };

    const fail = (error) => {
      if (settled) return;
      settled = true;
      cleanup();
      child.kill("SIGKILL");
      gzip.destroy();
      out.destroy();
      reject(error);
    };

    const timer = setTimeout(() => {
      fail(new Error("Database dump timed out."));
    }, DUMP_TIMEOUT_MS);

    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    child.on("error", (error) => {
      clearTimeout(timer);
      fail(error);
    });

    child.on("close", (code) => {
      if (settled) return;
      if (code !== 0) {
        clearTimeout(timer);
        fail(
          new Error(
            stderr.trim() || `mysqldump exited with code ${code}`
          )
        );
      }
    });

    gzip.on("error", (error) => {
      clearTimeout(timer);
      fail(error);
    });

    out.on("error", (error) => {
      clearTimeout(timer);
      fail(error);
    });

    out.on("finish", () => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      cleanup();
      resolve();
    });

    child.stdout.pipe(gzip).pipe(out);
  });
}

function sqlLiteral(value) {
  if (value === null || value === undefined) return "NULL";
  if (Buffer.isBuffer(value)) {
    return `0x${value.toString("hex")}`;
  }
  if (value instanceof Date) {
    const iso = value.toISOString().slice(0, 19).replace("T", " ");
    return db.escape(iso);
  }
  return db.escape(value);
}

async function dumpViaMysql2(outputPath) {
  const dbName = process.env.DB_NAME;
  const [tableRows] = await db.query(
    "SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'"
  );
  const tableKey = `Tables_in_${dbName}`;

  const chunks = [
    `-- Moi Kanakku database backup`,
    `-- Database: ${dbName}`,
    `-- Generated: ${new Date().toISOString()}`,
    ``,
    `SET NAMES utf8mb4;`,
    `SET FOREIGN_KEY_CHECKS=0;`,
    `SET UNIQUE_CHECKS=0;`,
    ``,
  ];

  for (const row of tableRows) {
    const tableName = row[tableKey] || Object.values(row)[0];
    if (!tableName) continue;

    const [createRows] = await db.query(`SHOW CREATE TABLE \`${tableName}\``);
    const createSql = createRows[0]["Create Table"];
    chunks.push(`DROP TABLE IF EXISTS \`${tableName}\`;`);
    chunks.push(`${createSql};`);
    chunks.push("");

    const [dataRows] = await db.query(`SELECT * FROM \`${tableName}\``);
    if (dataRows.length > 0) {
      const columns = Object.keys(dataRows[0]).map((col) => `\`${col}\``);
      const batchSize = 100;
      for (let i = 0; i < dataRows.length; i += batchSize) {
        const batch = dataRows.slice(i, i + batchSize);
        const values = batch
          .map(
            (item) =>
              `(${Object.keys(item)
                .map((col) => sqlLiteral(item[col]))
                .join(", ")})`
          )
          .join(",\n");
        chunks.push(
          `INSERT INTO \`${tableName}\` (${columns.join(", ")}) VALUES\n${values};`
        );
      }
      chunks.push("");
    }
  }

  chunks.push(`SET UNIQUE_CHECKS=1;`);
  chunks.push(`SET FOREIGN_KEY_CHECKS=1;`);
  chunks.push("");

  const gzipped = await new Promise((resolve, reject) => {
    zlib.gzip(Buffer.from(chunks.join("\n"), "utf8"), { level: 9 }, (err, result) => {
      if (err) reject(err);
      else resolve(result);
    });
  });

  await fsp.writeFile(outputPath, gzipped);
}

async function pruneOldBackups() {
  const files = await listBackupFiles();
  if (files.length <= MAX_BACKUPS) return;
  const extra = files.slice(MAX_BACKUPS);
  await Promise.all(
    extra.map((file) =>
      fsp.unlink(path.join(BACKUP_DIR, file.filename)).catch(() => {})
    )
  );
}

async function listBackupFiles() {
  await ensureBackupDir();
  const names = await fsp.readdir(BACKUP_DIR);
  const files = [];
  for (const name of names) {
    if (!isSafeBackupName(name)) continue;
    const fullPath = path.join(BACKUP_DIR, name);
    const stat = await fsp.stat(fullPath);
    if (!stat.isFile()) continue;
    files.push({
      filename: name,
      size: stat.size,
      createdAt: stat.mtime.toISOString(),
    });
  }
  files.sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
  return files;
}

async function createBackup() {
  if (backupInProgress) {
    const error = new Error("A backup is already in progress.");
    error.code = "BACKUP_IN_PROGRESS";
    throw error;
  }

  backupInProgress = true;
  const filename = backupFileName();
  const outputPath = path.join(BACKUP_DIR, filename);

  try {
    await ensureBackupDir();
    let method = "mysqldump";
    try {
      await runMysqldump(outputPath);
    } catch (dumpError) {
      logger.warn("mysqldump failed, using SQL fallback", {
        message: dumpError.message,
      });
      method = "sql";
      await dumpViaMysql2(outputPath);
    }

    const stat = await fsp.stat(outputPath);
    if (!stat.size) {
      throw new Error("Backup file is empty.");
    }

    await pruneOldBackups();
    return {
      filename,
      path: outputPath,
      size: stat.size,
      createdAt: stat.mtime.toISOString(),
      database: process.env.DB_NAME,
      method,
    };
  } catch (error) {
    await fsp.unlink(outputPath).catch(() => {});
    throw error;
  } finally {
    backupInProgress = false;
  }
}

function getBackupPath(filename) {
  if (!isSafeBackupName(filename)) {
    const error = new Error("Invalid backup filename.");
    error.code = "INVALID_FILENAME";
    throw error;
  }
  return path.join(BACKUP_DIR, filename);
}

async function deleteBackup(filename) {
  const fullPath = getBackupPath(filename);
  await fsp.unlink(fullPath);
}

module.exports = {
  BACKUP_DIR,
  createBackup,
  listBackupFiles,
  getBackupPath,
  deleteBackup,
  isSafeBackupName,
  isBackupInProgress: () => backupInProgress,
};
