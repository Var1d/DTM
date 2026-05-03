import { createContext, useContext, useState, useCallback } from 'react';
import api from '../utils/api';

const TaskContext = createContext(null);

export const TaskProvider = ({ children }) => {
  const [tasks,   setTasks]   = useState([]);
  const [loading, setLoading] = useState(false);
  const [error,   setError]   = useState(null);

  const fetchTasks = useCallback(async (params = {}) => {
    setLoading(true); setError(null);
    try {
      const { data } = await api.get('/tasks', { params });
      setTasks(data.data);
    } catch (e) {
      setError(e.response?.data?.message || 'Gagal memuat task');
    } finally { setLoading(false); }
  }, []);

  const createTask = async (payload) => {
    const { data } = await api.post('/tasks', payload);
    setTasks((prev) => [data.data, ...prev]);
    return data.data;
  };

  const updateTask = async (id, payload) => {
    const { data } = await api.put(`/tasks/${id}`, payload);
    setTasks((prev) => prev.map((t) => t.id === id ? data.data : t));
    return data.data;
  };

  const updateStatus = async (id, status) => {
    await api.patch(`/tasks/${id}/status`, { status });
    await fetchTasks();
  };

  const deleteTask = async (id) => {
    await api.delete(`/tasks/${id}`);
    setTasks((prev) => prev.filter((t) => t.id !== id));
  };

  return (
    <TaskContext.Provider value={{ tasks, loading, error, fetchTasks, createTask, updateTask, updateStatus, deleteTask }}>
      {children}
    </TaskContext.Provider>
  );
};

export const useTask = () => useContext(TaskContext);
