import { useEffect, useState } from 'react';
import { useCourse } from '../../context/CourseContext';
import Button from '../../components/common/Button';
import Input from '../../components/common/Input';

const DAYS = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

export default function CoursePage() {
  const { courses, loading, error, fetchCourses, createCourse, updateCourse, deleteCourse } = useCourse();
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ name: '', lecturer: '', room: '', day: '', start_time: '', end_time: '', credit: 3, color: '#a855f7' });
  const [saving, setSaving] = useState(false);

  useEffect(() => { fetchCourses(); }, [fetchCourses]);

  const openAdd = () => { setEditing(null); setForm({ name: '', lecturer: '', room: '', day: '', start_time: '', end_time: '', credit: 3, color: '#a855f7' }); setShowForm(true); };
  const openEdit = (course) => { setEditing(course); setForm({ name: course.name || '', lecturer: course.lecturer || '', room: course.room || '', day: course.day || '', start_time: (course.start_time || '').slice(0, 5), end_time: (course.end_time || '').slice(0, 5), credit: course.credit || 3, color: course.color || '#a855f7' }); setShowForm(true); };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    const payload = { ...form, lecturer: form.lecturer || null, room: form.room || null, day: form.day || null, start_time: form.start_time || null, end_time: form.end_time || null, credit: Number(form.credit) || 3 };
    if (editing) await updateCourse(editing.id, payload); else await createCourse(payload);
    setSaving(false);
    setShowForm(false);
  };

  return (
    <div className="page-shell">
      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 10, alignItems: 'center', marginBottom: 14 }}>
        <div><h2 style={{ margin: 0 }}>Mata Kuliah</h2><p style={{ color: 'var(--text-muted)', margin: '6px 0 0' }}>Kelola jadwal dan konteks tugas tiap mata kuliah.</p></div>
        <Button onClick={openAdd}>+ Tambah Mata Kuliah</Button>
      </div>

      {loading ? <div className="glass-card" style={{ padding: 20 }}>Memuat...</div> : error ? <div className="glass-card" style={{ padding: 20, color: 'var(--danger)' }}>{error}</div> : courses.length === 0 ? (
        <div className="glass-card empty-state">
          <h3>Belum ada mata kuliah</h3>
          <p>Tambahkan mata kuliah dulu supaya tugas bisa terstruktur berdasarkan konteks perkuliahan.</p>
          <Button onClick={openAdd}>+ Tambah Mata Kuliah</Button>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(260px,1fr))', gap: 12 }}>
          {courses.map((course) => (
            <div key={course.id} className="glass-card" style={{ padding: 14 }}>
              <div style={{ display: 'flex', gap: 10 }}>
                <div style={{ width: 16, height: 16, borderRadius: 5, background: course.color, marginTop: 5 }} />
                <div style={{ flex: 1 }}>
                  <h3 style={{ margin: 0 }}>{course.name}</h3>
                  <p style={{ color: 'var(--text-muted)', margin: '4px 0 0' }}>{[course.lecturer, course.room].filter(Boolean).join(' - ') || 'Detail belum diisi'}</p>
                  <p style={{ color: 'var(--text-muted)', margin: '6px 0 0', fontSize: 13 }}>{course.task_count || 0} tugas, {course.done_count || 0} selesai</p>
                </div>
                <div style={{ display: 'flex', gap: 6 }}>
                  <button className="btn btn-ghost" type="button" onClick={() => openEdit(course)} style={{ padding: '6px 8px' }}>Edit</button>
                  <button className="btn btn-outline" type="button" onClick={() => deleteCourse(course.id)} style={{ padding: '6px 8px' }}>Hapus</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {showForm && (
        <div className="modal-backdrop">
          <div className="glass-card modal-card">
            <h3 style={{ marginTop: 0 }}>{editing ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah'}</h3>
            <form onSubmit={handleSubmit}>
              <Input label="Nama Mata Kuliah *" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
              <Input label="Dosen" value={form.lecturer} onChange={(e) => setForm({ ...form, lecturer: e.target.value })} />
              <Input label="Ruangan" value={form.room} onChange={(e) => setForm({ ...form, room: e.target.value })} />
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <div className="field"><label>Hari</label><select value={form.day} onChange={(e) => setForm({ ...form, day: e.target.value })}>{DAYS.map((day) => <option key={day || 'none'} value={day}>{day || 'Fleksibel'}</option>)}</select></div>
                <Input label="SKS" type="number" min="1" value={form.credit} onChange={(e) => setForm({ ...form, credit: e.target.value })} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <Input label="Mulai" type="time" value={form.start_time} onChange={(e) => setForm({ ...form, start_time: e.target.value })} />
                <Input label="Selesai" type="time" value={form.end_time} onChange={(e) => setForm({ ...form, end_time: e.target.value })} />
              </div>
              <div className="field"><label>Warna</label><input type="color" value={form.color} onChange={(e) => setForm({ ...form, color: e.target.value })} /></div>
              <div style={{ display: 'flex', gap: 10 }}><Button type="button" variant="outline" onClick={() => setShowForm(false)} style={{ flex: 1 }}>Batal</Button><Button type="submit" loading={saving} style={{ flex: 2 }}>{editing ? 'Simpan' : 'Tambah'}</Button></div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
