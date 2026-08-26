/* Players management — devices + registration workflow */
function Players({ go }) {
  const [reg, setReg] = useState(false);
  const [detail, setDetail] = useState(null);
  const hwIcon = { "Amazon Fire TV Stick 4K":"#ff9900", "RePlay Signage Stick":"#2f6bff", "Raspberry Pi 4 (4GB)":"#c51a4a" };
  return (
    <div className="page">
      <Note>
        <b>Players = the devices behind the screens.</b> This is the most technical object, so the screen leads with the one thing that breaks — <b>connectivity</b>. Version numbers surface stale firmware (note B2 is two versions behind and offline). Registration is a guided pairing flow, not a config form, so a non-technical manager can bring a Fire Stick online in under a minute.
      </Note>

      <div className="ph-head">
        <div><h2>Players</h2><p>{PLAYERS.length} devices · {PLAYERS.filter(p=>p.status==="online").length} online · 1 needs attention</p></div>
        <div className="ph-actions">
          <button className="btn btn-secondary"><Icon name="refresh" size={15}/>Check for updates</button>
          <button className="btn btn-primary" onClick={()=>setReg(true)}><Icon name="plus" size={15}/>Register device</button>
        </div>
      </div>

      {/* alert banner */}
      <div style={{ display:"flex", alignItems:"center", gap:12, background:"var(--red-soft)", border:"1px solid #f5c6c8", borderRadius:11, padding:"12px 16px", marginBottom:18 }}>
        <Icon name="wifiOff" size={18} style={{ color:"var(--red)", flex:"none" }}/>
        <div style={{ fontSize:13, color:"#a3282c", flex:1 }}><b>Signage Stick · B2</b> at Williamsburg Leasing went offline 2 hours ago. The Corner Display is currently dark.</div>
        <button className="btn btn-sm" style={{ background:"#fff", color:"var(--red)", border:"1px solid #f5c6c8" }} onClick={()=>setDetail(PLAYERS.find(p=>p.status==="offline"))}>Troubleshoot</button>
      </div>

      <div className="tbl-wrap">
        <table className="tbl">
          <thead><tr><th style={{paddingLeft:18}}>Device</th><th>Hardware</th><th>Site</th><th>Assigned screen</th><th>Version</th><th>Uptime</th><th>Status</th><th></th></tr></thead>
          <tbody>
            {PLAYERS.map(p=>(
              <tr key={p.id} style={{ cursor:"pointer" }} onClick={()=>setDetail(p)}>
                <td style={{paddingLeft:18}}><div style={{ display:"flex", alignItems:"center", gap:11 }}>
                  <span style={{ width:32, height:32, borderRadius:8, display:"grid", placeItems:"center", background:(hwIcon[p.hw]||"#5b6470")+"18", color:hwIcon[p.hw]||"#5b6470" }}><Icon name="players" size={16}/></span>
                  <span className="cell-strong mono scr-link" style={{ fontSize:13 }}>{p.name}</span></div></td>
                <td className="muted">{p.hw}</td>
                <td className="muted">{p.site}</td>
                <td className="muted">{p.screen}</td>
                <td><span className={"mono"} style={{ fontSize:12.5, color: p.version==="2.8.1"?"var(--slate-500)":"var(--amber)" }}>v{p.version}{p.version!=="2.8.1" && p.status!=="offline" ? "" : ""}{p.version==="2.6.9"?" ↑":""}</span></td>
                <td className="muted mono" style={{ fontSize:12.5 }}>{p.uptime}</td>
                <td>{p.status==="online"
                  ? <span className="badge badge-green"><span className="dot"/>Online</span>
                  : <span className="badge badge-red"><span className="dot"/>Offline</span>}</td>
                <td><button className="icon-btn-sm" onClick={e=>e.stopPropagation()}><Icon name="dots" size={16}/></button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {reg && <RegisterModal onClose={()=>setReg(false)}/>}
      {detail && <PlayerDetail player={detail} onClose={()=>setDetail(null)} go={go}/>}
    </div>
  );
}

function RegisterModal({ onClose }) {
  const [step, setStep] = useState(1);
  const [paired, setPaired] = useState(false);
  useEffect(()=>{ if(step===2){ const t=setTimeout(()=>setPaired(true), 2600); return ()=>clearTimeout(t);} }, [step]);
  const code = "R7 K2 9X";
  return (
    <div className="modal-bg" onClick={onClose}>
      <div className="modal" onClick={e=>e.stopPropagation()} style={{ maxWidth:480 }}>
        <div className="modal-head" style={{ position:"relative" }}>
          <button className="icon-btn-sm" style={{ position:"absolute", right:16, top:16 }} onClick={onClose}><Icon name="x" size={16}/></button>
          <h3>Register a device</h3>
          <p>{step===1?"Pick your hardware to see setup steps.":paired?"Device paired successfully.":"Enter this code on the device screen."}</p>
        </div>
        <div className="modal-body">
          {step===1 ? (
            <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
              {[["Amazon Fire TV Stick 4K","#ff9900","Install the RePlay app from the Appstore"],["RePlay Signage Stick","#2f6bff","Ships pre-loaded — just power on"],["Raspberry Pi 4","#c51a4a","Flash RePlay OS to the SD card"]].map(([n,c,d])=>(
                <button key={n} className="chip" style={{ justifyContent:"flex-start", padding:"14px 14px", height:"auto", textAlign:"left" }} onClick={()=>setStep(2)}>
                  <span style={{ width:38, height:38, borderRadius:9, display:"grid", placeItems:"center", background:c+"18", color:c, flex:"none" }}><Icon name="players" size={18}/></span>
                  <span style={{ flex:1 }}><span style={{ display:"block", fontSize:14, fontWeight:650, color:"var(--ink-900)" }}>{n}</span><span style={{ fontSize:12, color:"var(--slate-400)" }}>{d}</span></span>
                  <Icon name="chevronR" size={16} style={{ color:"var(--slate-300)" }}/>
                </button>
              ))}
            </div>
          ) : (
            <div style={{ textAlign:"center", padding:"10px 0 6px" }}>
              {!paired ? <>
                <div style={{ display:"flex", justifyContent:"center", gap:10, marginBottom:18 }}>
                  {code.split(" ").map((c,i)=>(<span key={i} className="mono" style={{ fontSize:30, fontWeight:700, letterSpacing:"-.02em", background:"var(--surface-3)", borderRadius:11, padding:"12px 16px", color:"var(--ink-900)" }}>{c}</span>))}
                </div>
                <div style={{ display:"inline-flex", alignItems:"center", gap:8, fontSize:13, color:"var(--slate-500)" }}>
                  <span style={{ width:14, height:14, border:"2px solid var(--line)", borderTopColor:"var(--blue)", borderRadius:"50%", animation:"spin .8s linear infinite", display:"inline-block" }}/>
                  Waiting for device to connect…
                </div>
              </> : <>
                <div style={{ width:60, height:60, borderRadius:"50%", background:"var(--green-soft)", color:"var(--green)", display:"grid", placeItems:"center", margin:"0 auto 14px" }}><Icon name="check" size={30} sw={2.6}/></div>
                <div style={{ fontSize:16, fontWeight:650 }}>FireStick-4K · A5 connected</div>
                <div style={{ fontSize:13, color:"var(--slate-400)", marginTop:4 }}>Running RePlay v2.8.1 · Assign it to a screen next.</div>
              </>}
            </div>
          )}
        </div>
        <div className="modal-foot">
          <button className="btn btn-secondary" onClick={onClose}>{paired?"Later":"Cancel"}</button>
          {step===2 && paired && <button className="btn btn-primary" onClick={onClose}>Assign to screen</button>}
        </div>
      </div>
    </div>
  );
}
window.Players = Players;
