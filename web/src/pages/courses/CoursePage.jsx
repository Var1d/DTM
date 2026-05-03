import { useEffect, useState } from 'react';
import { useCourse } from '../../context/CourseContext';
import Button from '../../components/common/Button';
import Input from '../../components/common/Input';

const DAYS = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

export default function CoursePage() {
  const {
    courses,
    loading,
    error,
    fetchCourses,
    createCourse,
    updateCourse,
    deleteCourse,
  } = useCourse();
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({
    name: '',
    lecturer: '',
    room: '',
    day: '',
    start_time: '',
    end_time: '',
    credit: 3,
    color: '#6366f1',
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchCourses();
  }, [fetchCourses]);

  const openAdd = () => {
    setEditing(null);
    setForm({
      name: '',
      lecturer: '',
      room: '',
      day: '',
      start_time: '',
      end_time: '',
      credit: 3,
      color: '#6366f1',
    });
    setShowForm(true);
  };

  const openEdit = (course) => {
    setEditing(course);
    setForm({
      name: course.name || '',
      lecturer: course.lecturer || '',
      room: course.room || '',
      day: course.day || '',
      start_time: (course.start_time || '').slice(0, 5),
      end_time: (course.end_time || '').slice(0, 5),
      credit: course.credit || 3,
      color: course.color || '#6366f1',
    });
    setShowForm(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    const payload = {
      ...form,
      lecturer: form.lecturer || null,
      room: form.room || null,
      day: form.day || null,
      start_time: form.start_time || null,
      end_time: form.end_time || null,
      credit: Number(form.credit) || 3,
    };
    if (editing) await updateCourse(editing.id, payload);
    else await createCourse(payload);
    setSaving(false);
    setShowForm(false);
  };

  return (
    <div style={{ padding: 24, maxWidth: 860, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24, gap: 12 }}>
        <div>
          <h2 style={{ margin: 0 }}>Mata Kuliah</h2>
          <p style={{ margin: '6px 0 0', color: '#6b7280', fontSize: 14 }}>
            Kelola jadwal dan konteks akademik untuk setiap tugas.
          </p>
        </div>
        <Button onClick={openAdd}>+ Tambah Mata Kuliah</Button>
      </div>

      {loading ? (
        <p style={{ color: '#9ca3af', textAlign: 'center', padding: 40 }}>Memuat mata kuliah...</p>
      ) : error ? (
        <p style={{ color: '#ef4444', textAlign: 'center', padding: 40 }}>{error}</p>
      ) : courses.length === 0 ? (
        <p style={{ color: '#9ca3af', textAlign: 'center', padding: 40 }}>Belum ada mata kuliah</p>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 12 }}>
          {courses.map((course) => (
            <div key={course.id} style={{ background: '#fff', borderRadius: 12, padding: 16, boxShadow: '0 1px 4px rgba(0,0,0,0.06)', border: '1px solid #e5e7eb' }}>
              <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                <div style={{ width: 18, height: 18, borderRadius: 5, background: course.color, flexShrink: 0, marginTop: 3 }} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <h3 style={{ margin: 0, fontSize: 16 }}>{course.name}</h3>
                  <p style={{ margin: '6px 0 0', color: '#6b7280', fontSize: 13 }}>
                    {[course.lecturer, course.room].filter(Boolean).join(' - ') || 'Detail belum diisi'}
                  </p>
                  <p style={{ margin: '8px 0 0', color: '#374151', fontSize: 13 }}>
                    {course.day || 'Hari fleksibel'}
                    {course.start_time ? `, ${String(course.start_time).slice(0, 5)}` : ''}
                    {course.end_time ? `-${String(course.end_time).slice(0, 5)}` : ''}
                  </p>
                  <p style={{ margin: '8px 0 0', color: '#6b7280', fontSize: 12 }}>
                    {course.task_count || 0} tugas, {course.done_count || 0} selesai
                  </p>
                </div>
                <div style={{ display: 'flex', gap: 4 }}>
                  <button onClick={() => openEdit(course)} title="Edit" style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 15 }}>Edit</button>
                  <button onClick={() => deleteCourse(course.id)} title="Hapus" style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 15, color: '#dc2626' }}>Hapus</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {showForm && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200, padding: 16 }}>
          <div style={{ background: '#fff', borderRadius: 16, padding: 28, width: 460, maxHeight: '90vh', overflowY: 'auto', boxShadow: '0 20px 60px rgba(0,0,0,0.2)' }}>
            <h3 style={{ marginTop: 0 }}>{editing ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah'}</h3>
            <form onSubmit={handleSubmit}>
              <Input label="Nama Mata Kuliah *" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
              <Input label="Dosen" value={form.lecturer} onChange={(e) => setForm({ ...form, lecturer: e.target.value })} />
              <Input label="Ruangan" value={form.room} onChange={(e) => setForm({ ...form, room: e.target.value })} />
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div style={{ marginBottom: 16 }}>
                  <label style={{ display: 'block', marginBottom: 6, fontWeight: 500, fontSize: 14 }}>Hari</label>
                  <select value={form.day} onChange={(e) => setForm({ ...form, day: e.target.value })} style={{ width: '100%', padding: '10px 14px', border: '1px solid #d1d5db', borderRadius: 10, fontSize: 14 }}>
                    {DAYS.map((day) => <option key={day || 'none'} value={day}>{day || 'Fleksibel'}</option>)}
                  </select>
                </div>
                <Input label="SKS" type="number" min="1" value={form.credit} onChange={(e) => setForm({ ...form, credit: e.target.value })} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <Input label="Mulai" type="time" value={form.start_time} onChange={(e) => setForm({ ...form, start_time: e.target.value })} />
                <Input label="Selesai" type="time" value={form.end_time} onChange={(e) => setForm({ ...form, end_time: e.target.value })} />
              </div>
              <div style={{ marginBottom: 20 }}>
                <label style={{ display: 'block', marginBottom: 6, fontWeight: 500, fontSize: 14 }}>Warna</label>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <input type="color" value={form.color} onChange={(e) => setForm({ ...form, color: e.target.value })} style={{ width: 48, height: 40, borderRadius: 8, border: '1px solid #d1d5db', cursor: 'pointer', padding: 2 }} />
                  <span style={{ fontSize: 14, color: '#6b7280' }}>{form.color}</span>
                </div>
              </div>
              <div style={{ display: 'flex', gap: 10 }}>
                <Button type="button" variant="outline" onClick={() => setShowForm(false)} style={{ flex: 1 }}>Batal</Button>
                <Button type="submit" loading={saving} style={{ flex: 2 }}>{editing ? 'Simpan' : 'Tambah'}</Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
