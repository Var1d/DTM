import { useEffect, useMemo, useState } from 'react';
import { DndContext, PointerSensor, closestCenter, useDroppable, useSensor, useSensors } from '@dnd-kit/core';
import { SortableContext, useSortable, verticalListSortingStrategy } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import PriorityBadge from '../../components/task/PriorityBadge';
import { useCourse } from '../../context/CourseContext';
import { useTask } from '../../context/TaskContext';
import { timeAgo } from '../../utils/dateHelper';
import TaskFormModal from './TaskFormModal';

const COLUMNS = [
  { id: 'todo', label: 'To Do', color: '#a855f7' },
  { id: 'in_progress', label: 'In Progress', color: '#fb923c' },
  { id: 'done', label: 'Selesai', color: '#4ade80' },
];

function DraggableTaskCard({ task, onEdit, onDelete }) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id: task.id });
  const style = { transform: CSS.Transform.toString(transform), transition, opacity: isDragging ? 0.45 : 1 };

  return (
    <div ref={setNodeRef} style={style} className="task-card" {...attributes} {...listeners}>
      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, marginBottom: 8 }}>
        <p style={{ margin: 0, fontWeight: 700 }}>{task.title}</p>
        <div style={{ display: 'flex', gap: 6 }}>
          <button className="btn btn-ghost" type="button" style={{ padding: '4px 8px', fontSize: 12 }} onClick={(e) => { e.stopPropagation(); onEdit(task); }}>Edit</button>
          <button className="btn btn-outline" type="button" style={{ padding: '4px 8px', fontSize: 12 }} onClick={(e) => { e.stopPropagation(); onDelete(task.id); }}>Hapus</button>
        </div>
      </div>

      <PriorityBadge priority={task.priority} />

      <div style={{ display: 'flex', gap: 8, marginTop: 8, flexWrap: 'wrap' }}>
        {task.course_name && <span style={{ fontSize: 11, padding: '3px 8px', borderRadius: 999, background: task.course_color || 'var(--primary)', color: '#fff' }}>{task.course_name}</span>}
        <span style={{ fontSize: 11, padding: '3px 8px', borderRadius: 999, border: '1px solid var(--border)', color: 'var(--text-muted)' }}>{task.difficulty}</span>
      </div>

      {task.deadline && <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: '8px 0 0' }}>Deadline {timeAgo(task.deadline)}</p>}
      {task.academic_priority && <p style={{ fontSize: 11, color: 'var(--text-muted)', margin: '4px 0 0' }}>Skor {task.academic_priority.score} - {task.academic_priority.label}</p>}
    </div>
  );
}

function KanbanColumn({ column, tasks, onEdit, onDelete }) {
  const { setNodeRef, isOver } = useDroppable({ id: column.id });

  return (
    <section ref={setNodeRef} className="col" style={{ outline: isOver ? `2px solid ${column.color}` : 'none' }}>
      <div style={{ display: 'flex', alignItems: 'center', marginBottom: 12 }}>
        <div style={{ width: 10, height: 10, borderRadius: 50, background: column.color, marginRight: 8 }} />
        <strong>{column.label}</strong>
        <span style={{ marginLeft: 'auto', color: 'var(--text-muted)' }}>{tasks.length}</span>
      </div>
      <SortableContext items={tasks.map((task) => task.id)} strategy={verticalListSortingStrategy}>
        {tasks.map((task) => <DraggableTaskCard key={task.id} task={task} onEdit={onEdit} onDelete={onDelete} />)}
      </SortableContext>
    </section>
  );
}

export default function BoardPage() {
  const { tasks, loading, fetchTasks, updateStatus, deleteTask } = useTask();
  const { courses, fetchCourses } = useCourse();
  const [showModal, setShowModal] = useState(false);
  const [editTask, setEditTask] = useState(null);
  const [search, setSearch] = useState('');
  const [courseId, setCourseId] = useState('');

  const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 5 } }));

  useEffect(() => {
    fetchTasks();
    fetchCourses();
  }, [fetchTasks, fetchCourses]);

  const filtered = useMemo(() => tasks.filter((task) => {
    const matchesSearch = task.title.toLowerCase().includes(search.toLowerCase()) || (task.course_name || '').toLowerCase().includes(search.toLowerCase());
    const matchesCourse = !courseId || String(task.course_id) === String(courseId);
    return matchesSearch && matchesCourse;
  }), [tasks, search, courseId]);

  const grouped = COLUMNS.reduce((acc, column) => {
    acc[column.id] = filtered.filter((task) => task.status === column.id);
    return acc;
  }, {});

  const handleDragEnd = ({ active, over }) => {
    if (!over || active.id === over.id) return;
    const targetColumn = COLUMNS.find((column) => column.id === over.id) || COLUMNS.find((column) => grouped[column.id].some((task) => task.id === over.id));
    if (targetColumn) updateStatus(active.id, targetColumn.id);
  };

  return (
    <div className="page-shell">
      <div className="glass-card" style={{ padding: 18, marginBottom: 14, background: 'var(--card-glass)' }}>
        <h2 style={{ margin: 0 }}>PIO Task Board</h2>
        <p style={{ color: 'var(--text-muted)', margin: '6px 0 14px' }}>Drag and drop antar kolom untuk update progres dengan cepat.</p>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <select value={courseId} onChange={(e) => setCourseId(e.target.value)} className="btn btn-outline" style={{ textAlign: 'left', minWidth: 170 }}>
            <option value="">Semua mata kuliah</option>
            {courses.map((course) => <option key={course.id} value={course.id}>{course.name}</option>)}
          </select>
          <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari tugas / matkul" className="btn btn-outline" style={{ minWidth: 220, textAlign: 'left', fontWeight: 500 }} />
          <button onClick={() => { setEditTask(null); setShowModal(true); }} className="btn btn-primary" type="button">+ Tambah Tugas</button>
        </div>
      </div>

      {loading ? <div className="glass-card" style={{ padding: 24 }}>Memuat tugas...</div> : (
        <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
          {filtered.length === 0 ? (
            <div className="glass-card empty-state">
              <h3>Belum ada tugas yang cocok</h3>
              <p>Coba ubah filter atau tambah tugas baru untuk mulai menyusun progres akademikmu.</p>
              <button onClick={() => { setEditTask(null); setShowModal(true); }} className="btn btn-primary" type="button">+ Tambah Tugas</button>
            </div>
          ) : (
            <div className="board-grid">
              {COLUMNS.map((column) => <KanbanColumn key={column.id} column={column} tasks={grouped[column.id]} onEdit={(task) => { setEditTask(task); setShowModal(true); }} onDelete={deleteTask} />)}
            </div>
          )}
        </DndContext>
      )}

      {showModal && <TaskFormModal task={editTask} onClose={() => { setShowModal(false); setEditTask(null); fetchTasks(); }} />}
    </div>
  );
}
