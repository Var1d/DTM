export default function Avatar({ user, size = 56 }) {
  const initial = user?.name?.[0]?.toUpperCase() || 'U';

  if (user?.avatar_url) {
    return (
      <img
        src={user.avatar_url}
        alt="Avatar"
        style={{
          width: size,
          height: size,
          borderRadius: '50%',
          objectFit: 'cover',
          border: '2px solid var(--border)',
        }}
      />
    );
  }

  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: '50%',
        background: 'linear-gradient(135deg, var(--primary), var(--primary-2))',
        display: 'grid',
        placeItems: 'center',
        fontWeight: 800,
      }}
    >
      {initial}
    </div>
  );
}
