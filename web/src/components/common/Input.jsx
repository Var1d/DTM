export default function Input({ label, error, ...props }) {
  return (
    <div style={{marginBottom:16}}>
      {label && <label style={{display:'block',marginBottom:6,fontWeight:500,fontSize:14}}>{label}</label>}
      <input {...props} style={{width:'100%',padding:'10px 14px',border:`1px solid ${error?'#ef4444':'#d1d5db'}`,borderRadius:10,fontSize:14,boxSizing:'border-box',outline:'none'}} />
      {error && <p style={{color:'#ef4444',fontSize:12,marginTop:4}}>{error}</p>}
    </div>
  );
}
