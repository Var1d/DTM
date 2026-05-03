import { useState } from 'react';
import { useCourse } from '../../context/CourseContext';
import { useTask } from '../../context/TaskContext';
import Button from '../../components/common/Button';
import Input from '../../components/common/Input';

const TASK_TYPES = [
  ['assignment', 'Tugas'],
  ['quiz', 'Kuis'],
  ['mid_exam', 'UTS'],
  ['final_exam', 'UAS'],
  ['practicum', 'Praktikum'],
  ['presentation', 'Presentasi'],
  ['project', 'Proyek'],
  ['reading', 'Bacaan'],
  ['other', 'Lainnya'],
];

const DIFFICULTIES = [
  ['easy', 'Mudah'],
  ['medium', 'Sedang'],
  ['hard', 'Sulit'],
];

export default function TaskFormModal({ task, onClose }) {
  const isEdit = !!task;
  const { createTask, updateTask } = useTask();
  const { courses } = useCourse();

  const [form, setForm] = useState({
    title: task?.title || '',
    description: task?.description || '',
    course_id: task?.course_id || '',
    task_type: task?.task_type || 'assignment',
    difficulty: task?.difficulty || 'medium',
    grade_weight: task?.grade_weight ?? 0,
    achieved_score: task?.achieved_score ?? '',
    status: task?.status || 'todo',
    deadline: task?.deadline ? task.deadline.slice(0, 16) : '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const payload = {
        title: form.title.trim(),
        description: form.description.trim() || null,
        course_id: form.course_id || null,
        task_type: form.task_type,
        difficulty: form.difficulty,
        grade_weight: Number(form.grade_weight) || 0,
        achieved_score: form.achieved_score === '' ? null : Number(form.achieved_score),
        status: form.status,
        deadline: form.deadline || null,
      };
      if (isEdit) await updateTask(task.id, payload);
      else await createTask(payload);
      onClose();
    } catch (err) {
      setError(err.response?.data?.message || 'Gagal menyimpan tugas akademik');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200, padding: 16 }}>
      <div style={{ background: '#fff', borderRadius: 16, padding: 32, width: 520, maxHeight: '90vh', overflowY: 'auto', boxShadow: '0 20px 60px rgba(0,0,0,0.2)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
          <h2 style={{ margin: 0, fontSize: 18 }}>{isEdit ? 'Edit Tugas Akademik' : 'Tambah Tugas Akademik'}</h2>
          <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: 20, cursor: 'pointer', color: '#6b7280' }}>x</button>
        </div>
        <form onSubmit={handleSubmit}>
          <Input label="Judul Tugas *" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} required />
          <div style={{ marginBottom: 16 }}>
            <label style={{ display: 'block', marginBottom: 6, fontWeight: 500, fontSize: 14 }}>Deskripsi</label>
            <textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} rows={3} style={{ width: '100%', padding: '10px 14px', border: '1px solid #d1d5db', borderRadius: 10, fontSize: 14, boxSizing: 'border-box', resize: 'vertical' }} />
          </div>
          <div style={{ marginBottom: 16 }}>
            <label style={{ display: 'block', marginBottom: 6, fontWeight: 500, fontSize: 14 }}>Mata Kuliah</label>
            <select value={form.course_id} onChange={(e) => setForm({ ...form, course_id: e.target.value })} style={{ width: '100%', padding: '10px 14px', border: '1px solid #d1d5db', borderRadius: 10, fontSize: 14 }}>
              <option value="">Tanpa Mata Kuliah</option>
              {courses.map((course) => <option key={course.id} value={course.id}>{course.name}</option>)}
            </select>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div style={{ marginBottom: 16 }}>
              <label style={{ display: 'block', marginBottom: 6, fontWeight: 500, fontSize: 14 }}>Jenis Tugas</label>
              <select value={form.task_type} onChange={(e) => setForm({ ...form, task_type: e.target.value })} style={{ width: '100%', padding: '10px 14px', border: '1px solid #d1d5db', borderRadius: 10, fontSize: 14 }}>
                {TASK_TYPES.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </div>
            <div style={{ marginBottom: 16 }}>
              <label style={{ display: 'block', marginBottom: 6, fontWeight: 500, fontSize: 14 }}>Kesulitan</label>
              <select value={form.difficulty} onChange={(e) => setForm({ ...form, difficulty: e.target.value })} style={{ width: '100%', padding: '10px 14px', border: '1px solid #d1d5db', borderRadius: 10, fontSize: 14 }}>
                {DIFFICULTIES.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <Input label="Bobot Nilai (%)" type="number" min="0" max="100" value={form.grade_weight} onChange={(e) => setForm({ ...form, grade_weight: e.target.value })} />
            <Input label="Nilai Didapat" type="number" min="0" max="100" value={form.achieved_score} onChange={(e) => setForm({ ...form, achieved_score: e.target.value })} />
          </div>
          <div style={{ marginBottom: 16 }}>
            <label style={{ display: 'block', marginBottom: 6, fontWeight: 500, fontSize: 14 }}>Deadline</label>
            <input type="datetime-local" value={form.deadline} onChange={(e) => setForm({ ...form, deadline: e.target.value })} style={{ width: '100%', padding: '10px 14px', border: '1px solid #d1d5db', borderRadius: 10, fontSize: 14, boxSizing: 'border-box' }} />
            <p style={{ fontSize: 11, color: '#9ca3af', marginTop: 4 }}>Reminder dan prioritas akademik dihitung otomatis dari deadline.</p>
          </div>
          <div style={{ marginBottom: 20 }}>
            <label style={{ display: 'block', marginBottom: 6, fontWeight: 500, fontSize: 14 }}>Status</label>
            <div style={{ display: 'flex', gap: 8 }}>
              {[
                ['todo', 'To Do'],
                ['in_progress', 'In Progress'],
                ['done', 'Selesai'],
              ].map(([value, label]) => (
                <button key={value} type="button" onClick={() => setForm({ ...form, status: value })} style={{ flex: 1, padding: '8px 0', borderRadius: 8, border: `2px solid ${form.status === value ? '#6366f1' : '#e5e7eb'}`, background: form.status === value ? '#ede9fe' : '#fff', color: form.status === value ? '#6366f1' : '#374151', fontWeight: form.status === value ? 600 : 400, cursor: 'pointer', fontSize: 13 }}>
                  {label}
                </button>
              ))}
            </div>
          </div>
          {error && <p style={{ color: '#ef4444', fontSize: 13, marginBottom: 12 }}>{error}</p>}
          <div style={{ display: 'flex', gap: 10 }}>
            <Button type="button" variant="outline" onClick={onClose} style={{ flex: 1 }}>Batal</Button>
            <Button type="submit" loading={loading} style={{ flex: 2 }}>{isEdit ? 'Simpan' : 'Tambah Tugas'}</Button>
          </div>
        </form>
      </div>
    </div>
  );
}
