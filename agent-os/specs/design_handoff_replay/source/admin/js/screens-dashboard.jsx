/* Dashboard — executive overview */
function Dashboard({ go }) {
  const [setupOpen, setSetupOpen] = useState(true);
  const scansData = [620, 710, 680, 940, 1020, 880, 1180, 1240, 1090, 1380, 1510, 1840];
  const days = ["Jun","Jul","Aug","Sep","Oct","Nov","Dec","Jan","Feb","Mar","Apr","May"];
  const maxScan = Math.max(...scansData);
  const kindColor = { publish: "#2f6bff", alert: "#e5484d", create: "#0fb5a6", schedule: "#7c5cff", metric: "#1f9d57", rollback: "#e8990f" };
  const quick = [
    ["Create an ad", "Design a listing or promo", "ad-builder", "ads", "#2f6bff"],
    ["Build a playlist", "Sequence what plays", "playlist-builder", "playlists", "#0fb5a6"],
    ["Add a screen", "Pair a new display", "screens", "screens", "#7c5cff"],
    ["View analytics", "Scans & engagement", "analytics", "analytics", "#e8990f"],
  ];
  const setup = [
    ["Connect your first site", true], ["Pair a player device", true],
    ["Add listings from MLS", true], ["Build your first playlist", false], ["Publish to a screen", false],
  ];
  const doneCount = setup.filter(s => s[1]).length;

  return (
    <div className="page">
      {setupOpen && doneCount < setup.length && (
        <div className="setup-card">
          <div className="setup-ring"><Donut value={doneCount/setup.length*100} size={64} stroke={8} color="#fff" track="rgba(255,255,255,.25)" label={doneCount+"/"+setup.length}/></div>
          <div className="setup-body">
            <div className="setup-t">Finish setting up RePlay</div>
            <div className="setup-steps">
              {setup.map(([label, ok], i) => (
                <button key={i} className={"setup-step" + (ok ? " ok" : "")} onClick={() => !ok && go(i===3?"playlist-builder":"screens")}>
                  <span className="setup-check">{ok ? <Icon name="check" size={12} sw={3}/> : i+1}</span>{label}
                </button>
              ))}
            </div>
          </div>
          <button className="setup-x" onClick={() => setSetupOpen(false)} title="Dismiss"><Icon name="x" size={16}/></button>
        </div>
      )}

      <div className="quick-row">
        {quick.map(([t,d,route,icon,c]) => (
          <button key={t} className="quick-card" onClick={() => go(route)}>
            <span className="quick-ic" style={{ background: c+"18", color: c }}><Icon name={icon} size={18}/></span>
            <span className="quick-meta"><span className="qt">{t}</span><span className="qd">{d}</span></span>
            <Icon name="chevronR" size={15} style={{ color: "var(--slate-300)", marginLeft: "auto" }}/>
          </button>
        ))}
      </div>

      <Note>
        <b>Why this layout:</b> Managers open RePlay to answer one question — “is everything running, and is it working?” The top KPI strip answers <b>running</b> (network health) and <b>working</b> (scans) at a glance; the chart and top-ads rank what's driving results; the activity feed and health panel give an at-a-glance audit trail. Actionable, not a wall of widgets.
      </Note>

      <div className="page-grid" style={{ gridTemplateColumns: "repeat(5, 1fr)", marginBottom: 16 }}>
        <StatCard label="Sites" value="5" icon="sites" accent="#2f6bff" delta="+1" deltaDir="up" />
        <StatCard label="Active screens" value="14" icon="screens" accent="#0fb5a6" delta="93%" deltaDir="up" />
        <StatCard label="Online players" value="13/14" icon="players" accent="#1f9d57" />
        <StatCard label="Active campaigns" value="3" icon="campaigns" accent="#7c5cff" />
        <StatCard label="QR scans today" value="1,840" icon="qr" accent="#e8990f" delta="+21%" deltaDir="up" />
      </div>

      <div className="page-grid" style={{ gridTemplateColumns: "1.6fr 1fr", alignItems: "start" }}>
        {/* LEFT */}
        <div className="page-grid">
          {/* scans chart */}
          <div className="card">
            <div className="ch">
              <div>
                <h3>QR scans</h3>
                <div style={{ fontSize: 12.5, color: "var(--slate-400)", marginTop: 2 }}>Last 12 months · all sites</div>
              </div>
              <Segmented options={[{value:"12m",label:"12M"},{value:"30d",label:"30D"},{value:"7d",label:"7D"}]} value="12m" onChange={()=>{}} />
            </div>
            <div style={{ padding: "20px 20px 16px" }}>
              <div style={{ display: "flex", alignItems: "baseline", gap: 12, marginBottom: 18 }}>
                <span className="t-display tabular" style={{ fontSize: 34 }}>12,840</span>
                <span className="stat-delta up"><Icon name="arrowUp" size={12} sw={2.4}/>+34% vs last yr</span>
              </div>
              <div className="bars" style={{ height: 150 }}>
                {scansData.map((v, i) => (
                  <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 7 }}>
                    <div className="b" style={{ width: "100%", height: (v/maxScan*150)+"px",
                      background: i === scansData.length-1 ? "linear-gradient(180deg,#2f6bff,#0fb5a6)" : "var(--surface-3)",
                      borderRadius: "5px 5px 0 0" }} title={v+" scans"} />
                    <span style={{ fontSize: 10.5, color: "var(--slate-400)" }}>{days[i]}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* top ads */}
          <div className="card">
            <div className="ch"><h3>Top performing ads</h3><span className="ch-link" onClick={()=>go("analytics")}>View analytics</span></div>
            <table className="tbl">
              <thead><tr><th style={{paddingLeft:18}}>Ad</th><th>Campaign</th><th>Scans</th><th>Scan-through</th></tr></thead>
              <tbody>
                {TOP_ADS.map((a,i)=>(
                  <tr key={i}>
                    <td style={{paddingLeft:18}}><div style={{display:"flex",alignItems:"center",gap:11}}>
                      <span style={{width:22,height:22,borderRadius:6,display:"grid",placeItems:"center",fontSize:11,fontWeight:700,background:"var(--surface-3)",color:"var(--slate-500)"}}>{i+1}</span>
                      <span className="cell-strong">{a.name}</span></div></td>
                    <td className="muted">{a.camp}</td>
                    <td className="mono cell-strong">{a.scans}</td>
                    <td><div style={{display:"flex",alignItems:"center",gap:8}}>
                      <div className="bar" style={{width:64}}><span style={{width:(a.ctr/20*100)+"%",background:"linear-gradient(90deg,#2f6bff,#0fb5a6)"}}/></div>
                      <span className="mono" style={{fontSize:12,color:"var(--slate-500)"}}>{a.ctr}%</span></div></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* RIGHT */}
        <div className="page-grid">
          {/* network health */}
          <div className="card card-pad">
            <div style={{ display: "flex", alignItems: "center", gap: 18 }}>
              <Donut value={93} label="93%" sub="uptime" color="#1f9d57" />
              <div style={{ flex: 1 }}>
                <h3 style={{ fontSize: 15, fontWeight: 650, margin: "0 0 10px" }}>Network health</h3>
                <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
                  <HealthRow color="#1f9d57" label="Online players" val="13" />
                  <HealthRow color="#e5484d" label="Offline" val="1" />
                  <HealthRow color="#8a929e" label="Unassigned screens" val="1" />
                </div>
              </div>
            </div>
            <button className="btn btn-secondary" style={{ width: "100%", marginTop: 16 }} onClick={()=>go("players")}>
              <Icon name="players" size={15}/>Inspect players
            </button>
          </div>

          {/* recent activity */}
          <div className="card">
            <div className="ch"><h3>Recent activity</h3><span className="ch-link">View all</span></div>
            <div style={{ padding: "8px 6px" }}>
              {ACTIVITY.map((a,i)=>(
                <div key={i} style={{ display:"flex", gap:11, padding:"9px 12px", borderRadius:9, alignItems:"flex-start" }}>
                  <span style={{ width:8, height:8, borderRadius:"50%", background:kindColor[a.kind], marginTop:6, flex:"none", boxShadow:`0 0 0 3px ${kindColor[a.kind]}22` }} />
                  <div style={{ flex:1, fontSize:13, lineHeight:1.5 }}>
                    <b style={{fontWeight:650}}>{a.who}</b> <span className="muted">{a.act}</span> <span style={{fontWeight:600}}>{a.obj}</span>
                    <div style={{ fontSize:11.5, color:"var(--slate-400)", marginTop:1 }}>{a.time}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function HealthRow({ color, label, val }) {
  return (
    <div style={{ display:"flex", alignItems:"center", gap:8, fontSize:13 }}>
      <span style={{ width:8, height:8, borderRadius:"50%", background:color }} />
      <span className="muted" style={{ flex:1 }}>{label}</span>
      <span className="cell-strong mono">{val}</span>
    </div>
  );
}
window.Dashboard = Dashboard;
