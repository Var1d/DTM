import { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { useTheme } from '../../context/ThemeContext';
import Avatar from '../common/Avatar';

export default function Navbar() {
  const { user, logout } = useAuth();
  const { isDark, toggleTheme } = useTheme();
  const navigate = useNavigate();
  const [menuOpen, setMenuOpen] = useState(false);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const closeMenu = () => setMenuOpen(false);

  return (
    <nav className="navbar">
      <NavLink to="/" className="brand" onClick={closeMenu}>
        <img src={isDark ? '/pio-logo.png' : '/pio-logo-light.png'} alt="PIO Logo" className="brand-logo" />
      </NavLink>

      <button
        type="button"
        className="menu-toggle"
        aria-label="Toggle navigation"
        aria-expanded={menuOpen}
        onClick={() => setMenuOpen((prev) => !prev)}
      >
        <span />
        <span />
        <span />
      </button>

      <div className={`nav-links ${menuOpen ? 'open' : ''}`}>
        <NavLink to="/" end onClick={closeMenu} className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>Board</NavLink>
        <NavLink to="/courses" onClick={closeMenu} className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>Mata Kuliah</NavLink>
        <NavLink to="/profile" onClick={closeMenu} className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`} style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
          <Avatar user={user} size={26} />
          <span>{user?.name?.split(' ')[0] || 'Profil'}</span>
        </NavLink>
        <button
          onClick={toggleTheme}
          className="btn btn-ghost theme-toggle"
          type="button"
          aria-label={isDark ? 'Aktifkan mode light' : 'Aktifkan mode dark'}
          title={isDark ? 'Mode light' : 'Mode dark'}
        >
          <span className="theme-icon" aria-hidden="true">{isDark ? '☀' : '🌙'}</span>
        </button>
        <button onClick={handleLogout} className="btn btn-outline" type="button" style={{ padding: '8px 12px' }}>
          Keluar
        </button>
      </div>
    </nav>
  );
}
