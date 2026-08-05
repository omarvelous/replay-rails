/* Analytics — overview with charts, heatmap, rankings */
function Analytics() {
  const [tab, setTab] = useState("overview");
  const tabs = [["overview","Overview"],["sites","Sites"],["screens","Screens"],["ads","Ads"],["campaigns","Campaigns"],["qr","QR Scans"]];
  return (
    <div className="page">
      <Note>
        <b>Analytics answers “is this working?” in business terms.</b> The north-star is <b>QR scans → engagement</b>, not vanity impressions. We lead with the trend and the breakdowns a brokerage owner actually acts on: which sites, which ads, and when foot-traffic peaks (the heatmap drives smarter scheduling).
      </Note>
      <div className="ph-head">
        <div><h2>Analytics</h2><p>Last 30 days · updated 6m ago</p></div>
        <div className="ph-actions">
          <button className="chip"><Icon name="calendar" size={14}/>Last 30 days</button>
          <button className="btn btn-secondary"><Icon name="upload" size={15}/>Export</button>
        </div>
      </div>

      <div className="seg" style={{ marginBottom:20 }}>
        {tabs.map(([v,l])=>(<button key={v} className={"seg-btn"+(tab===v?" on":"")} onClick={()=>setTab(v)}>{l}</button>))}
      </div>

      {tab==="overview" && <AnalyticsOverview/>}
      {tab==="qr" && <AnalyticsOverview qr/>}
      {tab!=="overview" && tab!=="qr" && <AnalyticsRanked tab={tab}/>}
    </div>
  );
}

function AnalyticsOverview({ qr }) {
  const trend = [4.2,4.8,4.5,5.6,6.1,5.4,6.8,7.2,6.4,8.1,8.8,9.4,8.2,9.9,11.1,10.2,11.8,12.4,11,13.2,12.8];
  return (
    <>
      <div className="page-grid" style={{ gridTemplateColumns:"repeat(4,1fr)", marginBottom:16 }}>
        <StatCard label="QR scans" value="12,840" icon="qr" accent="#2f6bff" delta="+34%" deltaDir="up" spark={[6,7,6,8,9,8,11,12]}/>
        <StatCard label="Unique scanners" value="9,210" icon="players" accent="#0fb5a6" delta="+28%" deltaDir="up" spark={[5,6,7,6,8,9,10,11]}/>
        <StatCard label="Avg dwell" value="2:14" icon="clock" accent="#7c5cff" delta="+11%" deltaDir="up" spark={[3,4,4,5,5,6,6,7]}/>
        <StatCard label="Scan-through rate" value="14.2%" icon="analytics" accent="#e8990f" delta="-2%" deltaDir="down" spark={[8,7,8,7,6,7,6,6]}/>
      </div>

      <div className="page-grid" style={{ gridTemplateColumns:"1.5fr 1fr", alignItems:"start", marginBottom:16 }}>
        <div className="card">
          <div className="ch"><h3>{qr?"QR scans over time":"Engagement trend"}</h3><span style={{ fontSize:12.5, color:"var(--slate-400)" }}>scans per day (k)</span></div>
          <div style={{ padding:"20px 20px 14px" }}><AreaChart data={trend}/></div>
        </div>
        <div className="card">
          <div className="ch"><h3>Scans by site</h3></div>
          <div style={{ padding:"16px 20px 18px", display:"flex", flexDirection:"column", gap:14 }}>
            {SITES.slice().sort((a,b)=>b.scans-a.scans).map(s=>{
              const max=Math.max(...SITES.map(x=>x.scans));
              return (<div key={s.id}><div style={{ display:"flex", justifyContent:"space-between", marginBottom:6, fontSize:13 }}><span style={{fontWeight:550}}>{s.name}</span><span className="mono cell-strong">{s.scans.toLocaleString()}</span></div>
                <div className="bar"><span style={{ width:(s.scans/max*100)+"%", background:s.color }}/></div></div>);
            })}
          </div>
        </div>
      </div>

      <div className="page-grid" style={{ gridTemplateColumns:"1fr 1fr", alignItems:"start" }}>
        {/* heatmap */}
        <div className="card">
          <div className="ch"><h3>Foot-traffic heatmap</h3><span style={{ fontSize:12.5, color:"var(--slate-400)" }}>scans by hour × day</span></div>
          <div style={{ padding:"18px 20px 20px" }}><Heatmap/></div>
        </div>
        {/* device + top ads */}
        <div className="card">
          <div className="ch"><h3>Top performing ads</h3></div>
          <table className="tbl">
            <tbody>{TOP_ADS.map((a,i)=>(
              <tr key={i}><td style={{paddingLeft:18}}><div style={{display:"flex",alignItems:"center",gap:11}}>
                <span style={{width:22,height:22,borderRadius:6,display:"grid",placeItems:"center",fontSize:11,fontWeight:700,background:"var(--surface-3)",color:"var(--slate-500)"}}>{i+1}</span>
                <span className="cell-strong">{a.name}</span></div></td>
                <td className="mono cell-strong" style={{textAlign:"right"}}>{a.scans}</td>
                <td style={{width:90}}><div className="bar"><span style={{width:(a.ctr/20*100)+"%",background:"linear-gradient(90deg,#2f6bff,#0fb5a6)"}}/></div></td>
                <td className="mono muted" style={{paddingRight:18,fontSize:12}}>{a.ctr}%</td></tr>
            ))}</tbody>
          </table>
        </div>
      </div>
    </>
  );
}

function AnalyticsRanked({ tab }) {
  const data = {
    sites: SITES.map(s=>({name:s.name, val:s.scans, color:s.color})),
    screens: SCREENS.filter(s=>s.status==="live").map((s,i)=>({name:s.name+" · "+s.site, val:Math.round(2000-i*180+Math.random()*100), color:"#2f6bff"})),
    ads: TOP_ADS.map(a=>({name:a.name, val:a.scans, color:"#0fb5a6"})),
    campaigns: CAMPAIGNS.map(c=>({name:c.name, val:c.scans, color:c.color})),
  }[tab].sort((a,b)=>b.val-a.val);
  const max = Math.max(...data.map(d=>d.val));
  return (
    <div className="card">
      <div className="ch"><h3 style={{textTransform:"capitalize"}}>{tab} ranked by scans</h3><span style={{ fontSize:12.5, color:"var(--slate-400)" }}>last 30 days</span></div>
      <div style={{ padding:"18px 22px 22px", display:"flex", flexDirection:"column", gap:16 }}>
        {data.map((d,i)=>(
          <div key={i} style={{ display:"flex", alignItems:"center", gap:14 }}>
            <span style={{ width:22, fontSize:12, fontWeight:700, color:"var(--slate-400)" }}>{i+1}</span>
            <div style={{ flex:1 }}><div style={{ display:"flex", justifyContent:"space-between", marginBottom:6, fontSize:13 }}><span style={{fontWeight:550}}>{d.name}</span><span className="mono cell-strong">{d.val.toLocaleString()}</span></div>
              <div className="bar" style={{height:8}}><span style={{ width:(d.val/max*100)+"%", background:d.color }}/></div></div>
          </div>
        ))}
      </div>
    </div>
  );
}

function AreaChart({ data, h=200 }) {
  const w=620, max=Math.max(...data)*1.1, min=0;
  const pts=data.map((d,i)=>[i/(data.length-1)*w, h-((d-min)/(max-min))*h]);
  const path=pts.map((p,i)=>(i?"L":"M")+p[0].toFixed(1)+" "+p[1].toFixed(1)).join(" ");
  return (
    <svg viewBox={`0 0 ${w} ${h}`} style={{ width:"100%", height:h }} preserveAspectRatio="none">
      <defs><linearGradient id="ac" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor="#2f6bff" stopOpacity=".22"/><stop offset="1" stopColor="#2f6bff" stopOpacity="0"/></linearGradient></defs>
      {[0,.25,.5,.75,1].map(g=>(<line key={g} x1="0" x2={w} y1={h*g} y2={h*g} stroke="#eef0f3" strokeWidth="1"/>))}
      <path d={path+` L${w} ${h} L0 ${h} Z`} fill="url(#ac)"/>
      <path d={path} fill="none" stroke="#2f6bff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"/>
      {pts.map((p,i)=> i===pts.length-1 ? <circle key={i} cx={p[0]} cy={p[1]} r="4.5" fill="#2f6bff" stroke="#fff" strokeWidth="2"/> : null)}
    </svg>
  );
}

function Heatmap() {
  const days=["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
  const hours=["8a","10a","12p","2p","4p","6p","8p"];
  // weighted: weekends + midday hot
  const val=(d,h)=>{ const wk=d>=5?1.4:1; const mid=1-Math.abs(h-3.5)/4; return Math.min(1, (mid*0.8+0.15)*wk*(0.7+Math.random()*0.5)); };
  return (
    <div>
      <div style={{ display:"grid", gridTemplateColumns:"30px repeat(7,1fr)", gap:4 }}>
        <div/>{days.map(d=><div key={d} style={{ textAlign:"center", fontSize:10.5, color:"var(--slate-400)", fontWeight:600 }}>{d}</div>)}
        {hours.map((hr,hi)=>(<React.Fragment key={hr}>
          <div style={{ fontSize:10, color:"var(--slate-400)", display:"flex", alignItems:"center" }}>{hr}</div>
          {days.map((d,di)=>{ const v=val(di,hi); return <div key={d} title={Math.round(v*100)+" scans"} style={{ aspectRatio:"1.4", borderRadius:5, background:`rgba(47,107,255,${0.08+v*0.85})` }}/>; })}
        </React.Fragment>))}
      </div>
      <div style={{ display:"flex", alignItems:"center", gap:8, marginTop:14, fontSize:11, color:"var(--slate-400)" }}>
        Less<div style={{ display:"flex", gap:3 }}>{[.1,.3,.5,.7,.95].map(o=><span key={o} style={{ width:14, height:14, borderRadius:4, background:`rgba(47,107,255,${o})` }}/>)}</div>More
        <span style={{ marginLeft:"auto" }}>Peak: <b style={{color:"var(--ink-800)"}}>Sat 2–4PM</b></span>
      </div>
    </div>
  );
}
window.Analytics = Analytics;
