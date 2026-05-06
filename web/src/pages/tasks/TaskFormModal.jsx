import { useState } from 'react';
import { useCourse } from '../../context/CourseContext';
import { useTask } from '../../context/TaskContext';
import Button from '../../components/common/Button';
import Input from '../../components/common/Input';
import { toDateTimeLocalValue } from '../../utils/dateHelper';

const TASK_TYPES = [
  ['assignment', 'Tugas'], ['quiz', 'Kuis'], ['mid_exam', 'UTS'], ['final_exam', 'UAS'],
  ['practicum', 'Praktikum'], ['presentation', 'Presentasi'], ['project', 'Proyek'], ['reading', 'Bacaan'], ['other', 'Lainnya'],
];

const DIFFICULTIES = [['easy', 'Mudah'], ['medium', 'Sedang'], ['hard', 'Sulit']];

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
    deadline: toDateTimeLocalValue(task?.deadline),
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
    <div className="modal-backdrop">
      <div className="glass-card modal-card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h2 style={{ margin: 0 }}>{isEdit ? 'Edit Tugas' : 'Tambah Tugas'}</h2>
          <button type="button" className="btn btn-outline" style={{ padding: '6px 10px' }} onClick={onClose}>X</button>
        </div>

        <form onSubmit={handleSubmit}>
          <Input label="Judul Tugas *" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} required />
          <div className="field">
            <label>Deskripsi</label>
            <textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} rows={3} />
          </div>
          <div className="field">
            <label>Mata Kuliah</label>
            <select value={form.course_id} onChange={(e) => setForm({ ...form, course_id: e.target.value })}>
              <option value="">Tanpa Mata Kuliah</option>
              {courses.map((course) => <option key={course.id} value={course.id}>{course.name}</option>)}
            </select>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div className="field"><label>Jenis Tugas</label><select value={form.task_type} onChange={(e) => setForm({ ...form, task_type: e.target.value })}>{TASK_TYPES.map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></div>
            <div className="field"><label>Kesulitan</label><select value={form.difficulty} onChange={(e) => setForm({ ...form, difficulty: e.target.value })}>{DIFFICULTIES.map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <Input label="Bobot Nilai (%)" type="number" min="0" max="100" value={form.grade_weight} onChange={(e) => setForm({ ...form, grade_weight: e.target.value })} />
            <Input label="Nilai Didapat" type="number" min="0" max="100" value={form.achieved_score} onChange={(e) => setForm({ ...form, achieved_score: e.target.value })} />
          </div>
          <Input label="Deadline" type="datetime-local" value={form.deadline} onChange={(e) => setForm({ ...form, deadline: e.target.value })} />

          <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
            {[['todo', 'To Do'], ['in_progress', 'In Progress'], ['done', 'Selesai']].map(([value, label]) => (
              <button key={value} type="button" onClick={() => setForm({ ...form, status: value })} className={`btn ${form.status === value ? 'btn-primary' : 'btn-outline'}`} style={{ flex: 1 }}>{label}</button>
            ))}
          </div>

          {error && <p style={{ color: 'var(--danger)' }}>{error}</p>}
          <div style={{ display: 'flex', gap: 10 }}>
            <Button type="button" variant="outline" onClick={onClose} style={{ flex: 1 }}>Batal</Button>
            <Button type="submit" loading={loading} style={{ flex: 2 }}>{isEdit ? 'Simpan' : 'Tambah Tugas'}</Button>
          </div>
        </form>
      </div>
    </div>
  );
}
