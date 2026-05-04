export default function Input({ label, error, ...props }) {
  return (
    <div className="field">
      {label && <label>{label}</label>}
      <input {...props} />
      {error && <p style={{ color: 'var(--danger)', fontSize: 12, marginTop: 5 }}>{error}</p>}
    </div>
  );
}
