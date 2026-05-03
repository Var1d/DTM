export default function Button({ children, loading, variant='primary', ...props }) {
  const bg = variant === 'primary' ? '#6366f1' : variant === 'danger' ? '#ef4444' : '#fff';
  const color = variant === 'outline' ? '#6366f1' : '#fff';
  const border = variant === 'outline' ? '1px solid #6366f1' : 'none';
  return (
    <button {...props} disabled={loading || props.disabled}
      style={{background:bg,color,border,padding:'10px 20px',borderRadius:10,fontWeight:600,fontSize:14,cursor:'pointer',opacity:(loading||props.disabled)?0.6:1,...props.style}}>
      {loading ? 'Loading...' : children}
    </button>
  );
}
