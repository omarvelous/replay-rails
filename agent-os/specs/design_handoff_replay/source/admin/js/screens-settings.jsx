/* Settings + Publish workflow */
function Settings() {
  const [tab, setTab] = useState("branding");
  const tabs = [["branding","Branding"],["team","Team & Roles"],["billing","Billing"],["api","API & Devices"]];
  const team = [
    { n:"Maya Chen", e:"maya@vantagerealty.com", role:"Office Manager", c:"#2f6bff" },
    { n:"Dev Patel", e:"dev@vantagerealty.com", role:"Marketing Manager", c:"#0fb5a6" },
    { n:"Jordan Lee", e:"jordan@vantagerealty.com", role:"Leasing Manager", c:"#7c5cff" },
    { n:"Sam Rivera", e:"sam@vantagerealty.com", role:"Sales Gallery Manager", c:"#e8990f" },
    { n:"Alex Kim", e:"alex@vantagerealty.com", role:"Viewer", c:"#5b6470" },
  ];
  return (
    <div className="page" style={{ maxWidth:900 }}>
      <div className="ph-head"><div><h2>Settings</h2><p>Vantage Realty · Enterprise plan</p></div></div>
      <div style={{ display:"grid", gridTemplateColumns:"180px 1fr", gap:28, alignItems:"start" }}>
        <div style={{ display:"flex", flexDirection:"column", gap:2, position:"sticky", top:0 }}>
          {tabs.map(([v,l])=>(<button key={v} className="sb-item" style={{ color:tab===v?"var(--ink-900)":"var(--slate-500)", background:tab===v?"var(--surface-3)":"transparent" }} onClick={()=>setTab(v)}>{l}</button>))}
        </div>
        <div>
          {tab==="branding" && <>
            <Note><b>Branding cascades to every screen and mobile page.</b> Set it once here and ads inherit the brokerage's logo, colors, and contact details — keeping signage on-brand without designers in the loop.</Note>
            <div className="card card-pad" style={{ marginBottom:16 }}>
              <h3 style={{ fontSize:15, fontWeight:650, margin:"0 0 16px" }}>Logo & identity</h3>
              <div style={{ display:"flex", gap:16, alignItems:"center", marginBottom:18 }}>
                <div className="ph" data-label="logo" style={{ width:90, height:90, borderRadius:12, flex:"none" }}/>
                <div><button className="btn btn-secondary btn-sm"><Icon name="upload" size={14}/>Upload logo</button><div style={{ fontSize:12, color:"var(--slate-400)", marginTop:8 }}>SVG or PNG, min 512px. Shown on branding ads & QR pages.</div></div>
              </div>
              <div className="field" style={{ marginBottom:14 }}><label>Brokerage name</label><input className="input" defaultValue="Vantage Realty"/></div>
              <div><label style={{ fontSize:12.5, fontWeight:600, display:"block", marginBottom:8 }}>Brand colors</label>
                <div style={{ display:"flex", gap:10 }}>
                  {["#2f6bff","#0fb5a6","#0b0d12","#e8990f"].map(c=>(<div key={c} style={{ width:42, height:42, borderRadius:9, background:c, boxShadow:"var(--sh-xs)", border:"2px solid #fff", outline:"1px solid var(--line)" }}/>))}
                  <button style={{ width:42, height:42, borderRadius:9, border:"1.5px dashed var(--line)", background:"transparent", color:"var(--slate-400)", cursor:"pointer" }}><Icon name="plus" size={16}/></button>
                </div>
              </div>
            </div>
          </>}

          {tab==="team" && <>
            <Note><b>Roles map to real jobs, not abstract permissions.</b> A Leasing Manager edits their site's playlists but can't touch billing; a Viewer sees analytics only. This keeps a 50-person brokerage safe without an IT admin.</Note>
            <div className="tbl-wrap">
              <div className="ch"><h3>Team members</h3><button className="btn btn-primary btn-sm"><Icon name="plus" size={14}/>Invite</button></div>
              <table className="tbl"><tbody>
                {team.map((m,i)=>(<tr key={i}>
                  <td style={{paddingLeft:18}}><div style={{display:"flex",alignItems:"center",gap:11}}><Avatar name={m.n} color={m.c}/><div><div className="cell-strong">{m.n}</div><div style={{fontSize:12,color:"var(--slate-400)"}}>{m.e}</div></div></div></td>
                  <td style={{textAlign:"right"}}><select className="select" defaultValue={m.role} style={{ width:200, height:34, display:"inline-block" }}><option>{m.role}</option><option>Owner</option><option>Office Manager</option><option>Viewer</option></select></td>
                  <td style={{width:40,paddingRight:18}}><button className="icon-btn-sm"><Icon name="dots" size={16}/></button></td>
                </tr>))}
              </tbody></table>
            </div>
          </>}

          {tab==="billing" && <div className="card card-pad">
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start", marginBottom:20 }}>
              <div><div className="t-label">Current plan</div><div style={{ fontSize:24, fontWeight:700, letterSpacing:"-.02em", marginTop:6 }}>Enterprise</div><div style={{ fontSize:13, color:"var(--slate-400)" }}>16 screens · billed annually</div></div>
              <span className="badge badge-green"><span className="dot"/>Active</span>
            </div>
            <div style={{ display:"flex", gap:24, padding:"16px 0", borderTop:"1px solid var(--line)", borderBottom:"1px solid var(--line)", marginBottom:18 }}>
              <MiniStat label="Screens used" val="16 / 25"/><MiniStat label="Next invoice" val="$1,840"/><MiniStat label="Renews" val="Jan 2027"/>
            </div>
            <div style={{ fontSize:13, color:"var(--slate-400)" }}>Billing & payment-method management are placeholders in this prototype.</div>
          </div>}

          {tab==="api" && <div className="card card-pad">
            <h3 style={{ fontSize:15, fontWeight:650, margin:"0 0 6px" }}>API keys</h3>
            <p style={{ fontSize:13, color:"var(--slate-400)", margin:"0 0 16px" }}>Push listings from your MLS or CRM directly into RePlay. <i>(Placeholder)</i></p>
            <div style={{ display:"flex", alignItems:"center", gap:10, background:"var(--surface-2)", border:"1px solid var(--line)", borderRadius:9, padding:"11px 14px" }}>
              <Icon name="link" size={16} style={{ color:"var(--slate-400)" }}/>
              <span className="mono" style={{ fontSize:13, flex:1, color:"var(--slate-500)" }}>rp_live_••••••••••••••••3a9f</span>
              <button className="btn btn-secondary btn-sm">Reveal</button><button className="btn btn-secondary btn-sm">Rotate</button>
            </div>
          </div>}
        </div>
      </div>
    </div>
  );
}

/* ---------- Publish workflow modal ---------- */
function PublishModal({ onClose }) {
  const [view, setView] = useState("review"); // review | history
  const [published, setPublished] = useState(false);
  const versions = [
    { v:"v6", note:"Added Maple Ave hero + open house slide", who:"Maya Chen", time:"Live now", live:true },
    { v:"v5", note:"Reordered loop, trimmed brand slide to 6s", who:"Dev Patel", time:"2 days ago" },
    { v:"v4", note:"Swapped Williamsburg rentals", who:"Jordan Lee", time:"5 days ago" },
    { v:"v3", note:"Initial spring lineup", who:"Maya Chen", time:"2 weeks ago" },
  ];
  return (
    <div className="modal-bg" onClick={onClose}>
      <div className="modal" onClick={e=>e.stopPropagation()} style={{ maxWidth:560 }}>
        <div className="modal-head" style={{ position:"relative" }}>
          <button className="icon-btn-sm" style={{ position:"absolute", right:16, top:16 }} onClick={onClose}><Icon name="x" size={16}/></button>
          <div className="seg" style={{ marginBottom:14 }}>
            <button className={"seg-btn"+(view==="review"?" on":"")} onClick={()=>setView("review")}>Review & publish</button>
            <button className={"seg-btn"+(view==="history"?" on":"")} onClick={()=>setView("history")}>Version history</button>
          </div>
        </div>
        {view==="review" ? (
          published ? (
            <div className="modal-body" style={{ alignItems:"center", textAlign:"center", padding:"10px 22px 24px" }}>
              <div style={{ width:60, height:60, borderRadius:"50%", background:"var(--green-soft)", color:"var(--green)", display:"grid", placeItems:"center" }}><Icon name="check" size={30} sw={2.6}/></div>
              <div style={{ fontSize:17, fontWeight:650 }}>Published to 14 screens</div>
              <div style={{ fontSize:13, color:"var(--slate-400)" }}>Changes are now live across all assigned displays. v7 is the active version.</div>
            </div>
          ) : <>
            <div className="modal-body">
              <div style={{ display:"flex", gap:10, alignItems:"center" }}>
                <span className="badge badge-amber"><span className="dot"/>Draft</span><Icon name="chevronR" size={14} style={{color:"var(--slate-300)"}}/><span className="badge badge-blue">Will publish as v7</span>
              </div>
              <div style={{ border:"1px solid var(--line)", borderRadius:11, overflow:"hidden" }}>
                {[["3 slides changed","Maple Ave hero, open house, brand timing"],["14 screens affected","Across Bushwick & Williamsburg"],["Safe to roll back","Previous version kept for 90 days"]].map(([t,d],i)=>(
                  <div key={i} style={{ display:"flex", gap:11, padding:"12px 14px", borderBottom:i<2?"1px solid var(--line-2)":"none", alignItems:"center" }}>
                    <Icon name="check" size={16} style={{ color:"var(--green)", flex:"none" }}/>
                    <div style={{ flex:1 }}><div style={{ fontSize:13.5, fontWeight:600 }}>{t}</div><div style={{ fontSize:12, color:"var(--slate-400)" }}>{d}</div></div>
                  </div>
                ))}
              </div>
              <div className="field"><label>Add a note for the version history</label><input className="input" placeholder="What changed?" defaultValue="Added Maple Ave hero + open house slide"/></div>
            </div>
            <div className="modal-foot">
              <button className="btn btn-secondary" onClick={onClose}>Keep as draft</button>
              <button className="btn btn-primary" onClick={()=>setPublished(true)}><Icon name="upload" size={15}/>Publish to 14 screens</button>
            </div>
          </>
        ) : (
          <>
            <div className="modal-body" style={{ gap:0, padding:"6px 22px 8px" }}>
              {versions.map((v,i)=>(
                <div key={i} style={{ display:"flex", gap:13, padding:"13px 0", borderBottom:i<versions.length-1?"1px solid var(--line-2)":"none" }}>
                  <div style={{ display:"flex", flexDirection:"column", alignItems:"center" }}>
                    <span style={{ width:11, height:11, borderRadius:"50%", background:v.live?"var(--green)":"var(--slate-300)", border:"2px solid #fff", outline:v.live?"none":"1px solid var(--line)" }}/>
                    {i<versions.length-1 && <span style={{ flex:1, width:2, background:"var(--line)", marginTop:3 }}/>}
                  </div>
                  <div style={{ flex:1 }}>
                    <div style={{ display:"flex", alignItems:"center", gap:8 }}><span className="mono cell-strong">{v.v}</span>{v.live && <span className="badge badge-green" style={{fontSize:10.5}}>Live</span>}<span style={{ marginLeft:"auto", fontSize:12, color:"var(--slate-400)" }}>{v.time}</span></div>
                    <div style={{ fontSize:13, marginTop:3 }}>{v.note}</div>
                    <div style={{ fontSize:11.5, color:"var(--slate-400)", marginTop:2 }}>by {v.who}</div>
                    {!v.live && <button className="btn btn-secondary btn-sm" style={{ marginTop:8 }}><Icon name="refresh" size={13}/>Restore this version</button>}
                  </div>
                </div>
              ))}
            </div>
            <div className="modal-foot"><button className="btn btn-secondary" onClick={onClose}>Close</button></div>
          </>
        )}
      </div>
    </div>
  );
}
window.Settings = Settings; window.PublishModal = PublishModal;
