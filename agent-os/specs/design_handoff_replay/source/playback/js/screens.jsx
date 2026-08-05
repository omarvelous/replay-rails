/* RePlay — Screen Playback designs (each is a self-contained signage frame) */

const QRBITS = [1,1,1,0,1,1,1, 1,0,1,0,1,0,1, 1,1,1,0,1,1,1, 0,0,0,1,0,0,0, 1,1,0,1,0,1,1, 0,0,1,0,1,0,1, 1,1,1,0,1,1,0];
function QR({ size = "16cqh", style }) {
  return <div className="pb-qr" style={{ width: size, height: size, ...style }}>
    {QRBITS.map((b,i)=><span key={i} className={b?"":"o"} />)}
  </div>;
}
function Mark() { return <span className="pb-mark"><svg viewBox="0 0 24 24" fill="none"><path d="M8 6.5v11l9-5.5-9-5.5z" fill="#fff"/></svg></span>; }

/* ============ HOOK SCREENS ============ */
function HookKinetic() {
  return <div className="pb" style={{ background:"radial-gradient(120% 120% at 80% -10%, #16203a, #0b0d12 60%)" }}>
    <div style={{ position:"absolute", top:"7cqh", left:"6cqw", display:"flex", alignItems:"center", gap:"1.5cqw" }} className="pb-fade">
      <Mark/><span style={{ fontSize:"3cqh", fontWeight:700, letterSpacing:"-.02em" }}>Vantage Realty</span>
    </div>
    <div style={{ position:"absolute", top:"50%", left:"6cqw", right:"6cqw", transform:"translateY(-50%)" }}>
      <div className="pb-eyebrow pb-rise" style={{ color:"#5b9bff", marginBottom:"2.5cqh" }}>Now showing</div>
      <div style={{ fontSize:"10cqh", fontWeight:800, lineHeight:.98, letterSpacing:"-.03em" }}>
        <div className="pb-rise d1">Homes for Sale</div>
        <div className="pb-rise d2">in <span style={{ background:"linear-gradient(120deg,#5b9bff,#0fb5a6)", WebkitBackgroundClip:"text", backgroundClip:"text", color:"transparent" }}>Bushwick</span></div>
      </div>
    </div>
    <div style={{ position:"absolute", bottom:"7cqh", left:"6cqw", display:"flex", alignItems:"center", gap:"2cqw" }} className="pb-rise d3">
      <QR size="13cqh"/><div style={{ fontSize:"3cqh", fontWeight:600, color:"rgba(255,255,255,.8)" }}>Scan to browse<br/>every listing →</div>
    </div>
  </div>;
}
function HookPhoto() {
  return <div className="pb">
    <div className="pb-photo pb-ken" data-label="neighborhood photo"></div>
    <div className="pb-scrim-b"></div>
    <div style={{ position:"absolute", top:"7cqh", left:"6cqw" }} className="pb-brandrow pb-fade"><Mark/><span style={{ fontSize:"2.8cqh", fontWeight:700 }}>Vantage Realty</span></div>
    <div style={{ position:"absolute", top:"7cqh", right:"6cqw" }} className="pb-fade">
      <span className="pill-spec" style={{ background:"#2f6bff", border:"none" }}>● 6 new this week</span>
    </div>
    <div style={{ position:"absolute", bottom:"7cqh", left:"6cqw", right:"6cqw" }}>
      <div className="pb-eyebrow pb-rise" style={{ color:"#7aa2ff", marginBottom:"2cqh" }}>Just listed</div>
      <div className="pb-rise d1" style={{ fontSize:"8.5cqh", fontWeight:800, lineHeight:1, letterSpacing:"-.03em", maxWidth:"82%" }}>New Listings This Week</div>
    </div>
  </div>;
}
function HookMinimal() {
  return <div className="pb" style={{ background:"#f4f5f7", color:"#0b0d12" }}>
    <div style={{ position:"absolute", top:"7cqh", left:"50%", transform:"translateX(-50%)" }} className="pb-brandrow pb-fade"><Mark/><span style={{ fontSize:"2.6cqh", fontWeight:700 }}>Vantage Realty</span></div>
    <div style={{ position:"absolute", inset:0, display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", textAlign:"center", padding:"0 8cqw" }}>
      <div className="pb-eyebrow pb-rise" style={{ color:"var(--blue)", marginBottom:"3cqh" }}>Open house weekend</div>
      <div className="pb-rise d1" style={{ fontSize:"9cqh", fontWeight:800, lineHeight:.98, letterSpacing:"-.035em" }}>5 homes.<br/>One afternoon.</div>
      <div className="pb-rise d2" style={{ fontSize:"3cqh", color:"#5b6470", marginTop:"3.5cqh" }}>Saturday · 12–4PM · Bushwick</div>
    </div>
    <div style={{ position:"absolute", bottom:"6cqh", left:"50%", transform:"translateX(-50%)", display:"flex", alignItems:"center", gap:"1.5cqw", fontSize:"2.4cqh", fontWeight:600, color:"#5b6470" }} className="pb-rise d3">
      <span style={{ width:"3cqh", height:"3cqh", borderRadius:4, background:"#0b0d12", display:"inline-block" }}></span>Scan for the map
    </div>
  </div>;
}

/* ============ HERO LISTING ============ */
function HeroCinematic() {
  return <div className="pb">
    <div className="pb-photo pb-ken" data-label="hero property photo"></div>
    <div className="pb-scrim-b"></div>
    <div style={{ position:"absolute", top:"6cqh", left:"6cqw" }} className="pb-brandrow pb-fade"><Mark/><span style={{ fontSize:"2.6cqh", fontWeight:700 }}>Vantage Realty</span></div>
    <span style={{ position:"absolute", top:"6cqh", right:"6cqw" }} className="pill-spec pb-fade"><span style={{color:"#5b9bff"}}>●</span> For Sale</span>
    <div style={{ position:"absolute", bottom:"6cqh", left:"6cqw", right:"6cqw", display:"flex", alignItems:"flex-end", justifyContent:"space-between", gap:"3cqw" }}>
      <div style={{ flex:1 }}>
        <div className="pb-eyebrow pb-rise" style={{ color:"#7aa2ff", marginBottom:"1.5cqh" }}>Just listed · Townhouse</div>
        <div className="pb-rise d1" style={{ fontSize:"5cqh", fontWeight:600, letterSpacing:"-.01em", marginBottom:"1.5cqh" }}>124 Maple Ave, Bushwick</div>
        <div className="pb-rise d2" style={{ fontSize:"9cqh", fontWeight:800, letterSpacing:"-.03em", lineHeight:1 }}>$1,250,000</div>
        <div className="pb-rise d3" style={{ display:"flex", gap:"1.5cqw", marginTop:"2.5cqh" }}>
          <span className="pill-spec">3 Beds</span><span className="pill-spec">2 Baths</span><span className="pill-spec">1,840 sqft</span>
        </div>
      </div>
      <div className="pb-rise d3" style={{ textAlign:"center" }}><QR size="18cqh"/><div style={{ fontSize:"2.2cqh", marginTop:"1.2cqh", color:"rgba(255,255,255,.8)" }}>Scan for tour</div></div>
    </div>
  </div>;
}
function HeroEditorial() {
  return <div className="pb" style={{ background:"#fff", color:"#0b0d12", display:"flex" }}>
    <div style={{ width:"56%", position:"relative" }}><div className="pb-photo pb-ken" data-label="property photo"></div></div>
    <div style={{ flex:1, padding:"7cqh 4cqw", display:"flex", flexDirection:"column", justifyContent:"center" }}>
      <div className="pb-brandrow pb-fade" style={{ marginBottom:"4cqh" }}><Mark/><span style={{ fontSize:"2.4cqh", fontWeight:700 }}>Vantage Realty</span></div>
      <div className="pb-eyebrow pb-rise" style={{ color:"var(--blue)", marginBottom:"2cqh" }}>For Sale</div>
      <div className="pb-rise d1" style={{ fontSize:"7cqh", fontWeight:800, letterSpacing:"-.03em", lineHeight:1 }}>$1,250,000</div>
      <div className="pb-rise d2" style={{ fontSize:"3cqh", color:"#5b6470", marginTop:"1.5cqh" }}>124 Maple Ave, Bushwick</div>
      <div className="pb-rise d2" style={{ display:"flex", gap:"4cqw", marginTop:"4cqh", paddingTop:"3cqh", borderTop:"1px solid #e6e8ec" }}>
        <Spec n="3" l="Beds"/><Spec n="2" l="Baths"/><Spec n="1,840" l="Sq ft"/>
      </div>
      <div className="pb-rise d3" style={{ display:"flex", alignItems:"center", gap:"2cqw", marginTop:"4cqh" }}>
        <QR size="14cqh" style={{ boxShadow:"0 2px 10px rgba(0,0,0,.1)" }}/><div style={{ fontSize:"2.6cqh", fontWeight:600, color:"#5b6470" }}>Scan to book<br/>a private viewing</div>
      </div>
    </div>
  </div>;
}
function Spec({ n, l }) { return <div><div style={{ fontSize:"4cqh", fontWeight:700, letterSpacing:"-.02em" }}>{n}</div><div style={{ fontSize:"2cqh", color:"#8a929e" }}>{l}</div></div>; }

function HeroLuxury() {
  return <div className="pb" style={{ display:"flex" }}>
    <div style={{ width:"42%", background:"linear-gradient(165deg,#11151d,#1a2236)", padding:"7cqh 3cqw", display:"flex", flexDirection:"column", justifyContent:"space-between", position:"relative" }}>
      <div className="pb-brandrow pb-fade"><Mark/><span style={{ fontSize:"2.4cqh", fontWeight:700 }}>Vantage</span></div>
      <div>
        <div className="pb-eyebrow pb-rise" style={{ color:"#b79b73", marginBottom:"2cqh" }}>Private Collection</div>
        <div className="pb-rise d1" style={{ fontSize:"8cqh", fontWeight:800, letterSpacing:"-.03em", lineHeight:.98 }}>$8.95M</div>
        <div className="pb-rise d2" style={{ fontSize:"2.8cqh", color:"rgba(255,255,255,.7)", marginTop:"1.5cqh" }}>20 Hudson Yards · 72A</div>
        <div className="pb-rise d2" style={{ display:"flex", gap:"3cqw", marginTop:"3cqh", color:"rgba(255,255,255,.85)", fontSize:"2.4cqh", fontWeight:600 }}>
          <span>4 BD</span><span>4.5 BA</span><span>3,600 SF</span>
        </div>
      </div>
      <div className="pb-rise d3" style={{ display:"flex", alignItems:"center", gap:"1.5cqw" }}><QR size="11cqh"/><div style={{ fontSize:"2cqh", color:"rgba(255,255,255,.65)" }}>Scan for the<br/>full gallery</div></div>
    </div>
    <div style={{ flex:1, position:"relative" }}><div className="pb-photo pb-ken" data-label="luxury interior"></div></div>
  </div>;
}

/* ============ BROWSE GRID ============ */
function BrowseGrid() {
  const items = [["$985K","412 Knickerbocker","2bd · 1ba"],["$1.25M","124 Maple Ave","3bd · 2ba"],["$2.35M","19 Greenpoint Ave","3bd · 2.5ba"]];
  return <div className="pb" style={{ padding:"6cqh 4cqw", display:"flex", flexDirection:"column" }}>
    <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:"4cqh" }} className="pb-fade">
      <div><div className="pb-eyebrow" style={{ color:"#5b9bff", marginBottom:"1cqh" }}>This week in Bushwick</div>
        <div style={{ fontSize:"6cqh", fontWeight:800, letterSpacing:"-.03em" }}>6 New Listings</div></div>
      <div className="pb-brandrow"><Mark/></div>
    </div>
    <div style={{ display:"grid", gridTemplateColumns:"repeat(3,1fr)", gap:"2.5cqw", flex:1 }}>
      {items.map((it,i)=>(
        <div key={i} className={"pb-rise d"+(i+1)} style={{ borderRadius:"2cqh", overflow:"hidden", background:"#14171f", display:"flex", flexDirection:"column" }}>
          <div className="pb-photo" data-label="" style={{ position:"relative", flex:1 }}></div>
          <div style={{ padding:"2.4cqh 2cqw" }}>
            <div style={{ fontSize:"4cqh", fontWeight:800, letterSpacing:"-.02em" }}>{it[0]}</div>
            <div style={{ fontSize:"2.4cqh", color:"rgba(255,255,255,.85)", marginTop:".5cqh" }}>{it[1]}</div>
            <div style={{ fontSize:"2cqh", color:"rgba(255,255,255,.5)" }}>{it[2]}</div>
          </div>
        </div>
      ))}
    </div>
    <div style={{ display:"flex", alignItems:"center", justifyContent:"center", gap:"1.5cqw", marginTop:"3.5cqh", fontSize:"2.6cqh", fontWeight:600, color:"rgba(255,255,255,.8)" }} className="pb-rise d4">
      <span style={{ width:"3cqh", height:"3cqh", borderRadius:4, background:"#fff", display:"inline-block" }}></span>Scan any code to see more →
    </div>
  </div>;
}

/* ============ OPEN HOUSE ============ */
function OpenHouse() {
  return <div className="pb" style={{ background:"linear-gradient(135deg,#1f54e0,#0fb5a6)" }}>
    <div style={{ position:"absolute", top:"7cqh", left:"6cqw" }} className="pb-brandrow pb-fade"><span className="pb-mark" style={{ background:"rgba(255,255,255,.2)" }}><svg viewBox="0 0 24 24" fill="none"><path d="M8 6.5v11l9-5.5-9-5.5z" fill="#fff"/></svg></span><span style={{ fontSize:"2.8cqh", fontWeight:700 }}>Vantage Realty</span></div>
    <div style={{ position:"absolute", top:"50%", left:"6cqw", transform:"translateY(-50%)", maxWidth:"60%" }}>
      <div className="pb-eyebrow pb-rise" style={{ marginBottom:"2cqh", opacity:.85 }}>You're invited</div>
      <div className="pb-rise d1" style={{ fontSize:"11cqh", fontWeight:800, lineHeight:.9, letterSpacing:"-.035em" }}>Open<br/>House</div>
      <div className="pb-rise d2" style={{ fontSize:"4cqh", fontWeight:700, marginTop:"3cqh" }}>Saturday, June 7 · 2–4PM</div>
      <div className="pb-rise d2" style={{ fontSize:"3cqh", opacity:.85, marginTop:"1cqh" }}>124 Maple Ave, Bushwick</div>
    </div>
    <div style={{ position:"absolute", bottom:"7cqh", right:"6cqw", textAlign:"center" }} className="pb-rise d3">
      <div style={{ background:"#fff", borderRadius:"3cqh", padding:"2.5cqh", boxShadow:"0 8px 30px rgba(0,0,0,.2)" }}><QR size="16cqh"/></div>
      <div style={{ fontSize:"2.4cqh", fontWeight:600, marginTop:"1.5cqh" }}>Scan to RSVP</div>
    </div>
  </div>;
}

/* ============ BRANDING ============ */
function BrandAwards() {
  return <div className="pb" style={{ background:"radial-gradient(110% 110% at 50% 0%, #18203a, #0b0d12 65%)", display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", textAlign:"center", padding:"0 8cqw" }}>
    <span className="pb-mark pb-rise" style={{ width:"10cqh", height:"10cqh", borderRadius:"2.4cqh", marginBottom:"4cqh" }}><svg viewBox="0 0 24 24" fill="none" style={{ width:"5.5cqh", height:"5.5cqh" }}><path d="M8 6.5v11l9-5.5-9-5.5z" fill="#fff"/></svg></span>
    <div className="pb-rise d1" style={{ fontSize:"4.5cqh", fontWeight:600, letterSpacing:"-.01em" }}>Vantage Realty</div>
    <div className="pb-rise d2" style={{ fontSize:"7cqh", fontWeight:800, letterSpacing:"-.03em", lineHeight:1, marginTop:"1.5cqh", maxWidth:"16ch" }}>Brooklyn's <span style={{ color:"#5b9bff" }}>#1</span> boutique brokerage</div>
    <div className="pb-rise d3" style={{ display:"flex", gap:"6cqw", marginTop:"5cqh" }}>
      <Stat n="$2.4B" l="Sold in 2025"/><Stat n="1,200+" l="Families moved"/><Stat n="4.9★" l="Client rating"/>
    </div>
  </div>;
}
function Stat({ n, l }) { return <div><div style={{ fontSize:"5cqh", fontWeight:800, letterSpacing:"-.02em", background:"linear-gradient(120deg,#5b9bff,#0fb5a6)", WebkitBackgroundClip:"text", backgroundClip:"text", color:"transparent" }}>{n}</div><div style={{ fontSize:"2cqh", color:"rgba(255,255,255,.6)", marginTop:".5cqh" }}>{l}</div></div>; }

function BrandTestimonial() {
  return <div className="pb" style={{ display:"flex" }}>
    <div style={{ width:"45%", position:"relative" }}><div className="pb-photo pb-ken" data-label="agent / team photo"></div></div>
    <div style={{ flex:1, background:"#0b0d12", padding:"8cqh 4cqw", display:"flex", flexDirection:"column", justifyContent:"center" }}>
      <div style={{ fontSize:"9cqh", fontWeight:800, color:"#2f6bff", lineHeight:.5, height:"4cqh" }} className="pb-fade">“</div>
      <div className="pb-rise d1" style={{ fontSize:"4cqh", fontWeight:600, lineHeight:1.25, letterSpacing:"-.015em" }}>They sold our brownstone in 9 days, over asking. The whole team is exceptional.</div>
      <div className="pb-rise d2" style={{ marginTop:"4cqh", fontSize:"2.6cqh" }}><b>The Okonkwo Family</b><div style={{ color:"rgba(255,255,255,.55)", fontSize:"2.2cqh", marginTop:".5cqh" }}>Sold · Park Slope</div></div>
      <div className="pb-rise d3" style={{ marginTop:"4cqh" }}><span className="pb-brandrow"><Mark/><span style={{ fontSize:"2.4cqh", fontWeight:700 }}>Vantage Realty</span></span></div>
    </div>
  </div>;
}

/* ============ RECRUITING ============ */
function Recruiting() {
  return <div className="pb" style={{ background:"linear-gradient(155deg,#0b0d12 40%,#13243f)", padding:"7cqh 6cqw", display:"flex", flexDirection:"column", justifyContent:"center" }}>
    <div style={{ position:"absolute", top:"7cqh", left:"6cqw" }} className="pb-brandrow pb-fade"><Mark/><span style={{ fontSize:"2.6cqh", fontWeight:700 }}>Vantage Realty</span></div>
    <div className="pb-eyebrow pb-rise" style={{ color:"#0fb5a6", marginBottom:"2.5cqh" }}>We're hiring agents</div>
    <div className="pb-rise d1" style={{ fontSize:"8cqh", fontWeight:800, letterSpacing:"-.03em", lineHeight:1, maxWidth:"15ch" }}>Build your real-estate career here.</div>
    <div className="pb-rise d2" style={{ display:"flex", gap:"2.5cqw", marginTop:"4cqh" }}>
      {[["85%","commission split"],["Full","marketing support"],["RePlay","signage included"]].map((b,i)=>(
        <div key={i} style={{ background:"rgba(255,255,255,.06)", border:"1px solid rgba(255,255,255,.1)", borderRadius:"1.6cqh", padding:"2.4cqh 2.4cqw", flex:1 }}>
          <div style={{ fontSize:"4cqh", fontWeight:800, color:"#5b9bff" }}>{b[0]}</div><div style={{ fontSize:"2cqh", color:"rgba(255,255,255,.65)", marginTop:".5cqh" }}>{b[1]}</div>
        </div>
      ))}
    </div>
    <div className="pb-rise d3" style={{ display:"flex", alignItems:"center", gap:"2cqw", marginTop:"5cqh" }}>
      <QR size="13cqh"/><div style={{ fontSize:"3cqh", fontWeight:600 }}>Scan to apply<div style={{ fontSize:"2.2cqh", color:"rgba(255,255,255,.6)", fontWeight:400, marginTop:".5cqh" }}>Confidential · 2-minute form</div></div>
    </div>
  </div>;
}

/* ============ CTA ============ */
function CtaGiant() {
  return <div className="pb" style={{ background:"radial-gradient(120% 120% at 50% 120%, #16203a, #0b0d12 60%)", display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", textAlign:"center" }}>
    <div className="pb-rise" style={{ background:"#fff", borderRadius:"4cqh", padding:"3.5cqh", boxShadow:"0 12px 50px rgba(47,107,255,.3)" }}><QR size="34cqh"/></div>
    <div className="pb-rise d1" style={{ fontSize:"6cqh", fontWeight:800, letterSpacing:"-.03em", marginTop:"4cqh" }}>Scan for the full tour</div>
    <div className="pb-rise d2" style={{ fontSize:"3cqh", color:"rgba(255,255,255,.6)", marginTop:"1.5cqh" }}>Photos · floor plans · book a viewing instantly</div>
  </div>;
}
function CtaSplit() {
  return <div className="pb" style={{ background:"linear-gradient(120deg,#2f6bff,#0fb5a6)", display:"flex", alignItems:"center", padding:"0 7cqw", justifyContent:"space-between" }}>
    <div style={{ maxWidth:"58%" }}>
      <div className="pb-brandrow pb-fade" style={{ marginBottom:"4cqh" }}><span className="pb-mark" style={{ background:"rgba(255,255,255,.2)" }}><svg viewBox="0 0 24 24" fill="none"><path d="M8 6.5v11l9-5.5-9-5.5z" fill="#fff"/></svg></span><span style={{ fontSize:"2.6cqh", fontWeight:700 }}>Vantage Realty</span></div>
      <div className="pb-rise d1" style={{ fontSize:"8cqh", fontWeight:800, letterSpacing:"-.035em", lineHeight:.98 }}>Love what<br/>you see?</div>
      <div className="pb-rise d2" style={{ fontSize:"3.4cqh", opacity:.9, marginTop:"2.5cqh", fontWeight:500 }}>Scan the code to talk to an agent today — no calls, no pressure.</div>
    </div>
    <div className="pb-rise d2" style={{ background:"#fff", borderRadius:"3.5cqh", padding:"3cqh", boxShadow:"0 12px 40px rgba(0,0,0,.2)" }}><QR size="24cqh"/></div>
  </div>;
}

/* ============ PORTRAIT WINDOW VARIANTS ============ */
function HeroPortrait() {
  return <div className="pb">
    <div className="pb-photo pb-ken" data-label="property photo"></div>
    <div className="pb-scrim-b"></div>
    <div style={{ position:"absolute", top:"4cqh", left:"7cqw", right:"7cqw", display:"flex", alignItems:"center", justifyContent:"space-between" }} className="pb-fade">
      <span className="pb-brandrow"><Mark/><span style={{ fontSize:"2.4cqh", fontWeight:700 }}>Vantage</span></span>
      <span className="pill-spec" style={{ fontSize:"1.9cqh" }}><span style={{color:"#5b9bff"}}>●</span> For Sale</span>
    </div>
    <div style={{ position:"absolute", bottom:"4cqh", left:"7cqw", right:"7cqw" }}>
      <div className="pb-eyebrow pb-rise" style={{ color:"#7aa2ff", marginBottom:"1.5cqh", fontSize:"1.8cqh" }}>Just listed · Townhouse</div>
      <div className="pb-rise d1" style={{ fontSize:"6cqh", fontWeight:800, letterSpacing:"-.03em", lineHeight:1 }}>$1,250,000</div>
      <div className="pb-rise d2" style={{ fontSize:"2.6cqh", fontWeight:500, marginTop:"1cqh", opacity:.85 }}>124 Maple Ave, Bushwick</div>
      <div className="pb-rise d2" style={{ display:"flex", gap:"1.4cqw", marginTop:"2cqh", flexWrap:"wrap" }}>
        <span className="pill-spec" style={{ fontSize:"1.9cqh" }}>3 Beds</span><span className="pill-spec" style={{ fontSize:"1.9cqh" }}>2 Baths</span><span className="pill-spec" style={{ fontSize:"1.9cqh" }}>1,840 sqft</span>
      </div>
      <div className="pb-rise d3" style={{ display:"flex", alignItems:"center", gap:"3cqw", marginTop:"3cqh", paddingTop:"3cqh", borderTop:"1px solid rgba(255,255,255,.15)" }}>
        <QR size="9cqh"/><div style={{ fontSize:"2.2cqh", fontWeight:600 }}>Scan for the full tour →</div>
      </div>
    </div>
  </div>;
}
function CtaPortrait() {
  return <div className="pb" style={{ background:"radial-gradient(120% 90% at 50% 110%, #16203a, #0b0d12 60%)", display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", textAlign:"center", padding:"0 8cqw" }}>
    <span className="pb-brandrow pb-fade" style={{ marginBottom:"5cqh" }}><Mark/><span style={{ fontSize:"2.4cqh", fontWeight:700 }}>Vantage Realty</span></span>
    <div className="pb-rise" style={{ background:"#fff", borderRadius:"3.5cqh", padding:"3.5cqh", boxShadow:"0 12px 50px rgba(47,107,255,.3)" }}><QR size="22cqh"/></div>
    <div className="pb-rise d1" style={{ fontSize:"4.4cqh", fontWeight:800, letterSpacing:"-.03em", marginTop:"4cqh", lineHeight:1.05 }}>Scan for the<br/>full tour</div>
    <div className="pb-rise d2" style={{ fontSize:"2.2cqh", color:"rgba(255,255,255,.6)", marginTop:"2cqh" }}>Photos · floor plans · book instantly</div>
  </div>;
}

Object.assign(window, { HookKinetic, HookPhoto, HookMinimal, HeroCinematic, HeroEditorial, HeroLuxury, BrowseGrid, OpenHouse, BrandAwards, BrandTestimonial, Recruiting, CtaGiant, CtaSplit, HeroPortrait, CtaPortrait });
