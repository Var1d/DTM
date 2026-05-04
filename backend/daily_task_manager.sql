-- ============================================
-- DATABASE: Academic Task Manager
-- Platform: MySQL 8+
-- Project : Tugas Besar - Pengembangan Aplikasi Berbasis Platform
-- Fokus   : Produktivitas akademik mahasiswa
-- ============================================

CREATE DATABASE IF NOT EXISTS daily_task_manager
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE daily_task_manager;

CREATE TABLE users (
  id          INT PRIMARY KEY AUTO_INCREMENT,
  name        VARCHAR(100)  NOT NULL,
  email       VARCHAR(100)  NOT NULL UNIQUE,
  password    VARCHAR(255)  NOT NULL,
  avatar_url  VARCHAR(255)  DEFAULT NULL,
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE refresh_tokens (
  id          INT PRIMARY KEY AUTO_INCREMENT,
  user_id     INT           NOT NULL,
  token       VARCHAR(512)  NOT NULL,
  expires_at  TIMESTAMP     NOT NULL,
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT uq_refresh_token UNIQUE (token),
  CONSTRAINT fk_rt_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE courses (
  id          INT PRIMARY KEY AUTO_INCREMENT,
  user_id     INT           NOT NULL,
  name        VARCHAR(120)  NOT NULL,
  lecturer    VARCHAR(120)  DEFAULT NULL,
  room        VARCHAR(80)   DEFAULT NULL,
  day         ENUM('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu') DEFAULT NULL,
  start_time  TIME          DEFAULT NULL,
  end_time    TIME          DEFAULT NULL,
  credit      INT           DEFAULT 3,
  color       VARCHAR(7)    DEFAULT '#6366f1',
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_course_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,

  CONSTRAINT chk_course_credit CHECK (credit BETWEEN 1 AND 6),
  CONSTRAINT chk_course_time CHECK (start_time IS NULL OR end_time IS NULL OR start_time < end_time)
  -- NOTE: validasi format hex color (#RRGGBB) dipindah ke trigger karena
  -- REGEXP di dalam CHECK constraint di-parse MySQL tapi TIDAK dieksekusi (silent ignore).
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tasks (
  id              INT PRIMARY KEY AUTO_INCREMENT,
  user_id         INT           NOT NULL,
  course_id       INT           DEFAULT NULL,
  parent_id       INT           DEFAULT NULL,
  title           VARCHAR(255)  NOT NULL,
  description     TEXT          DEFAULT NULL,
  task_type       ENUM('assignment','quiz','mid_exam','final_exam','practicum','presentation','project','reading','other') DEFAULT 'assignment',
  status          ENUM('todo', 'in_progress', 'done') DEFAULT 'todo',
  difficulty      ENUM('easy','medium','hard') DEFAULT 'medium',
  grade_weight    DECIMAL(5,2)  DEFAULT 0.00,
  achieved_score  DECIMAL(5,2)  DEFAULT NULL,
  deadline        DATETIME      DEFAULT NULL,
  reminder_at     DATETIME      DEFAULT NULL,
  is_deleted      TINYINT(1)    DEFAULT 0,
  created_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_task_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_task_course
    FOREIGN KEY (course_id) REFERENCES courses(id)
    ON DELETE SET NULL,

  CONSTRAINT fk_task_parent
    FOREIGN KEY (parent_id) REFERENCES tasks(id)
    ON DELETE CASCADE,

  CONSTRAINT chk_task_grade_weight CHECK (grade_weight BETWEEN 0 AND 100),
  CONSTRAINT chk_task_achieved_score CHECK (achieved_score IS NULL OR achieved_score BETWEEN 0 AND 100),
  CONSTRAINT chk_task_deleted CHECK (is_deleted IN (0, 1)),
  -- chk_task_no_self_parent DIHAPUS: MySQL error #1901 melarang referensi kolom
  -- AUTO_INCREMENT (id) di dalam CHECK constraint. Guard ini sudah ditangani trigger.
  CONSTRAINT chk_task_reminder_deadline CHECK (reminder_at IS NULL OR deadline IS NULL OR reminder_at <= deadline)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_courses_user_id ON courses(user_id);
CREATE INDEX idx_courses_user_day_time ON courses(user_id, day, start_time);

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_course_id ON tasks(course_id);
CREATE INDEX idx_tasks_parent_id ON tasks(parent_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_deadline ON tasks(deadline);
CREATE INDEX idx_tasks_deleted ON tasks(is_deleted);
CREATE INDEX idx_tasks_listing ON tasks(user_id, is_deleted, parent_id, deadline, created_at);
CREATE INDEX idx_tasks_filter_course_status ON tasks(user_id, course_id, status, is_deleted);

CREATE INDEX idx_rt_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_rt_expiry ON refresh_tokens(expires_at);

-- Trigger guard: course_id pada task harus milik user yang sama.
-- Juga memvalidasi format hex color pada courses (karena REGEXP di CHECK tidak dieksekusi MySQL).
DELIMITER $$
CREATE TRIGGER trg_courses_color_ins
BEFORE INSERT ON courses
FOR EACH ROW
BEGIN
  IF NEW.color IS NOT NULL AND NEW.color NOT REGEXP '^#[0-9A-Fa-f]{6}$' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Format color tidak valid, gunakan format #RRGGBB';
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_courses_color_upd
BEFORE UPDATE ON courses
FOR EACH ROW
BEGIN
  IF NEW.color IS NOT NULL AND NEW.color NOT REGEXP '^#[0-9A-Fa-f]{6}$' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Format color tidak valid, gunakan format #RRGGBB';
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_tasks_course_owner_ins
BEFORE INSERT ON tasks
FOR EACH ROW
BEGIN
  -- [FIX] Guard self-parent ditambahkan di INSERT (sebelumnya hanya ada di UPDATE)
  IF NEW.parent_id IS NOT NULL AND NEW.parent_id = NEW.id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'parent_id tidak boleh sama dengan id task';
  END IF;

  IF NEW.course_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM courses c WHERE c.id = NEW.course_id AND c.user_id = NEW.user_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'course_id tidak valid untuk user ini';
  END IF;

  IF NEW.parent_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM tasks t WHERE t.id = NEW.parent_id AND t.user_id = NEW.user_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'parent_id tidak valid untuk user ini';
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_tasks_course_owner_upd
BEFORE UPDATE ON tasks
FOR EACH ROW
BEGIN
  IF NEW.parent_id IS NOT NULL AND NEW.parent_id = NEW.id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'parent_id tidak boleh sama dengan id task';
  END IF;

  IF NEW.course_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM courses c WHERE c.id = NEW.course_id AND c.user_id = NEW.user_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'course_id tidak valid untuk user ini';
  END IF;

  IF NEW.parent_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM tasks t WHERE t.id = NEW.parent_id AND t.user_id = NEW.user_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'parent_id tidak valid untuk user ini';
  END IF;
END$$
DELIMITER ;

-- Opsional untuk development: seed data. Jangan dipakai di production.
INSERT INTO users (name, email, password) VALUES
('Farid', 'farid@email.com', '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ12345');
-- ^ Hash di atas adalah PLACEHOLDER 60-char. Ganti dengan hash bcrypt asli sebelum deploy.

INSERT INTO courses (user_id, name, lecturer, room, day, start_time, end_time, credit, color) VALUES
(1, 'Pengembangan Aplikasi Berbasis Platform', 'Dosen PABP', 'Lab Komputer', 'Senin', '08:00:00', '09:40:00', 3, '#6366f1'),
(1, 'Basis Data', 'Dosen Basis Data', 'Ruang 204', 'Rabu', '10:00:00', '11:40:00', 3, '#14b8a6'),
(1, 'Statistika', 'Dosen Statistika', 'Ruang 301', 'Jumat', '13:00:00', '14:40:00', 2, '#f59e0b');

INSERT INTO tasks
(user_id, course_id, parent_id, title, description, task_type, status, difficulty, grade_weight, achieved_score, deadline, reminder_at)
VALUES
(1, 1, NULL, 'UAS aplikasi Academic Task Manager', 'Finalisasi mobile dan backend untuk UAS PABP', 'final_exam', 'in_progress', 'hard', 40.00, NULL, '2026-06-30 23:59:00', NULL),
(1, 2, NULL, 'Laporan normalisasi database', 'Normalisasi dan ERD sistem akademik', 'assignment', 'todo', 'medium', 15.00, NULL, '2026-05-10 23:59:00', NULL),
(1, 3, NULL, 'Kuis probabilitas', 'Latihan distribusi peluang', 'quiz', 'todo', 'medium', 10.00, NULL, '2026-05-05 08:00:00', NULL);

INSERT INTO tasks (user_id, course_id, parent_id, title, task_type, status, difficulty) VALUES
(1, 1, 1, 'Rancang schema akademik', 'project', 'done', 'medium'),
(1, 1, 1, 'Implementasi smart priority', 'project', 'in_progress', 'hard'),
(1, 1, 1, 'Testing aplikasi mobile', 'project', 'todo', 'medium');
