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
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f5f5f5' }}>
      <div style={{ background: '#fff', padding: 40, borderRadius: 16, width: 380, boxShadow: '0 4px 20px rgba(0,0,0,0.08)' }}>
        <h1 style={{ marginBottom: 8, fontSize: 24 }}>Buat Akun Baru</h1>
        <p style={{ color: '#6b7280', marginBottom: 28, fontSize: 14 }}>Mulai kelola tugas, deadline, dan mata kuliahmu</p>
        <form onSubmit={handleSubmit}>
          <Input label="Nama Lengkap" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
          <Input label="Email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required />
          <Input label="Password" type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required />
          {error && <p style={{ color: '#ef4444', fontSize: 13, marginBottom: 12 }}>{error}</p>}
          <Button type="submit" loading={loading} style={{ width: '100%' }}>Daftar</Button>
        </form>
        <p style={{ textAlign: 'center', marginTop: 20, fontSize: 14 }}>
          Sudah punya akun? <Link to="/login" style={{ color: '#6366f1', fontWeight: 600 }}>Masuk</Link>
        </p>
      </div>
    </div>
  );
}
