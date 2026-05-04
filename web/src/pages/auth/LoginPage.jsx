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
    <div className="auth-wrap">
      <div className="glass-card auth-card" style={{ background: 'var(--card-glass)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
          <img src="/pio-logo.png" alt="PIO Logo" style={{ width: 34, height: 34, objectFit: 'contain' }} />
          <h1 style={{ margin: 0 }}>PIO</h1>
        </div>
        <p style={{ color: 'var(--text-muted)', margin: '0 0 22px' }}>Masuk untuk lanjut mengelola tugas akademikmu.</p>
        <form onSubmit={handleSubmit}>
          <Input label="Email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required />
          <Input label="Password" type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required />
          {error && <p style={{ color: 'var(--danger)', fontSize: 13, marginBottom: 12 }}>{error}</p>}
          <Button type="submit" loading={loading} style={{ width: '100%' }}>Masuk</Button>
        </form>
        <p style={{ textAlign: 'center', marginTop: 18 }}>
          Belum punya akun? <Link to="/register" style={{ color: 'var(--primary-2)', fontWeight: 700 }}>Daftar</Link>
        </p>
      </div>
    </div>
  );
}
