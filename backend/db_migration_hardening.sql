-- Migration hardening untuk database existing
USE daily_task_manager;

-- 1) Bersihkan duplikasi token (jaga token terbaru), lalu pasang UNIQUE
DELETE rt1
FROM refresh_tokens rt1
JOIN refresh_tokens rt2
  ON rt1.token = rt2.token
 AND rt1.id < rt2.id;

ALTER TABLE refresh_tokens
  ADD CONSTRAINT uq_refresh_token UNIQUE (token);

-- 2) Tambah CHECK constraints
ALTER TABLE courses
  ADD CONSTRAINT chk_course_credit CHECK (credit BETWEEN 1 AND 6),
  ADD CONSTRAINT chk_course_time CHECK (start_time IS NULL OR end_time IS NULL OR start_time < end_time),
  ADD CONSTRAINT chk_course_color CHECK (color REGEXP '^#[0-9A-Fa-f]{6}$');

ALTER TABLE tasks
  ADD CONSTRAINT chk_task_grade_weight CHECK (grade_weight BETWEEN 0 AND 100),
  ADD CONSTRAINT chk_task_achieved_score CHECK (achieved_score IS NULL OR achieved_score BETWEEN 0 AND 100),
  ADD CONSTRAINT chk_task_deleted CHECK (is_deleted IN (0, 1)),
  ADD CONSTRAINT chk_task_reminder_deadline CHECK (reminder_at IS NULL OR deadline IS NULL OR reminder_at <= deadline);

-- 3) Index komposit untuk performa listing/filter
CREATE INDEX idx_courses_user_day_time ON courses(user_id, day, start_time);
CREATE INDEX idx_tasks_listing ON tasks(user_id, is_deleted, parent_id, deadline, created_at);
CREATE INDEX idx_tasks_filter_course_status ON tasks(user_id, course_id, status, is_deleted);
CREATE INDEX idx_rt_expiry ON refresh_tokens(expires_at);

-- 4) Trigger integritas owner untuk tasks
DROP TRIGGER IF EXISTS trg_tasks_course_owner_ins;
DROP TRIGGER IF EXISTS trg_tasks_course_owner_upd;

DELIMITER $$
CREATE TRIGGER trg_tasks_course_owner_ins
BEFORE INSERT ON tasks
FOR EACH ROW
BEGIN
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
