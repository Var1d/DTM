const APP_TIMEZONE_OFFSET_MINUTES = Number(process.env.APP_TIMEZONE_OFFSET_MINUTES || 420);

const pad = (number) => String(number).padStart(2, '0');

const normalizeDateTimeInput = (value) => {
  if (!value) return null;
  if (value instanceof Date) return toMysqlDateTime(value);

  const text = String(value).trim();
  const match = text.match(/^(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2})(?::(\d{2}))?/);
  if (!match) return text;

  const [, year, month, day, hour, minute, second = '00'] = match;
  return `${year}-${month}-${day} ${hour}:${minute}:${second}`;
};

const parseLocalDateTime = (value) => {
  const normalized = normalizeDateTimeInput(value);
  if (!normalized) return null;

  const match = normalized.match(/^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})/);
  if (!match) {
    const date = new Date(normalized);
    return Number.isNaN(date.getTime()) ? null : date;
  }

  const [, year, month, day, hour, minute, second] = match.map(Number);
  const utcMs = Date.UTC(year, month - 1, day, hour, minute, second) - APP_TIMEZONE_OFFSET_MINUTES * 60 * 1000;
  return new Date(utcMs);
};

const toMysqlDateTime = (date) => {
  if (!date) return null;
  const value = date instanceof Date ? date : new Date(date);
  if (Number.isNaN(value.getTime())) return null;

  const localMs = value.getTime() + APP_TIMEZONE_OFFSET_MINUTES * 60 * 1000;
  const local = new Date(localMs);

  return `${local.getUTCFullYear()}-${pad(local.getUTCMonth() + 1)}-${pad(local.getUTCDate())} ` +
    `${pad(local.getUTCHours())}:${pad(local.getUTCMinutes())}:${pad(local.getUTCSeconds())}`;
};

module.exports = {
  APP_TIMEZONE_OFFSET_MINUTES,
  normalizeDateTimeInput,
  parseLocalDateTime,
  toMysqlDateTime,
};
