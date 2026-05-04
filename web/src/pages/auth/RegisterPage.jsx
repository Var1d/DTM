import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import Button from '../../components/common/Button';
import Input from '../../components/common/Input';

export default function RegisterPage() {
  const [form, setForm] = useState({ name: '', email: '', password: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { register } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await register(form.name, form.email, form.password);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.message || 'Registrasi gagal');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-wrap">
      <div className="glass-card auth-card" style={{ background: 'var(--card-glass)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
          <img src="/pio-logo.png" alt="PIO Logo" style={{ width: 34, height: 34, objectFit: 'contain' }} />
          <h1 style={{ margin: 0 }}>Buat Akun PIO</h1>
        </div>
        <p style={{ color: 'var(--text-muted)', margin: '0 0 22px' }}>Mulai atur mata kuliah, deadline, dan target nilaimu.</p>
        <form onSubmit={handleSubmit}>
          <Input label="Nama Lengkap" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
          <Input label="Email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required />
          <Input label="Password" type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required />
          {error && <p style={{ color: 'var(--danger)', fontSize: 13, marginBottom: 12 }}>{error}</p>}
          <Button type="submit" loading={loading} style={{ width: '100%' }}>Daftar</Button>
        </form>
        <p style={{ textAlign: 'center', marginTop: 18 }}>
          Sudah punya akun? <Link to="/login" style={{ color: 'var(--primary-2)', fontWeight: 700 }}>Masuk</Link>
        </p>
      </div>
    </div>
  );
}
