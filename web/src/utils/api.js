import axios from 'axios';

const normalizeBaseUrl = (raw) => String(raw || '').trim().replace(/\/+$/, '');

const getRootUrl = () => {
  const envUrl = normalizeBaseUrl(process.env.REACT_APP_API_URL);
  if (envUrl) return envUrl;

  if (typeof window !== 'undefined') {
    const { protocol, hostname, origin } = window.location;
    const envPort = String(process.env.REACT_APP_API_PORT || '').trim();
    if (envPort) return `${protocol}//${hostname}:${envPort}`;
    return origin;
  }

  return 'http://localhost:3000';
};

export const ROOT_URL = getRootUrl();
const BASE_URL = `${ROOT_URL}/api`;

const api = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 15000,
});

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
          const { data } = await axios.post(`${BASE_URL}/auth/refresh`, { refresh_token: refresh }, { timeout: 15000 });
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
