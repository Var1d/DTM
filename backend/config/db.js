const mysql = require('mysql2/promise');

const parseDatabaseUrl = (databaseUrl) => {
  if (!databaseUrl) return null;

  try {
    const url = new URL(databaseUrl);

    return {
      host: url.hostname,
      port: Number(url.port) || 3306,
      user: decodeURIComponent(url.username || 'root'),
      password: decodeURIComponent(url.password || ''),
      database: decodeURIComponent(url.pathname.replace(/^\//, '') || 'daily_task_manager'),
    };
  } catch (err) {
    throw new Error('DATABASE_URL/MYSQL_URL/DB_HOST tidak valid. Gunakan format mysql://user:password@host:port/database.');
  }
};

const dbHost = process.env.DB_HOST || '';
const databaseUrl =
  process.env.DATABASE_URL ||
  process.env.MYSQL_URL ||
  (dbHost.startsWith('mysql://') || dbHost.startsWith('mysql2://') ? dbHost : null);

const connectionConfig = parseDatabaseUrl(databaseUrl) || {
  host:     process.env.DB_HOST     || 'localhost',
  port:     Number(process.env.DB_PORT) || 3306,
  user:     process.env.DB_USER     || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME     || 'daily_task_manager',
};

const pool = mysql.createPool({
  ...connectionConfig,
  dateStrings: true,
  waitForConnections: true,
  connectionLimit:    10,
});

module.exports = pool;
