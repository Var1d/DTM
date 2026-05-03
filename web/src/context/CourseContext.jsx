import { createContext, useCallback, useContext, useState } from 'react';
import api from '../utils/api';

const CourseContext = createContext(null);

export const CourseProvider = ({ children }) => {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchCourses = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await api.get('/courses');
      setCourses(data.data);
    } catch (e) {
      setError(e.response?.data?.message || 'Gagal memuat mata kuliah');
    } finally {
      setLoading(false);
    }
  }, []);

  const createCourse = async (payload) => {
    await api.post('/courses', payload);
    await fetchCourses();
  };

  const updateCourse = async (id, payload) => {
    await api.put(`/courses/${id}`, payload);
    await fetchCourses();
  };

  const deleteCourse = async (id) => {
    await api.delete(`/courses/${id}`);
    setCourses((prev) => prev.filter((course) => course.id !== id));
  };

  return (
    <CourseContext.Provider
      value={{
        courses,
        loading,
        error,
        fetchCourses,
        createCourse,
        updateCourse,
        deleteCourse,
      }}
    >
      {children}
    </CourseContext.Provider>
  );
};

export const useCourse = () => useContext(CourseContext);
