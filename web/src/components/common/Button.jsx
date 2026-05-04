export default function Button({ children, loading, variant = 'primary', className = '', ...props }) {
  const variantClass = variant === 'outline' ? 'btn-outline' : variant === 'danger' ? 'btn-danger' : variant === 'ghost' ? 'btn-ghost' : 'btn-primary';

  return (
    <button
      {...props}
      disabled={loading || props.disabled}
      className={`btn ${variantClass} ${className}`.trim()}
      style={props.style}
    >
      {loading ? 'Loading...' : children}
    </button>
  );
}
