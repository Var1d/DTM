export const formatDate = (dateStr) => {
  if (!dateStr) return '-';
  return new Date(dateStr).toLocaleDateString('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
  });
};

export const timeAgo = (dateStr) => {
  if (!dateStr) return '-';
  const diff = new Date(dateStr) - new Date();
  const days = Math.ceil(diff / (1000 * 60 * 60 * 24));
  const hours = Math.ceil(diff / (1000 * 60 * 60));
  if (diff < 0) return `Terlambat ${Math.abs(days)} hari`;
  if (days <= 0) return `${hours} jam lagi`;
  if (days === 1) return 'Besok';
  return `${days} hari lagi`;
};

export const priorityConfig = (priority) => ({
  overdue: { bg: '#fee2e2', text: '#dc2626', label: 'Terlambat' },
  critical: { bg: '#ffedd5', text: '#ea580c', label: 'Kritis' },
  high: { bg: '#fef3c7', text: '#d97706', label: 'Tinggi' },
  medium: { bg: '#fefce8', text: '#ca8a04', label: 'Sedang' },
  low: { bg: '#dcfce7', text: '#16a34a', label: 'Rendah' },
  none: { bg: '#f3f4f6', text: '#6b7280', label: 'Tanpa Deadline' },
}[priority] ?? { bg: '#f3f4f6', text: '#6b7280', label: '-' });
