import { createContext, useContext, useState, useEffect } from 'react';
import api from '../utils/api';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const initAuth = async () => {
      const stored = localStorage.getItem('user');
      const token = localStorage.getItem('access_token');
      
      if (stored && token) {
        try {
          // Ambil data terbaru dari server agar sinkron dengan Mobile
          const { data } = await api.get('/auth/me');
          syncUser(data.data);
        } catch (err) {
          // Fallback ke local storage jika server tidak bisa dijangkau
          setUser(JSON.parse(stored));
        }
      }
      setLoading(false);
    };
    initAuth();
  }, []);

  const syncUser = (nextUser) => {
    setUser(nextUser);
    localStorage.setItem('user', JSON.stringify(nextUser));
  };

  const login = async (email, password) => {
    const { data } = await api.post('/auth/login', { email, password });
    localStorage.setItem('access_token', data.data.access_token);
    localStorage.setItem('refresh_token', data.data.refresh_token);
    syncUser(data.data.user);
    return data;
  };

  const register = async (name, email, password) => {
    await api.post('/auth/register', { name, email, password });
    return login(email, password);
  };

  const logout = async () => {
    const refresh = localStorage.getItem('refresh_token');
    if (refresh) await api.post('/auth/logout', { refresh_token: refresh }).catch(() => {});
    localStorage.clear();
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout, syncUser }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
