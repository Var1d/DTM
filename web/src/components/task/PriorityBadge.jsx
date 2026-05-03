import { priorityConfig } from '../../utils/dateHelper';

export default function PriorityBadge({ priority }) {
  const cfg = priorityConfig(priority);
  return (
    <span style={{background:cfg.bg,color:cfg.text,padding:'2px 10px',borderRadius:20,fontSize:12,fontWeight:600}}>
      {cfg.label}
    </span>
  );
}
