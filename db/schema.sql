-- SQLite Schema for Claude Code Checkpoint System
-- This schema replaces the markdown-based checkpoint system with a more efficient SQLite database

-- Configuration table - Stores system configuration values
CREATE TABLE config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- Insert default configuration values
INSERT INTO config (key, value) VALUES
  ('checkpoint_enabled', 'true'),
  ('detailed_logging', 'true'),
  ('auto_resume', 'true'),
  ('auto_proceed', 'true'),
  ('db_version', '1');

-- Tasks table - Stores information about tasks
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'in_progress', -- 'in_progress', 'completed', 'failed'
  created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);

-- Task Steps table - Stores steps for each task
CREATE TABLE steps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'completed', 'failed'
  command TEXT,
  error_message TEXT,
  timestamp TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  FOREIGN KEY (task_id) REFERENCES tasks(id)
);

-- Command History table - Stores command execution history
CREATE TABLE commands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER,
  command TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'success', -- 'success', 'failed'
  exit_code INTEGER,
  timestamp TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  FOREIGN KEY (task_id) REFERENCES tasks(id)
);

-- Error Logs table - Stores detailed error information
CREATE TABLE errors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER,
  step_id INTEGER,
  command_id INTEGER,
  message TEXT NOT NULL,
  recovery_status TEXT DEFAULT 'pending', -- 'pending', 'resolved'
  timestamp TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  FOREIGN KEY (task_id) REFERENCES tasks(id),
  FOREIGN KEY (step_id) REFERENCES steps(id),
  FOREIGN KEY (command_id) REFERENCES commands(id)
);

-- Current Status view - Shows the current active task and step
CREATE VIEW current_status AS
SELECT 
  t.name AS task_name, 
  t.description AS task_description, 
  t.status AS task_status,
  s.description AS last_step,
  s.status AS last_step_status,
  c.command AS last_command
FROM tasks t
LEFT JOIN steps s ON t.id = s.task_id
LEFT JOIN commands c ON t.id = c.task_id
WHERE t.status = 'in_progress'
ORDER BY s.timestamp DESC, c.timestamp DESC
LIMIT 1;

-- Create indices for performance
CREATE INDEX idx_steps_task_id ON steps(task_id);
CREATE INDEX idx_commands_task_id ON commands(task_id);
CREATE INDEX idx_errors_task_id ON errors(task_id);