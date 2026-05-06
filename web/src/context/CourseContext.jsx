import { createContext, useCallback, useContext, useState } from 'react';
import api from '../utils/api';

const CourseContext = createContext(null);
const COURSE_CACHE_KEY = 'pio.cached_courses';

const readCachedCourses = () => {
  try {
    return JSON.parse(localStorage.getItem(COURSE_CACHE_KEY) || '[]');
  } catch {
    return [];
  }
};

const saveCachedCourses = (nextCourses) => {
  localStorage.setItem(COURSE_CACHE_KEY, JSON.stringify(nextCourses));
};

export const CourseProvider = ({ children }) => {
  const [courses, setCourses] = useState(readCachedCourses);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchCourses = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await api.get('/courses');
      setCourses(data.data);
      saveCachedCourses(data.data);
    } catch (e) {
      const cachedCourses = readCachedCourses();
      if (cachedCourses.length > 0) {
        setCourses(cachedCourses);
        setError(null);
      } else {
        setError(e.response?.data?.message || 'Gagal memuat mata kuliah');
      }
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
    setCourses((prev) => {
      const nextCourses = prev.filter((course) => course.id !== id);
      saveCachedCourses(nextCourses);
      return nextCourses;
    });
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
