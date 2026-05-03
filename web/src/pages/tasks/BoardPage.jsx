import { useEffect, useMemo, useState } from 'react';
import { DndContext, PointerSensor, closestCenter, useSensor, useSensors } from '@dnd-kit/core';
import { SortableContext, useSortable, verticalListSortingStrategy } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import PriorityBadge from '../../components/task/PriorityBadge';
import { useCourse } from '../../context/CourseContext';
import { useTask } from '../../context/TaskContext';
import { timeAgo } from '../../utils/dateHelper';
import TaskFormModal from './TaskFormModal';

const COLUMNS = [
  { id: 'todo', label: 'To Do', color: '#6366f1' },
  { id: 'in_progress', label: 'In Progress', color: '#f59e0b' },
  { id: 'done', label: 'Selesai', color: '#22c55e' },
];

function DraggableTaskCard({ task, onEdit, onDelete }) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id: task.id });
  const style = { transform: CSS.Transform.toString(transform), transition, opacity: isDragging ? 0.5 : 1 };

  return (
    <div ref={setNodeRef} style={{ ...style, background: '#fff', borderRadius: 10, padding: 14, marginBottom: 10, boxShadow: '0 1px 4px rgba(0,0,0,0.08)', border: task.priority === 'overdue' ? '1px solid #fca5a5' : '1px solid #e5e7eb', cursor: 'grab' }} {...attributes} {...listeners}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
        <p style={{ fontWeight: 600, fontSize: 14, margin: 0, flex: 1, paddingRight: 8 }}>{task.title}</p>
        <div style={{ display: 'flex', gap: 4 }}>
          <button onClick={(e) => { e.stopPropagation(); onEdit(task); }} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 12, padding: 2, color: '#4f46e5' }}>Edit</button>
          <button onClick={(e) => { e.stopPropagation(); onDelete(task.id); }} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 12, padding: 2, color: '#dc2626' }}>Hapus</button>
        </div>
      </div>
      <PriorityBadge priority={task.priority} />
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 8 }}>
        {task.course_name && (
          <span style={{ fontSize: 11, background: task.course_color || '#ede9fe', color: '#111827', padding: '2px 8px', borderRadius: 20, display: 'inline-block' }}>
            {task.course_name}
          </span>
        )}
        <span style={{ fontSize: 11, background: '#f3f4f6', color: '#374151', padding: '2px 8px', borderRadius: 20, display: 'inline-block' }}>
          {task.difficulty || 'medium'}
        </span>
        {Number(task.grade_weight) > 0 && (
          <span style={{ fontSize: 11, background: '#ecfeff', color: '#0e7490', padding: '2px 8px', borderRadius: 20, display: 'inline-block' }}>
            Bobot {task.grade_weight}%
          </span>
        )}
      </div>
      {task.deadline && (
        <p style={{ fontSize: 12, color: '#6b7280', marginTop: 8, marginBottom: 0 }}>Deadline {timeAgo(task.deadline)}</p>
      )}
      {task.academic_priority && (
        <p style={{ fontSize: 11, color: '#9ca3af', marginTop: 4, marginBottom: 0 }}>
          Skor akademik {task.academic_priority.score} - {task.academic_priority.label}
        </p>
      )}
      {task.sub_tasks?.length > 0 && (
        <div style={{ marginTop: 8 }}>
          <div style={{ height: 4, background: '#e5e7eb', borderRadius: 4, overflow: 'hidden' }}>
            <div style={{ height: '100%', background: '#6366f1', width: `${task.progress || 0}%`, borderRadius: 4 }} />
          </div>
          <p style={{ fontSize: 11, color: '#9ca3af', marginTop: 2 }}>{task.progress || 0}% selesai</p>
        </div>
      )}
    </div>
  );
}

function KanbanColumn({ column, tasks, onEdit, onDelete }) {
  return (
    <div style={{ flex: 1, minWidth: 280, background: '#f9fafb', borderRadius: 12, padding: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <div style={{ width: 10, height: 10, borderRadius: '50%', background: column.color }} />
        <h3 style={{ margin: 0, fontSize: 15, fontWeight: 600 }}>{column.label}</h3>
        <span style={{ marginLeft: 'auto', background: '#e5e7eb', borderRadius: 20, padding: '1px 10px', fontSize: 12 }}>{tasks.length}</span>
      </div>
      <SortableContext items={tasks.map((task) => task.id)} strategy={verticalListSortingStrategy}>
        {tasks.map((task) => (
          <DraggableTaskCard key={task.id} task={task} onEdit={onEdit} onDelete={onDelete} />
        ))}
      </SortableContext>
    </div>
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

  const filtered = useMemo(() => {
    return tasks.filter((task) => {
      const matchesSearch = task.title.toLowerCase().includes(search.toLowerCase())
        || (task.course_name || '').toLowerCase().includes(search.toLowerCase());
      const matchesCourse = !courseId || String(task.course_id) === String(courseId);
      return matchesSearch && matchesCourse;
    });
  }, [tasks, search, courseId]);

  const grouped = COLUMNS.reduce((acc, column) => {
    acc[column.id] = filtered.filter((task) => task.status === column.id);
    return acc;
  }, {});

  const handleDragEnd = ({ active, over }) => {
    if (!over || active.id === over.id) return;
    const targetColumn = COLUMNS.find((column) => grouped[column.id].some((task) => task.id === over.id));
    if (targetColumn) updateStatus(active.id, targetColumn.id);
  };

  const handleEdit = (task) => {
    setEditTask(task);
    setShowModal(true);
  };

  const handleAdd = () => {
    setEditTask(null);
    setShowModal(true);
  };

  return (
    <div style={{ padding: 24 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20, flexWrap: 'wrap', gap: 12 }}>
        <div>
          <h2 style={{ margin: 0 }}>Academic Kanban Board</h2>
          <p style={{ margin: '6px 0 0', color: '#6b7280', fontSize: 14 }}>Drag and drop tugas antar status untuk memperbarui progres.</p>
        </div>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
          <select value={courseId} onChange={(e) => setCourseId(e.target.value)} style={{ padding: '8px 14px', borderRadius: 10, border: '1px solid #d1d5db', fontSize: 14, outline: 'none', minWidth: 180 }}>
            <option value="">Semua mata kuliah</option>
            {courses.map((course) => <option key={course.id} value={course.id}>{course.name}</option>)}
          </select>
          <input placeholder="Cari tugas atau matkul..." value={search} onChange={(e) => setSearch(e.target.value)} style={{ padding: '8px 14px', borderRadius: 10, border: '1px solid #d1d5db', fontSize: 14, outline: 'none', width: 220 }} />
          <button onClick={handleAdd} style={{ background: '#6366f1', color: '#fff', border: 'none', padding: '9px 18px', borderRadius: 10, fontWeight: 600, cursor: 'pointer', fontSize: 14 }}>
            + Tambah Tugas
          </button>
        </div>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 60, color: '#9ca3af' }}>Memuat tugas akademik...</div>
      ) : (
        <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
          <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start', overflowX: 'auto', paddingBottom: 16 }}>
            {COLUMNS.map((column) => (
              <KanbanColumn key={column.id} column={column} tasks={grouped[column.id]} onEdit={handleEdit} onDelete={deleteTask} />
            ))}
          </div>
        </DndContext>
      )}

      {showModal && (
        <TaskFormModal task={editTask} onClose={() => { setShowModal(false); setEditTask(null); fetchTasks(); }} />
      )}
    </div>
  );
}
