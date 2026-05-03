import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import Button from '../../components/common/Button';
import Input from '../../components/common/Input';

export default function LoginPage() {
  const [form, setForm] = useState({ email: '', password: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(form.email, form.password);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.message || 'Login gagal');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f5f5f5' }}>
      <div style={{ background: '#fff', padding: 40, borderRadius: 16, width: 380, boxShadow: '0 4px 20px rgba(0,0,0,0.08)' }}>
        <h1 style={{ marginBottom: 8, fontSize: 24 }}>Academic Task Manager</h1>
        <p style={{ color: '#6b7280', marginBottom: 28, fontSize: 14 }}>Masuk untuk mengelola tugas akademik Anda</p>
        <form onSubmit={handleSubmit}>
          <Input label="Email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required />
          <Input label="Password" type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required />
          {error && <p style={{ color: '#ef4444', fontSize: 13, marginBottom: 12 }}>{error}</p>}
          <Button type="submit" loading={loading} style={{ width: '100%' }}>Masuk</Button>
        </form>
        <p style={{ textAlign: 'center', marginTop: 20, fontSize: 14 }}>
          Belum punya akun? <Link to="/register" style={{ color: '#6366f1', fontWeight: 600 }}>Daftar</Link>
        </p>
      </div>
    </div>
  );
}
