import { createContext, useContext, useState, useCallback } from 'react';
import api from '../utils/api';

const TaskContext = createContext(null);
const TASK_CACHE_KEY = 'pio.cached_tasks';

const readCachedTasks = () => {
  try {
    return JSON.parse(localStorage.getItem(TASK_CACHE_KEY) || '[]');
  } catch {
    return [];
  }
};

const saveCachedTasks = (nextTasks) => {
  localStorage.setItem(TASK_CACHE_KEY, JSON.stringify(nextTasks));
};

export const TaskProvider = ({ children }) => {
  const [tasks,   setTasks]   = useState(readCachedTasks);
  const [loading, setLoading] = useState(false);
  const [error,   setError]   = useState(null);

  const fetchTasks = useCallback(async (params = {}) => {
    setLoading(true); setError(null);
    try {
      const { data } = await api.get('/tasks', { params });
      setTasks(data.data);
      saveCachedTasks(data.data);
    } catch (e) {
      const cachedTasks = readCachedTasks();
      if (cachedTasks.length > 0) {
        setTasks(cachedTasks);
        setError(null);
      } else {
        setError(e.response?.data?.message || 'Gagal memuat task');
      }
    } finally { setLoading(false); }
  }, []);

  const createTask = async (payload) => {
    const { data } = await api.post('/tasks', payload);
    setTasks((prev) => {
      const nextTasks = [data.data, ...prev];
      saveCachedTasks(nextTasks);
      return nextTasks;
    });
    return data.data;
  };

  const updateTask = async (id, payload) => {
    const { data } = await api.put(`/tasks/${id}`, payload);
    setTasks((prev) => {
      const nextTasks = prev.map((t) => t.id === id ? data.data : t);
      saveCachedTasks(nextTasks);
      return nextTasks;
    });
    return data.data;
  };

  const updateStatus = async (id, status) => {
    await api.patch(`/tasks/${id}/status`, { status });
    await fetchTasks();
  };

  const deleteTask = async (id) => {
    await api.delete(`/tasks/${id}`);
    setTasks((prev) => {
      const nextTasks = prev.filter((t) => t.id !== id);
      saveCachedTasks(nextTasks);
      return nextTasks;
    });
  };

  return (
    <TaskContext.Provider value={{ tasks, loading, error, fetchTasks, createTask, updateTask, updateStatus, deleteTask }}>
      {children}
    </TaskContext.Provider>
  );
};

export const useTask = () => useContext(TaskContext);
