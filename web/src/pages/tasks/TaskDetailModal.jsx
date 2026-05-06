import { useState } from 'react';
import Button from '../../components/common/Button';
import PriorityBadge from '../../components/task/PriorityBadge';
import { useTask } from '../../context/TaskContext';
import { formatDate } from '../../utils/dateHelper';

const DIFFICULTIES = [
  ['easy', 'Mudah'],
  ['medium', 'Sedang'],
  ['hard', 'Sulit'],
];

export default function TaskDetailModal({ task, onClose, onEdit }) {
  const { createTask, updateStatus, fetchTasks } = useTask();
  const [form, setForm] = useState({ title: '', description: '', difficulty: 'medium' });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  if (!task) return null;

  const subTasks = task.sub_tasks || [];
  const progress = task.progress ?? 0;

  const handleAddSubtask = async (e) => {
    e.preventDefault();
    const title = form.title.trim();
    if (!title) return;

    setSaving(true);
    setError('');
    try {
      await createTask({
        title,
        description: form.description.trim() || null,
        parent_id: task.id,
        course_id: task.course_id || null,
        task_type: 'other',
        difficulty: form.difficulty,
        status: 'todo',
      });
      setForm({ title: '', description: '', difficulty: 'medium' });
      await fetchTasks();
    } catch (err) {
      setError(err.response?.data?.message || 'Gagal menambah subtask');
    } finally {
      setSaving(false);
    }
  };

  const handleToggleSubtask = async (subtask) => {
    await updateStatus(subtask.id, subtask.status === 'done' ? 'todo' : 'done');
    await fetchTasks();
  };

  return (
    <div className="modal-backdrop" onMouseDown={onClose}>
      <div className="glass-card modal-card" style={{ width: 680 }} onMouseDown={(e) => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'flex-start', marginBottom: 16 }}>
          <div>
            <h2 style={{ margin: 0 }}>{task.title}</h2>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 10 }}>
              <PriorityBadge priority={task.priority} />
              {task.course_name && (
                <span style={{ fontSize: 12, padding: '4px 9px', borderRadius: 999, background: task.course_color || 'var(--primary)', color: '#fff' }}>
                  {task.course_name}
                </span>
              )}
              <span style={{ fontSize: 12, padding: '4px 9px', borderRadius: 999, border: '1px solid var(--border)', color: 'var(--text-muted)' }}>
                {task.status}
              </span>
            </div>
          </div>
          <button type="button" className="btn btn-outline" style={{ padding: '6px 10px' }} onClick={onClose}>X</button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 10, marginBottom: 14 }}>
          <div className="glass-card" style={{ padding: 12, boxShadow: 'none' }}>
            <div style={{ color: 'var(--text-muted)', fontSize: 12 }}>Deadline</div>
            <strong>{formatDate(task.deadline)}</strong>
          </div>
          <div className="glass-card" style={{ padding: 12, boxShadow: 'none' }}>
            <div style={{ color: 'var(--text-muted)', fontSize: 12 }}>Smart Priority</div>
            <strong>{task.academic_priority?.label || '-'} ({task.academic_priority?.score ?? 0})</strong>
          </div>
          <div className="glass-card" style={{ padding: 12, boxShadow: 'none' }}>
            <div style={{ color: 'var(--text-muted)', fontSize: 12 }}>Bobot</div>
            <strong>{Number(task.grade_weight || 0).toFixed(0)}%</strong>
          </div>
        </div>

        {task.description && (
          <div style={{ marginBottom: 16 }}>
            <h3 style={{ margin: '0 0 6px' }}>Deskripsi</h3>
            <p style={{ margin: 0, color: 'var(--text-muted)' }}>{task.description}</p>
          </div>
        )}

        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 10, alignItems: 'center', marginBottom: 8 }}>
          <h3 style={{ margin: 0 }}>Subtask</h3>
          <span style={{ color: 'var(--text-muted)' }}>{progress}%</span>
        </div>
        <div style={{ height: 7, borderRadius: 999, background: 'var(--bg-soft)', border: '1px solid var(--border)', overflow: 'hidden', marginBottom: 10 }}>
          <div style={{ width: `${progress}%`, height: '100%', background: 'linear-gradient(135deg, var(--primary), var(--primary-2))' }} />
        </div>

        {subTasks.length === 0 ? (
          <p style={{ color: 'var(--text-muted)', marginTop: 0 }}>Belum ada subtask.</p>
        ) : (
          <div style={{ display: 'grid', gap: 8, marginBottom: 16 }}>
            {subTasks.map((subtask) => (
              <label key={subtask.id} className="glass-card" style={{ display: 'flex', alignItems: 'center', gap: 10, padding: 10, boxShadow: 'none', cursor: 'pointer' }}>
                <input type="checkbox" checked={subtask.status === 'done'} onChange={() => handleToggleSubtask(subtask)} />
                <span style={{ flex: 1, textDecoration: subtask.status === 'done' ? 'line-through' : 'none', color: subtask.status === 'done' ? 'var(--text-muted)' : 'var(--text)' }}>
                  {subtask.title}
                </span>
                <span style={{ color: 'var(--text-muted)', fontSize: 12 }}>{subtask.difficulty}</span>
              </label>
            ))}
          </div>
        )}

        <form onSubmit={handleAddSubtask}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 150px', gap: 10 }}>
            <div className="field">
              <label>Judul Subtask</label>
              <input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="Contoh: Kerjakan bagian analisis" />
            </div>
            <div className="field">
              <label>Kesulitan</label>
              <select value={form.difficulty} onChange={(e) => setForm({ ...form, difficulty: e.target.value })}>
                {DIFFICULTIES.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </div>
          </div>
          <div className="field">
            <label>Deskripsi Subtask</label>
            <textarea rows={2} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          </div>
          {error && <p style={{ color: 'var(--danger)' }}>{error}</p>}
          <div style={{ display: 'flex', gap: 10 }}>
            <Button type="button" variant="outline" onClick={() => onEdit(task)} style={{ flex: 1 }}>Edit Task</Button>
            <Button type="submit" loading={saving} style={{ flex: 2 }}>Tambah Subtask</Button>
          </div>
        </form>
      </div>
    </div>
  );
}
