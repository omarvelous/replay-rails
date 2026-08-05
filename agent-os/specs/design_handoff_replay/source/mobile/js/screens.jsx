/* RePlay — Mobile QR landing screens */
function StatusBar({ dark }) {
  return <div className={"mob-status"+(dark?" on-dark":"")}>
    <span>9:41</span>
    <span className="sb-r">
      <svg viewBox="0 0 18 12" fill="currentColor"><rect x="0" y="7" width="3" height="5" rx="1"/><rect x="5" y="4" width="3" height="8" rx="1"/><rect x="10" y="1.5" width="3" height="10.5" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1" opacity=".35"/></svg>
      <svg viewBox="0 0 16 12" fill="currentColor"><path d="M8 2.5c2.2 0 4.2.8 5.7 2.2l-1.4 1.4A6 6 0 0 0 8 4.5 6 6 0 0 0 3.7 6.1L2.3 4.7A8 8 0 0 1 8 2.5z" opacity=".9"/><circle cx="8" cy="9.5" r="1.6"/></svg>
      <svg viewBox="0 0 26 12" fill="none"><rect x="1" y="1" width="21" height="10" rx="3" stroke="currentColor" strokeWidth="1.2" opacity=".5"/><rect x="2.5" y="2.5" width="16" height="7" rx="1.5" fill="currentColor"/><rect x="23.5" y="4" width="1.5" height="4" rx=".75" fill="currentColor" opacity=".5"/></svg>
    </span>
  </div>;
}
function MI({ d, size=20, sw=1.8, fill }) { return <svg width={size} height={size} viewBox="0 0 24 24" fill={fill||"none"} stroke={fill?"none":"currentColor"} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">{d}</svg>; }
const I_back = <path d="m15 18-6-6 6-6"/>;
const I_heart = <path d="M19 14c1.5-1.5 3-3.3 3-5.5A4.5 4.5 0 0 0 12 5 4.5 4.5 0 0 0 2 8.5C2 13 12 21 12 21s4-3 7-7z"/>;
const I_share = <><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="m8.6 13.5 6.8 4M15.4 6.5l-6.8 4"/></>;
const I_phone = <path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2 4.2 2 2 0 0 1 4 2h3a2 2 0 0 1 2 1.7c.1 1 .4 1.9.7 2.8a2 2 0 0 1-.5 2.1L8 9.8a16 16 0 0 0 6 6l1.2-1.2a2 2 0 0 1 2.1-.5c.9.3 1.8.6 2.8.7a2 2 0 0 1 1.7 2z"/>;
const I_msg = <path d="M21 11.5a8.4 8.4 0 0 1-9 8.4 8.4 8.4 0 0 1-3.8-.8L3 21l1.9-5.2A8.4 8.4 0 0 1 12 3a8.4 8.4 0 0 1 9 8.5z"/>;
const I_bed = <path d="M3 18v-6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v6M3 14h18M7 10V8a2 2 0 0 1 2-2h2v4"/>;
const I_pin = <><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0z"/><circle cx="12" cy="10" r="3"/></>;

function QRm({ size=120 }) {
  const bits=[1,1,1,0,1,0,1,1,1, 1,0,1,0,0,1,1,0,1, 1,1,1,0,1,0,1,1,1, 0,0,0,1,0,1,0,0,0, 1,0,1,0,1,0,1,1,0, 0,1,0,1,0,0,0,1,1, 1,1,1,0,0,1,1,0,1, 1,0,1,1,0,0,0,1,0, 1,1,1,0,1,1,1,0,1];
  return <div style={{ width:size, height:size, background:"#fff", borderRadius:14, padding:size*0.1, display:"grid", gridTemplateColumns:"repeat(9,1fr)", gridTemplateRows:"repeat(9,1fr)", gap:size*0.012, boxShadow:"0 4px 16px rgba(0,0,0,.12)" }}>
    {bits.map((b,i)=><span key={i} style={{ background:b?"#0b0d12":"transparent", borderRadius:1 }}/>)}
  </div>;
}

/* ---------- A · Landing (dark hero) ---------- */
function Landing() {
  return <div className="mob">
    <div style={{ position:"relative" }}>
      <StatusBar dark/>
      <div className="mob-nav">
        <button className="nb"><MI d={I_back}/></button>
        <div style={{ display:"flex", gap:8 }}><button className="nb"><MI d={I_share} size={17}/></button><button className="nb"><MI d={I_heart} size={18}/></button></div>
      </div>
    </div>
    <div className="mob-scroll">
      <div className="mob-hero" style={{ marginTop:-94 }}>
        <div className="ph" data-label="property photo" style={{ height:340, background:"linear-gradient(160deg,#2b3445,#11151d)" }}></div>
        <div className="grad"></div>
        <span className="count">1 / 24</span>
        <div className="dots"><span className="on"></span><span></span><span></span><span></span></div>
      </div>
      <div className="mob-body">
        <div style={{ display:"flex", alignItems:"center", gap:8, marginBottom:8 }}>
          <span className="badge badge-green" style={{ fontSize:11 }}><span className="dot"></span>For Sale</span>
          <span className="badge badge-gray" style={{ fontSize:11 }}>Townhouse</span>
        </div>
        <div className="mob-price">$1,250,000</div>
        <div className="mob-addr">124 Maple Ave</div>
        <div className="mob-area">Bushwick, Brooklyn NY 11221</div>
        <div className="mob-specs">
          <div><div className="n">3</div><div className="l">Beds</div></div>
          <div><div className="n">2</div><div className="l">Baths</div></div>
          <div><div className="n">1,840</div><div className="l">Sq ft</div></div>
          <div><div className="n">1920</div><div className="l">Built</div></div>
        </div>
        <div className="mob-chips">
          {["Private garden","Renovated kitchen","Original details","2-car parking","Near L train"].map(c=><span className="mob-chip" key={c}>{c}</span>)}
        </div>
        <div className="mob-sec-t">About this home</div>
        <div className="mob-desc">Sun-filled three-bedroom townhouse on a quiet Bushwick block. A chef's kitchen opens to a landscaped private garden — rare for the neighborhood…</div>
      </div>
      <div style={{ height:96 }}></div>
    </div>
    <div className="mob-cta">
      <button className="mob-icon-btn"><MI d={I_msg}/></button>
      <button className="btn btn-secondary"><MI d={I_phone} size={17}/>Call agent</button>
      <button className="btn btn-primary">Schedule viewing</button>
      <div className="home-ind"></div>
    </div>
  </div>;
}

/* ---------- A2 · Landing scrolled (map + agent + browse) ---------- */
function LandingScroll() {
  return <div className="mob">
    <StatusBar/>
    <div style={{ display:"flex", alignItems:"center", gap:12, padding:"4px 16px 12px", borderBottom:"1px solid var(--line)" }}>
      <button className="mob-icon-btn" style={{ width:38, height:38, borderRadius:10 }}><MI d={I_back}/></button>
      <div style={{ flex:1 }}><div style={{ fontSize:15, fontWeight:700 }}>$1,250,000</div><div style={{ fontSize:12, color:"var(--slate-400)" }}>124 Maple Ave</div></div>
      <button className="mob-icon-btn" style={{ width:38, height:38, borderRadius:10 }}><MI d={I_heart} size={18}/></button>
    </div>
    <div className="mob-scroll">
      <div className="mob-body" style={{ paddingTop:6 }}>
        <div className="mob-sec-t" style={{ marginTop:14 }}>Location</div>
        <div className="ph" data-label="map" style={{ height:150, borderRadius:14, position:"relative" }}>
          <span style={{ position:"absolute", top:"42%", left:"50%", transform:"translate(-50%,-50%)", color:"var(--blue)" }}><MI d={I_pin} size={30} fill="var(--blue)"/></span>
        </div>
        <div className="mob-sec-t">Listed by</div>
        <div className="mob-agent">
          <div className="av" style={{ background:"linear-gradient(135deg,#2f6bff,#0fb5a6)" }}></div>
          <div style={{ flex:1 }}><div style={{ fontSize:15, fontWeight:650 }}>Dev Patel</div><div style={{ fontSize:12.5, color:"var(--slate-400)" }}>Vantage Realty · Lic #10401</div></div>
          <button className="mob-icon-btn" style={{ width:40, height:40, borderRadius:11 }}><MI d={I_phone} size={17}/></button>
        </div>
        <div className="mob-sec-t">More in Bushwick</div>
        {[["$985,000","412 Knickerbocker Ave","2 bd · 1 ba"],["$1.4M","88 Troutman St","3 bd · 2 ba"]].map((m,i)=>(
          <div className="mini-listing" key={i}>
            <div className="ph" data-label=""></div>
            <div style={{ flex:1, paddingTop:4 }}><div style={{ fontSize:16, fontWeight:700, letterSpacing:"-.02em" }}>{m[0]}</div><div style={{ fontSize:13, color:"var(--ink-800)", marginTop:2 }}>{m[1]}</div><div style={{ fontSize:12, color:"var(--slate-400)" }}>{m[2]}</div></div>
          </div>
        ))}
      </div>
      <div style={{ height:96 }}></div>
    </div>
    <div className="mob-cta">
      <button className="btn btn-primary" style={{ flex:1 }}>Schedule a viewing</button>
      <div className="home-ind"></div>
    </div>
  </div>;
}

/* ---------- B · Gallery ---------- */
function Gallery() {
  return <div className="mob">
    <StatusBar/>
    <div style={{ display:"flex", alignItems:"center", gap:12, padding:"4px 16px 12px" }}>
      <button className="mob-icon-btn" style={{ width:38, height:38, borderRadius:10 }}><MI d={I_back}/></button>
      <div style={{ flex:1, fontSize:15, fontWeight:650, textAlign:"center" }}>All photos · 24</div>
      <button className="mob-icon-btn" style={{ width:38, height:38, borderRadius:10 }}><MI d={I_share} size={16}/></button>
    </div>
    <div className="mob-scroll">
      <div className="mob-gal" style={{ padding:"0 3px" }}>
        <div className="ph" data-label="living room"></div>
        {["kitchen","garden","bedroom","bath","facade","detail"].map(l=><div className="ph" data-label={l} key={l}></div>)}
      </div>
    </div>
    <div className="mob-cta">
      <button className="btn btn-primary" style={{ flex:1 }}>Book a viewing</button>
      <div className="home-ind"></div>
    </div>
  </div>;
}

/* ---------- C · Schedule viewing ---------- */
function Schedule() {
  const days=["S","M","T","W","T","F","S"];
  const today=7;
  return <div className="mob">
    <StatusBar/>
    <div style={{ display:"flex", alignItems:"center", gap:12, padding:"4px 16px 12px" }}>
      <button className="mob-icon-btn" style={{ width:38, height:38, borderRadius:10 }}><MI d={I_back}/></button>
      <div style={{ flex:1, fontSize:16, fontWeight:700, textAlign:"center" }}>Schedule a viewing</div>
      <div style={{ width:38 }}></div>
    </div>
    <div className="mob-scroll">
      <div className="mob-body" style={{ paddingTop:8 }}>
        <div style={{ display:"flex", gap:11, alignItems:"center", padding:"12px 14px", background:"var(--surface-2)", borderRadius:13, marginBottom:6 }}>
          <div className="ph" data-label="" style={{ width:54, height:42, borderRadius:9 }}></div>
          <div><div style={{ fontSize:14, fontWeight:700 }}>$1,250,000</div><div style={{ fontSize:12.5, color:"var(--slate-400)" }}>124 Maple Ave, Bushwick</div></div>
        </div>
        <div className="mob-sec-t">June 2026</div>
        <div className="cal" style={{ marginBottom:6 }}>{days.map((d,i)=><div className="dow" key={i}>{d}</div>)}</div>
        <div className="cal">
          {Array.from({length:30}).map((_,i)=>{ const day=i+1; return <div key={i} className={"d"+(day===today?" on":"")+(day<3?" muted":"")}>{day}</div>; })}
        </div>
        <div className="mob-sec-t">Available times · Sat Jun 7</div>
        <div style={{ display:"grid", gridTemplateColumns:"repeat(3,1fr)", gap:9 }}>
          <div className="timeslot">10:00</div><div className="timeslot on">2:00 PM</div><div className="timeslot">3:30</div>
          <div className="timeslot">4:15</div><div className="timeslot">5:00</div><div className="timeslot" style={{ color:"var(--slate-300)" }}>Booked</div>
        </div>
      </div>
      <div style={{ height:96 }}></div>
    </div>
    <div className="mob-cta">
      <button className="btn btn-primary" style={{ flex:1 }}>Confirm · Sat 2:00 PM</button>
      <div className="home-ind"></div>
    </div>
  </div>;
}

/* ---------- B2 · Editorial light landing ---------- */
function LandingEditorial() {
  return <div className="mob" style={{ background:"#faf9f7" }}>
    <StatusBar/>
    <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"4px 16px 8px" }}>
      <button className="mob-icon-btn" style={{ width:38, height:38, borderRadius:10, border:"none", background:"transparent" }}><MI d={I_back}/></button>
      <span className="logo" style={{ transform:"scale(.85)" }}><span className="logo-mark"><svg viewBox="0 0 24 24" fill="none"><path d="M8 6.5v11l9-5.5-9-5.5z" fill="#fff"/></svg></span><span className="logo-word">Re<b>Play</b></span></span>
      <button className="mob-icon-btn" style={{ width:38, height:38, borderRadius:10, border:"none", background:"transparent" }}><MI d={I_heart} size={18}/></button>
    </div>
    <div className="mob-scroll">
      <div style={{ padding:"6px 18px 0", textAlign:"center" }}>
        <div className="t-label" style={{ color:"var(--blue)", justifyContent:"center", display:"block" }}>For Sale · Townhouse</div>
        <div style={{ fontSize:34, fontWeight:800, letterSpacing:"-.03em", marginTop:8 }}>$1,250,000</div>
        <div style={{ fontSize:14.5, color:"var(--slate-500)", marginTop:4 }}>124 Maple Ave · Bushwick</div>
      </div>
      <div className="ph" data-label="property photo" style={{ height:230, margin:"18px 0" }}></div>
      <div style={{ padding:"0 18px" }}>
        <div style={{ display:"flex", justifyContent:"space-around", textAlign:"center", paddingBottom:18, borderBottom:"1px solid var(--line)" }}>
          <div><div style={{ fontSize:19, fontWeight:700 }}>3</div><div style={{ fontSize:12, color:"var(--slate-400)" }}>Beds</div></div>
          <div><div style={{ fontSize:19, fontWeight:700 }}>2</div><div style={{ fontSize:12, color:"var(--slate-400)" }}>Baths</div></div>
          <div><div style={{ fontSize:19, fontWeight:700 }}>1,840</div><div style={{ fontSize:12, color:"var(--slate-400)" }}>Sq ft</div></div>
        </div>
        <div className="mob-desc" style={{ marginTop:18, textAlign:"center", fontSize:14.5, color:"var(--ink-800)" }}>A rare sun-filled townhouse with a private landscaped garden, moments from the L train.</div>
      </div>
      <div style={{ height:96 }}></div>
    </div>
    <div className="mob-cta" style={{ background:"rgba(250,249,247,.92)" }}>
      <button className="btn btn-primary" style={{ flex:1 }}>Book a private viewing</button>
      <div className="home-ind"></div>
    </div>
  </div>;
}

Object.assign(window, { Landing, LandingScroll, Gallery, Schedule, LandingEditorial, QRm });
