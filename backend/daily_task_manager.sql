-- ============================================
-- DATABASE: Daily Task Manager
-- Platform: MySQL
-- Project : Tugas Besar - Pengembangan Aplikasi Berbasis Platform
-- Versi 2  : Priority dihitung dinamis dari deadline (tidak disimpan di DB)
-- ============================================

CREATE DATABASE IF NOT EXISTS daily_task_manager
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE daily_task_manager;

-- ============================================
-- TABEL: users
-- ============================================
CREATE TABLE users (
  id          INT PRIMARY KEY AUTO_INCREMENT,
  name        VARCHAR(100)  NOT NULL,
  email       VARCHAR(100)  NOT NULL UNIQUE,
  password    VARCHAR(255)  NOT NULL,
  avatar_url  VARCHAR(255)  DEFAULT NULL,
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABEL: refresh_tokens
-- ============================================
CREATE TABLE refresh_tokens (
  id          INT PRIMARY KEY AUTO_INCREMENT,
  user_id     INT           NOT NULL,
  token       VARCHAR(512)  NOT NULL,
  expires_at  TIMESTAMP     NOT NULL,
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_rt_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABEL: categories
-- ============================================
CREATE TABLE categories (
  id          INT PRIMARY KEY AUTO_INCREMENT,
  user_id     INT           NOT NULL,
  name        VARCHAR(100)  NOT NULL,
  color       VARCHAR(7)    DEFAULT '#6366f1',
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_cat_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABEL: tasks
-- Catatan: kolom 'priority' DIHAPUS karena dihitung
--          secara dinamis di backend berdasarkan deadline.
--          Kolom 'reminder_at' juga dihitung otomatis
--          dari deadline jika tidak diisi manual.
-- ============================================
CREATE TABLE tasks (
  id            INT PRIMARY KEY AUTO_INCREMENT,
  user_id       INT           NOT NULL,
  category_id   INT           DEFAULT NULL,
  parent_id     INT           DEFAULT NULL,
  title         VARCHAR(255)  NOT NULL,
  description   TEXT          DEFAULT NULL,
  status        ENUM('todo', 'in_progress', 'done') DEFAULT 'todo',
  deadline      DATETIME      DEFAULT NULL,
  reminder_at   DATETIME      DEFAULT NULL,
  is_deleted    TINYINT(1)    DEFAULT 0,
  created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_task_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_task_category
    FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE SET NULL,

  CONSTRAINT fk_task_parent
    FOREIGN KEY (parent_id) REFERENCES tasks(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- INDEX (untuk performa query)
-- ============================================
CREATE INDEX idx_tasks_user_id      ON tasks(user_id);
CREATE INDEX idx_tasks_category_id  ON tasks(category_id);
CREATE INDEX idx_tasks_parent_id    ON tasks(parent_id);
CREATE INDEX idx_tasks_status       ON tasks(status);
CREATE INDEX idx_tasks_deadline     ON tasks(deadline);
CREATE INDEX idx_tasks_is_deleted   ON tasks(is_deleted);
CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_rt_user_id         ON refresh_tokens(user_id);

-- ============================================
-- DATA DUMMY (opsional, untuk testing)
-- ============================================

-- User dummy (password: "rahasia123" di-hash dengan bcrypt)
INSERT INTO users (name, email, password) VALUES
('Rrr',   'rrr@email.com',   '$2b$10$examplehashedpassword1234567890abcdef'),
('Farid', 'farid@email.com', '$2b$10$examplehashedpassword0987654321fedcba');

-- Kategori default mahasiswa untuk user id=1 (otomatis dibuat saat register)
INSERT INTO categories (user_id, name, color) VALUES
(1, 'Kuliah',     '#6366f1'),
(1, 'Tugas',      '#f59e0b'),
(1, 'Ujian',      '#ef4444'),
(1, 'Organisasi', '#22c55e');

-- Task utama dummy (tanpa kolom priority)
INSERT INTO tasks (user_id, category_id, parent_id, title, description, status, deadline, reminder_at) VALUES
(1, 1, NULL, 'Buat laporan praktikum',   'Laporan jaringan komputer pertemuan 5',       'in_progress', '2026-05-10 23:59:00', NULL),
(1, 2, NULL, 'Kerjakan tugas besar PABP','Aplikasi multiplatform Daily Task Manager',   'todo',        '2026-06-30 23:59:00', NULL),
(1, 1, NULL, 'Belajar untuk UTS',        'Materi Data Mining dan Jaringan Komputer',    'todo',        '2026-05-05 08:00:00', NULL);

-- Sub-task dari task id=1 (Laporan praktikum)
INSERT INTO tasks (user_id, category_id, parent_id, title, status) VALUES
(1, 1, 1, 'Foto dokumentasi praktikum', 'done'),
(1, 1, 1, 'Tulis pembahasan',           'todo'),
(1, 1, 1, 'Buat kesimpulan',            'todo');

-- Sub-task dari task id=2 (Tugas Besar)
INSERT INTO tasks (user_id, category_id, parent_id, title, status) VALUES
(1, 2, 2, 'Setup repository Git',    'done'),
(1, 2, 2, 'Buat backend Node.js',    'in_progress'),
(1, 2, 2, 'Buat Flutter mobile app', 'todo'),
(1, 2, 2, 'Buat web client React',   'todo');
