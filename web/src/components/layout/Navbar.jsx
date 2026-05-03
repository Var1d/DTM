import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

export default function Navbar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <nav style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 24px', background: '#6366f1', color: '#fff', position: 'sticky', top: 0, zIndex: 100 }}>
      <Link to="/" style={{ color: '#fff', textDecoration: 'none', fontWeight: 700, fontSize: 18 }}>
        Academic Task Manager
      </Link>
      <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
        <Link to="/" style={{ color: '#e0e7ff', textDecoration: 'none', fontSize: 14 }}>Board</Link>
        <Link to="/courses" style={{ color: '#e0e7ff', textDecoration: 'none', fontSize: 14 }}>Mata Kuliah</Link>
        <Link to="/profile" style={{ color: '#e0e7ff', textDecoration: 'none', fontSize: 14 }}>{user?.name?.split(' ')[0]}</Link>
        <button onClick={handleLogout} style={{ background: 'rgba(255,255,255,0.2)', border: 'none', color: '#fff', padding: '6px 14px', borderRadius: 8, cursor: 'pointer', fontSize: 14 }}>Keluar</button>
      </div>
    </nav>
  );
}
