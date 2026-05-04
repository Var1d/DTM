import { priorityConfig } from '../../utils/dateHelper';

export default function PriorityBadge({ priority }) {
  const cfg = priorityConfig(priority);
  return (
    <span
      style={{
        background: cfg.bg,
        color: cfg.text,
        padding: '3px 10px',
        borderRadius: 999,
        fontSize: 11,
        fontWeight: 700,
        border: '1px solid rgba(255,255,255,0.18)',
      }}
    >
      {cfg.label}
    </span>
  );
}
