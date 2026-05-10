import { useEffect, useMemo, useState } from 'react';
import PriorityBadge from '../../components/task/PriorityBadge';
import { useTask } from '../../context/TaskContext';
import { formatDate, parseLocalDateTime } from '../../utils/dateHelper';
import TaskDetailModal from '../tasks/TaskDetailModal';

const WEEKDAYS = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
const MONTHS_ID = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const SORT_OPTIONS = [
  { value: 'smart', label: 'Prioritas' },
  { value: 'deadline', label: 'Deadline' },
  { value: 'grade', label: 'Bobot' },
  { value: 'alphabet', label: 'A-Z' },
];

const toDateKey = (date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
const isSameDay = (a, b) => a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();

const priorityWeight = (task) => {
  if (task.status === 'done') return -1;
  const map = { overdue: 5, critical: 4, high: 3, medium: 2, low: 1 };
  return map[task.priority] ?? 0;
};

const compareDeadline = (a, b) => {
  const ad = parseLocalDateTime(a?.deadline);
  const bd = parseLocalDateTime(b?.deadline);
  if (!ad && !bd) return 0;
  if (!ad) return 1;
  if (!bd) return -1;
  return ad - bd;
};

export default function CalendarPage() {
  const { tasks, loading, fetchTasks } = useTask();
  const [currentMonth, setCurrentMonth] = useState(() => {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), 1);
  });
  const [selectedDay, setSelectedDay] = useState(() => new Date());
  const [sortBy, setSortBy] = useState('smart');
  const [sortAsc, setSortAsc] = useState(true);
  const [selectedTaskId, setSelectedTaskId] = useState(null);

  useEffect(() => {
    fetchTasks();
  }, [fetchTasks]);

  const tasksWithDeadline = useMemo(
    () => tasks.filter((task) => parseLocalDateTime(task.deadline)),
    [tasks],
  );

  const byDateMap = useMemo(() => {
    const map = new Map();
    tasksWithDeadline.forEach((task) => {
      const deadline = parseLocalDateTime(task.deadline);
      if (!deadline) return;
      const key = toDateKey(deadline);
      const list = map.get(key) || [];
      list.push(task);
      map.set(key, list);
    });
    return map;
  }, [tasksWithDeadline]);

  const days = useMemo(() => {
    const year = currentMonth.getFullYear();
    const month = currentMonth.getMonth();
    const first = new Date(year, month, 1);
    const start = new Date(first);
    start.setDate(first.getDate() - first.getDay());

    return Array.from({ length: 42 }, (_, idx) => {
      const d = new Date(start);
      d.setDate(start.getDate() + idx);
      return d;
    });
  }, [currentMonth]);

  const selectedTasks = useMemo(() => {
    const key = toDateKey(selectedDay);
    const dayTasks = [...(byDateMap.get(key) || [])];

    dayTasks.sort((a, b) => {
      let cmp = 0;
      if (sortBy === 'smart') {
        cmp = priorityWeight(b) - priorityWeight(a);
        if (cmp === 0) cmp = compareDeadline(a, b);
      } else if (sortBy === 'deadline') {
        cmp = compareDeadline(a, b);
      } else if (sortBy === 'grade') {
        cmp = Number(a.grade_weight || 0) - Number(b.grade_weight || 0);
      } else {
        cmp = String(a.title || '').localeCompare(String(b.title || ''), 'id', { sensitivity: 'base' });
      }
      return sortAsc ? cmp : -cmp;
    });

    return dayTasks;
  }, [byDateMap, selectedDay, sortBy, sortAsc]);

  const selectedTask = tasks.find((task) => task.id === selectedTaskId);

  return (
    <div className="page-shell">
      <div className="glass-card calendar-page-head">
        <h2 style={{ margin: 0 }}>Kalender Akademik</h2>
        <p style={{ color: 'var(--text-muted)', margin: '6px 0 0' }}>Pantau tenggat tugasmu secara visual per tanggal.</p>
      </div>

      <div className="glass-card calendar-box">
        <div className="calendar-header">
          <button type="button" className="btn btn-outline" onClick={() => setCurrentMonth((prev) => new Date(prev.getFullYear(), prev.getMonth() - 1, 1))}>
            &lt;
          </button>
          <h3 style={{ margin: 0 }}>{MONTHS_ID[currentMonth.getMonth()]} {currentMonth.getFullYear()}</h3>
          <button type="button" className="btn btn-outline" onClick={() => setCurrentMonth((prev) => new Date(prev.getFullYear(), prev.getMonth() + 1, 1))}>
            &gt;
          </button>
        </div>

        <div className="calendar-grid">
          {WEEKDAYS.map((name) => <div key={name} className="calendar-weekday">{name}</div>)}
          {days.map((day) => {
            const key = toDateKey(day);
            const dayTasks = byDateMap.get(key) || [];
            const inCurrentMonth = day.getMonth() === currentMonth.getMonth();
            const today = isSameDay(day, new Date());
            const selected = isSameDay(day, selectedDay);

            return (
              <button
                key={key}
                type="button"
                className={`calendar-day ${inCurrentMonth ? '' : 'muted'} ${today ? 'today' : ''} ${selected ? 'selected' : ''}`}
                onClick={() => setSelectedDay(day)}
              >
                <span className="calendar-day-number">{day.getDate()}</span>
                <span className="calendar-dots">
                  {dayTasks.slice(0, 4).map((task) => (
                    <span key={task.id} className={`calendar-dot ${task.status === 'done' ? 'done' : ''}`} />
                  ))}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      <div className="calendar-task-head">
        <p style={{ margin: 0, color: 'var(--text-muted)' }}>
          {selectedTasks.length === 0 ? 'Tidak ada tugas' : `${selectedTasks.length} tugas`}
        </p>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <select className="btn btn-outline" value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
            {SORT_OPTIONS.map((opt) => <option key={opt.value} value={opt.value}>{opt.label}</option>)}
          </select>
          <button type="button" className="btn btn-ghost" onClick={() => setSortAsc((prev) => !prev)}>
            {sortAsc ? 'Asc' : 'Desc'}
          </button>
        </div>
      </div>

      {loading ? (
        <div className="glass-card" style={{ padding: 20 }}>Memuat tugas...</div>
      ) : selectedTasks.length === 0 ? (
        <div className="glass-card empty-state">
          <h3>Tidak ada tugas di tanggal ini</h3>
          <p>Pilih tanggal lain di kalender untuk melihat daftar tugas.</p>
        </div>
      ) : (
        <div className="calendar-task-list">
          {selectedTasks.map((task) => (
            <button key={task.id} type="button" className="glass-card calendar-task-card" onClick={() => setSelectedTaskId(task.id)}>
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 10, alignItems: 'flex-start' }}>
                <div>
                  <h4 className="task-title" style={{ margin: 0 }}>{task.title}</h4>
                  {task.course_name && (
                    <p style={{ margin: '4px 0 0', color: 'var(--text-muted)', fontSize: 13 }}>{task.course_name}</p>
                  )}
                </div>
                <PriorityBadge priority={task.priority} />
              </div>
              <p style={{ margin: '10px 0 0', color: 'var(--text-muted)', fontSize: 13 }}>Deadline: {formatDate(task.deadline)}</p>
            </button>
          ))}
        </div>
      )}

      {selectedTask && (
        <TaskDetailModal
          task={selectedTask}
          onClose={() => setSelectedTaskId(null)}
          onEdit={() => setSelectedTaskId(null)}
        />
      )}
    </div>
  );
}
