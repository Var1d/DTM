import { useEffect, useMemo, useState } from 'react';
import Cropper from 'react-easy-crop';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import api from '../../utils/api';
import Input from '../../components/common/Input';
import Button from '../../components/common/Button';
import Avatar from '../../components/common/Avatar';
import { getCroppedImg } from '../../utils/cropImage';

export default function ProfilePage() {
  const { user, logout, syncUser } = useAuth();
  const navigate = useNavigate();
  const [name, setName] = useState(user?.name || '');
  const [oldPass, setOldPass] = useState('');
  const [newPass, setNewPass] = useState('');
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState('');

  const [avatarModalOpen, setAvatarModalOpen] = useState(false);
  const [cropImage, setCropImage] = useState(null);
  const [crop, setCrop] = useState({ x: 0, y: 0 });
  const [zoom, setZoom] = useState(1);
  const [croppedAreaPixels, setCroppedAreaPixels] = useState(null);

  const previewUrl = useMemo(() => (cropImage ? URL.createObjectURL(cropImage) : null), [cropImage]);
  useEffect(() => {
    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    };
  }, [previewUrl]);

  const saveProfile = async (e) => {
    e.preventDefault();
    setSaving(true);
    const { data } = await api.put('/user/profile', { name });
    syncUser({ ...user, ...data.data });
    setMsg('Profil berhasil diperbarui');
    setSaving(false);
  };

  const changePassword = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await api.put('/user/password', { old_password: oldPass, new_password: newPass });
      setMsg('Password berhasil diperbarui');
      setOldPass('');
      setNewPass('');
    } catch (err) {
      setMsg(err.response?.data?.message || 'Gagal mengganti password');
    } finally {
      setSaving(false);
    }
  };

  const handleAvatarSelect = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setCropImage(file);
    setCrop({ x: 0, y: 0 });
    setZoom(1);
    setAvatarModalOpen(true);
  };

  const handleUploadAvatar = async () => {
    if (!previewUrl || !croppedAreaPixels) return;
    setSaving(true);
    try {
      const croppedBlob = await getCroppedImg(previewUrl, croppedAreaPixels);
      const formData = new FormData();
      formData.append('avatar', croppedBlob, 'avatar.png');
      const { data } = await api.post('/user/avatar', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      syncUser({ ...user, ...data.data });
      setMsg('Foto profil berhasil diperbarui');
      setAvatarModalOpen(false);
      setCropImage(null);
    } catch (err) {
      setMsg(err.response?.data?.message || 'Gagal upload avatar');
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <div className="page-shell" style={{ maxWidth: 620 }}>
      <h2>Profil Saya</h2>
      <div className="glass-card" style={{ padding: 18, marginBottom: 12 }}>
        <div style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
          <Avatar user={user} size={72} />
          <div style={{ flex: 1 }}>
            <strong>{user?.name}</strong>
            <div style={{ color: 'var(--text-muted)' }}>{user?.email}</div>
          </div>
          <label className="btn btn-outline" style={{ cursor: 'pointer' }}>
            Ganti Foto
            <input type="file" accept="image/*" onChange={handleAvatarSelect} style={{ display: 'none' }} />
          </label>
        </div>
      </div>

      {msg && <div className="glass-card" style={{ padding: 12, marginBottom: 12 }}>{msg}</div>}

      <div className="glass-card" style={{ padding: 20, marginBottom: 12 }}>
        <h3 style={{ marginTop: 0 }}>Edit Profil</h3>
        <form onSubmit={saveProfile}><Input label="Nama" value={name} onChange={(e) => setName(e.target.value)} required /><Button type="submit" loading={saving} style={{ width: '100%' }}>Simpan Profil</Button></form>
      </div>

      <div className="glass-card" style={{ padding: 20, marginBottom: 12 }}>
        <h3 style={{ marginTop: 0 }}>Ganti Password</h3>
        <form onSubmit={changePassword}><Input label="Password Lama" type="password" value={oldPass} onChange={(e) => setOldPass(e.target.value)} required /><Input label="Password Baru" type="password" value={newPass} onChange={(e) => setNewPass(e.target.value)} required /><Button type="submit" variant="outline" loading={saving} style={{ width: '100%' }}>Ganti Password</Button></form>
      </div>

      <Button variant="danger" onClick={handleLogout} style={{ width: '100%' }}>Keluar dari Akun</Button>

      {avatarModalOpen && previewUrl && (
        <div className="modal-backdrop">
          <div className="glass-card modal-card" style={{ width: 520 }}>
            <h3 style={{ marginTop: 0 }}>Crop Foto Profil</h3>
            <div style={{ position: 'relative', width: '100%', height: 320, borderRadius: 12, overflow: 'hidden', marginBottom: 12 }}>
              <Cropper
                image={previewUrl}
                crop={crop}
                zoom={zoom}
                aspect={1}
                cropShape="round"
                showGrid={false}
                onCropChange={setCrop}
                onZoomChange={setZoom}
                onCropComplete={(_area, areaPixels) => setCroppedAreaPixels(areaPixels)}
              />
            </div>
            <div className="field">
              <label>Zoom</label>
              <input type="range" min={1} max={3} step={0.01} value={zoom} onChange={(e) => setZoom(Number(e.target.value))} />
            </div>
            <div style={{ display: 'flex', gap: 10 }}>
              <Button type="button" variant="outline" style={{ flex: 1 }} onClick={() => { setAvatarModalOpen(false); setCropImage(null); }}>Batal</Button>
              <Button type="button" style={{ flex: 1 }} loading={saving} onClick={handleUploadAvatar}>Simpan Foto</Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
