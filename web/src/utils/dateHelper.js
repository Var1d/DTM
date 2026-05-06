export const parseLocalDateTime = (dateStr) => {
  if (!dateStr) return null;
  if (dateStr instanceof Date) return dateStr;

  const text = String(dateStr).trim();
  const match = text.match(/^(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2})(?::(\d{2}))?/);
  if (!match) {
    const fallback = new Date(text);
    return Number.isNaN(fallback.getTime()) ? null : fallback;
  }

  const [, year, month, day, hour, minute, second = '0'] = match.map(Number);
  return new Date(year, month - 1, day, hour, minute, second);
};

export const toDateTimeLocalValue = (dateStr) => {
  if (!dateStr) return '';
  const text = String(dateStr).trim();
  const match = text.match(/^(\d{4}-\d{2}-\d{2})[T\s](\d{2}:\d{2})/);
  if (match) return `${match[1]}T${match[2]}`;

  const date = parseLocalDateTime(text);
  if (!date) return '';
  const pad = (number) => String(number).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
};

export const formatDate = (dateStr) => {
  if (!dateStr) return '-';
  const date = parseLocalDateTime(dateStr);
  if (!date) return '-';
  return date.toLocaleDateString('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
  });
};

export const timeAgo = (dateStr) => {
  if (!dateStr) return '-';
  const date = parseLocalDateTime(dateStr);
  if (!date) return '-';

  const now = new Date();
  const diff = date - now;
  const minuteMs = 1000 * 60;
  const hourMs = minuteMs * 60;
  const dayMs = hourMs * 24;

  if (diff < 0) {
    const overdue = Math.abs(diff);
    if (overdue < hourMs) return `Terlambat ${Math.max(1, Math.ceil(overdue / minuteMs))} menit`;
    if (overdue < dayMs) return `Terlambat ${Math.ceil(overdue / hourMs)} jam`;
    return `Terlambat ${Math.ceil(overdue / dayMs)} hari`;
  }

  if (diff < hourMs) return `${Math.max(1, Math.ceil(diff / minuteMs))} menit lagi`;
  if (diff < dayMs) return `${Math.ceil(diff / hourMs)} jam lagi`;

  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const deadlineDay = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const calendarDays = Math.round((deadlineDay - today) / dayMs);

  if (calendarDays === 1) return 'Besok';
  return `${calendarDays} hari lagi`;
};

export const priorityConfig = (priority) => ({
  overdue: { bg: '#fee2e2', text: '#dc2626', label: 'Terlambat' },
  critical: { bg: '#ffedd5', text: '#ea580c', label: 'Kritis' },
  high: { bg: '#fef3c7', text: '#d97706', label: 'Tinggi' },
  medium: { bg: '#fefce8', text: '#ca8a04', label: 'Sedang' },
  low: { bg: '#dcfce7', text: '#16a34a', label: 'Rendah' },
  none: { bg: '#f3f4f6', text: '#6b7280', label: 'Tanpa Deadline' },
}[priority] ?? { bg: '#f3f4f6', text: '#6b7280', label: '-' });
