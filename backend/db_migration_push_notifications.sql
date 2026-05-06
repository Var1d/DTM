-- Migration Web Push Notification untuk database existing
USE daily_task_manager;

CREATE TABLE IF NOT EXISTS push_subscriptions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  endpoint TEXT NOT NULL,
  p256dh VARCHAR(255) NOT NULL,
  auth VARCHAR(255) NOT NULL,
  expiration_time BIGINT DEFAULT NULL,
  user_agent VARCHAR(255) DEFAULT NULL,
  last_success_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_push_subscription_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS task_push_notifications (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  task_id INT NOT NULL,
  reminder_at DATETIME NOT NULL,
  sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_task_push_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_task_push_task
    FOREIGN KEY (task_id) REFERENCES tasks(id)
    ON DELETE CASCADE,

  CONSTRAINT uq_task_push_once UNIQUE (user_id, task_id, reminder_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
