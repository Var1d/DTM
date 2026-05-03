import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import api from '../../utils/api';
import Input from '../../components/common/Input';
import Button from '../../components/common/Button';

export default function ProfilePage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [name,    setName]    = useState(user?.name || '');
  const [oldPass, setOldPass] = useState('');
  const [newPass, setNewPass] = useState('');
  const [saving,  setSaving]  = useState(false);
  const [msg,     setMsg]     = useState('');

  const saveProfile = async (e) => {
    e.preventDefault(); setSaving(true);
    await api.put('/user/profile', { name });
    setMsg('Profil berhasil diperbarui'); setSaving(false);
  };

  const changePassword = async (e) => {
    e.preventDefault(); setSaving(true);
    try {
      await api.put('/user/password', { old_password: oldPass, new_password: newPass });
      setMsg('Password berhasil diperbarui'); setOldPass(''); setNewPass('');
    } catch (err) {
      setMsg(err.response?.data?.message || 'Gagal mengganti password');
    } finally { setSaving(false); }
  };

  const handleLogout = async () => { await logout(); navigate('/login'); };

  return (
    <div style={{padding:24,maxWidth:500,margin:'0 auto'}}>
      <h2>Profil Saya</h2>

      {/* Avatar */}
      <div style={{display:'flex',alignItems:'center',gap:16,marginBottom:28,background:'#fff',borderRadius:12,padding:20,boxShadow:'0 1px 4px rgba(0,0,0,0.06)'}}>
        <div style={{width:56,height:56,borderRadius:'50%',background:'#6366f1',display:'flex',alignItems:'center',justifyContent:'center',color:'#fff',fontSize:24,fontWeight:700}}>
          {user?.name?.[0]?.toUpperCase()}
        </div>
        <div>
          <p style={{margin:0,fontWeight:600,fontSize:16}}>{user?.name}</p>
          <p style={{margin:0,color:'#6b7280',fontSize:14}}>{user?.email}</p>
        </div>
      </div>

      {msg && <div style={{background:'#dcfce7',color:'#166534',padding:'10px 16px',borderRadius:10,marginBottom:16,fontSize:14}}>{msg}</div>}

      {/* Form profil */}
      <div style={{background:'#fff',borderRadius:12,padding:24,boxShadow:'0 1px 4px rgba(0,0,0,0.06)',marginBottom:16}}>
        <h3 style={{marginTop:0,fontSize:16}}>Edit Profil</h3>
        <form onSubmit={saveProfile}>
          <Input label="Nama" value={name} onChange={e=>setName(e.target.value)} required />
          <Button type="submit" loading={saving} style={{width:'100%'}}>Simpan Profil</Button>
        </form>
      </div>

      {/* Form ganti password */}
      <div style={{background:'#fff',borderRadius:12,padding:24,boxShadow:'0 1px 4px rgba(0,0,0,0.06)',marginBottom:16}}>
        <h3 style={{marginTop:0,fontSize:16}}>Ganti Password</h3>
        <form onSubmit={changePassword}>
          <Input label="Password Lama" type="password" value={oldPass} onChange={e=>setOldPass(e.target.value)} required />
          <Input label="Password Baru" type="password" value={newPass} onChange={e=>setNewPass(e.target.value)} required />
          <Button type="submit" variant="outline" loading={saving} style={{width:'100%'}}>Ganti Password</Button>
        </form>
      </div>

      <Button variant="danger" onClick={handleLogout} style={{width:'100%'}}>Keluar dari Akun</Button>
    </div>
  );
}
