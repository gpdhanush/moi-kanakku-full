-- Runtime configuration managed by the admin app.
-- Apply once to the active Moi Kanakku database.

CREATE TABLE IF NOT EXISTS app_runtime_config (
  id TINYINT UNSIGNED NOT NULL,
  live_url VARCHAR(500) NOT NULL,
  image_url VARCHAR(500) NOT NULL,
  maintenance_mode TINYINT(1) NOT NULL DEFAULT 0,
  min_app_version VARCHAR(32) NOT NULL DEFAULT '',
  updated_by BIGINT UNSIGNED NULL,

  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),

  CONSTRAINT fk_app_runtime_config_updated_by
    FOREIGN KEY (updated_by)
    REFERENCES admins(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
  
INSERT INTO app_runtime_config (id, live_url, image_url, maintenance_mode, min_app_version)
VALUES (
  1,
  'https://moi-api.floatwalktiruppur.in/apis',
  'https://moi-api.floatwalktiruppur.in',
  0,
  '5.0.0'
)
ON DUPLICATE KEY UPDATE id = id;
