const webPush = require('web-push');
const db = require('../config/db');
const { toMysqlDateTime } = require('../utils/dateTimeHelper');

const vapidPublicKey = process.env.VAPID_PUBLIC_KEY;
const vapidPrivateKey = process.env.VAPID_PRIVATE_KEY;
const vapidSubject = process.env.VAPID_SUBJECT || 'mailto:admin@example.com';

const isPushConfigured = () => Boolean(vapidPublicKey && vapidPrivateKey);

if (isPushConfigured()) {
  webPush.setVapidDetails(vapidSubject, vapidPublicKey, vapidPrivateKey);
} else {
  console.warn('Web Push belum aktif. Isi VAPID_PUBLIC_KEY dan VAPID_PRIVATE_KEY di .env.');
}

const ensureNotificationTables = async () => {
  await db.query(`
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
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);

  await db.query(`
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
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);
};

const toSubscription = (row) => ({
  endpoint: row.endpoint,
  expirationTime: row.expiration_time,
  keys: {
    p256dh: row.p256dh,
    auth: row.auth,
  },
});

const saveSubscription = async (userId, subscription, userAgent) => {
  const endpoint = subscription?.endpoint;
  const p256dh = subscription?.keys?.p256dh;
  const auth = subscription?.keys?.auth;

  if (!endpoint || !p256dh || !auth) {
    const err = new Error('Subscription tidak valid');
    err.statusCode = 400;
    throw err;
  }

  const [existing] = await db.query(
    'SELECT id FROM push_subscriptions WHERE user_id = ? AND endpoint = ? LIMIT 1',
    [userId, endpoint]
  );

  if (existing.length > 0) {
    await db.query(
      `UPDATE push_subscriptions
       SET p256dh = ?, auth = ?, expiration_time = ?, user_agent = ?
       WHERE id = ?`,
      [p256dh, auth, subscription.expirationTime || null, userAgent || null, existing[0].id]
    );
    return existing[0].id;
  }

  const [result] = await db.query(
    `INSERT INTO push_subscriptions
     (user_id, endpoint, p256dh, auth, expiration_time, user_agent)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [userId, endpoint, p256dh, auth, subscription.expirationTime || null, userAgent || null]
  );
  return result.insertId;
};

const removeSubscription = async (userId, endpoint) => {
  if (!endpoint) return;
  await db.query('DELETE FROM push_subscriptions WHERE user_id = ? AND endpoint = ?', [userId, endpoint]);
};

const removeBrokenSubscription = async (endpoint) => {
  await db.query('DELETE FROM push_subscriptions WHERE endpoint = ?', [endpoint]);
};

const sendToUser = async (userId, payload) => {
  if (!isPushConfigured()) {
    const err = new Error('Web Push belum dikonfigurasi');
    err.statusCode = 503;
    throw err;
  }

  const [subscriptions] = await db.query('SELECT * FROM push_subscriptions WHERE user_id = ?', [userId]);
  if (subscriptions.length === 0) return { sent: 0 };

  let sent = 0;
  await Promise.all(
    subscriptions.map(async (row) => {
      try {
        await webPush.sendNotification(toSubscription(row), JSON.stringify(payload));
        sent += 1;
        await db.query('UPDATE push_subscriptions SET last_success_at = CURRENT_TIMESTAMP WHERE id = ?', [row.id]);
      } catch (err) {
        if (err.statusCode === 404 || err.statusCode === 410) {
          await removeBrokenSubscription(row.endpoint);
        } else {
          console.error('Gagal mengirim push:', err.message);
        }
      }
    })
  );

  return { sent };
};

const processDueReminders = async () => {
  if (!isPushConfigured()) return;

  const [tasks] = await db.query(`
    SELECT
      t.id,
      t.user_id,
      t.title,
      t.deadline,
      COALESCE(t.reminder_at, DATE_SUB(t.deadline, INTERVAL 1 HOUR)) AS reminder_at,
      c.name AS course_name
    FROM tasks t
    LEFT JOIN courses c ON c.id = t.course_id
    WHERE t.is_deleted = 0
      AND t.status <> 'done'
      AND t.deadline IS NOT NULL
      AND COALESCE(t.reminder_at, DATE_SUB(t.deadline, INTERVAL 1 HOUR)) <= ?
      AND NOT EXISTS (
        SELECT 1
        FROM task_push_notifications n
        WHERE n.task_id = t.id
          AND n.user_id = t.user_id
          AND n.reminder_at = COALESCE(t.reminder_at, DATE_SUB(t.deadline, INTERVAL 1 HOUR))
      )
    ORDER BY COALESCE(t.reminder_at, DATE_SUB(t.deadline, INTERVAL 1 HOUR)) ASC
    LIMIT 50
  `, [toMysqlDateTime(new Date())]);

  for (const task of tasks) {
    const bodyParts = [];
    if (task.course_name) bodyParts.push(task.course_name);
    if (task.deadline) bodyParts.push(`Deadline: ${new Date(task.deadline).toLocaleString('id-ID')}`);

    const result = await sendToUser(task.user_id, {
      title: `Pengingat: ${task.title}`,
      body: bodyParts.join(' - ') || 'Ada tugas yang perlu dikerjakan.',
      url: '/',
      tag: `task-${task.id}`,
      data: { taskId: task.id },
    });

    if (result.sent > 0) {
      await db.query(
        `INSERT IGNORE INTO task_push_notifications (user_id, task_id, reminder_at)
         VALUES (?, ?, ?)`,
        [task.user_id, task.id, task.reminder_at]
      );
    }
  }
};

const startReminderWorker = () => {
  const intervalMs = Number(process.env.PUSH_REMINDER_INTERVAL_MS || 60000);
  processDueReminders().catch((err) => console.error('Reminder push worker error:', err.message));
  setInterval(() => {
    processDueReminders().catch((err) => console.error('Reminder push worker error:', err.message));
  }, intervalMs);
};

module.exports = {
  ensureNotificationTables,
  isPushConfigured,
  processDueReminders,
  removeSubscription,
  saveSubscription,
  sendToUser,
  startReminderWorker,
  vapidPublicKey,
};
