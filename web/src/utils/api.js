import axios from 'axios';

export const ROOT_URL = 'http://localhost:3000';
const BASE_URL = `${ROOT_URL}/api`;

const api = axios.create({ baseURL: BASE_URL, headers: { 'Content-Type': 'application/json' } });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  async (err) => {
    if (err.response?.status === 401 && !err.config?._retry) {
      const refresh = localStorage.getItem('refresh_token');
      if (refresh) {
        try {
          err.config._retry = true;
          const { data } = await axios.post(`${BASE_URL}/auth/refresh`, { refresh_token: refresh });
          localStorage.setItem('access_token', data.data.access_token);
          err.config.headers = err.config.headers || {};
          err.config.headers.Authorization = `Bearer ${data.data.access_token}`;
          return api(err.config);
        } catch {
          localStorage.clear();
          window.location.href = '/login';
        }
      }
    }
    return Promise.reject(err);
  }
);

export default api;
