/* Ad Builder — Canva-like editor with live preview */
function Ads({ go }) {
  const [ad, setAd] = useState({
    headline: "Just Listed in Bushwick",
    sub: "Sun-filled 3-bedroom townhouse with private garden",
    cta: "Scan to book a viewing",
    price: "$1,250,000", specs: "3 bd · 2 ba · 1,840 sqft",
    layout: "hero", theme: "dark", listing: "l1",
  });
  const set = (k,v) => setAd(p=>({...p,[k]:v}));
  const themes = {
    dark: { bg:"linear-gradient(135deg,#0b0d12,#1c2230)", fg:"#fff", accent:"#5b9bff", sub:"rgba(255,255,255,.75)" },
    light:{ bg:"#f7f8fa", fg:"#0b0d12", accent:"#2f6bff", sub:"#5b6470" },
    brand:{ bg:"linear-gradient(135deg,#1f54e0,#0fb5a6)", fg:"#fff", accent:"#fff", sub:"rgba(255,255,255,.85)" },
  };

  return (
    <div className="builder">
      {/* builder topbar */}
      <div className="bld-bar">
        <div style={{ display:"flex", alignItems:"center", gap:12 }}>
          <button className="icon-btn-sm" onClick={()=>go("ads")} title="Back to ads"><Icon name="chevronR" size={16} style={{transform:"rotate(180deg)"}}/></button>
          <div><div style={{ fontSize:14, fontWeight:650 }}>124 Maple Ave — Hero</div><div style={{ fontSize:11.5, color:"var(--slate-400)" }}>Spring Open Houses · <span style={{color:"var(--amber)"}}>Draft</span></div></div>
        </div>
        <div style={{ display:"flex", gap:10 }}>
          <button className="btn btn-secondary btn-sm" title="Duplicate this ad"><Icon name="layers" size={15}/>Duplicate</button>
          <button className="btn btn-secondary btn-sm"><Icon name="eye" size={15}/>Preview</button>
          <button className="btn btn-primary btn-sm"><Icon name="upload" size={15}/>Publish ad</button>
        </div>
      </div>

      <div className="bld-body">
        {/* LEFT — layouts & elements */}
        <div className="bld-left">
          <div className="bld-sec-t">Start from a template</div>
          <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:8, marginBottom:20 }}>
            {[
              ["Just Listed", {layout:"hero", theme:"dark", headline:"Just Listed in Bushwick", cta:"Scan to book a viewing"}, "#2f6bff"],
              ["Open House", {layout:"minimal", theme:"brand", headline:"Open House Saturday", cta:"Scan to RSVP"}, "#0fb5a6"],
              ["Price Drop", {layout:"grid", theme:"dark", headline:"New Price — 124 Maple", cta:"Scan for details"}, "#e8990f"],
              ["Recruiting", {layout:"minimal", theme:"dark", headline:"We're hiring agents", cta:"Scan to apply"}, "#7c5cff"],
            ].map(([name, preset, c])=>(
              <button key={name} className="tpl-chip" onClick={()=>setAd(p=>({...p, ...preset}))}>
                <span className="tpl-thumb" style={{ background:`linear-gradient(135deg, ${c}, ${c}88)` }}><span className="tpl-bar"/></span>
                {name}
              </button>
            ))}
          </div>
          <div className="bld-sec-t">Layout</div>
          <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:8, marginBottom:20 }}>
            {[["hero","Hero"],["split","Split"],["minimal","Minimal"],["grid","Stat"]].map(([v,l])=>(
              <button key={v} className={"layout-chip"+(ad.layout===v?" on":"")} onClick={()=>set("layout",v)}>
                <div className="layout-thumb">{v==="hero"&&<><span style={{position:"absolute",left:6,bottom:6,width:"50%",height:7,background:"currentColor",borderRadius:2}}/><span style={{position:"absolute",left:6,bottom:16,width:"34%",height:4,background:"currentColor",opacity:.5,borderRadius:2}}/></>}
                  {v==="split"&&<><span style={{position:"absolute",left:0,top:0,bottom:0,width:"50%",background:"currentColor",opacity:.25}}/><span style={{position:"absolute",right:6,top:"40%",width:"34%",height:5,background:"currentColor",borderRadius:2}}/></>}
                  {v==="minimal"&&<span style={{position:"absolute",left:"25%",top:"42%",width:"50%",height:6,background:"currentColor",borderRadius:2}}/>}
                  {v==="grid"&&<><span style={{position:"absolute",left:6,top:6,right:6,height:"45%",background:"currentColor",opacity:.25,borderRadius:2}}/><span style={{position:"absolute",left:6,bottom:6,width:8,height:8,background:"currentColor",borderRadius:2}}/></>}
                </div>{l}</button>
            ))}
          </div>
          <div className="bld-sec-t">Theme</div>
          <div style={{ display:"flex", gap:8, marginBottom:20 }}>
            {Object.keys(themes).map(t=>(
              <button key={t} className={"theme-dot"+(ad.theme===t?" on":"")} onClick={()=>set("theme",t)} style={{ background:themes[t].bg }} title={t}/>
            ))}
          </div>
          <div className="bld-sec-t">Media</div>
          <div className="ph" data-label="property photo" style={{ height:90, borderRadius:9, marginBottom:8 }}/>
          <button className="btn btn-secondary btn-sm" style={{ width:"100%" }}><Icon name="upload" size={14}/>Replace media</button>
        </div>

        {/* CENTER — canvas */}
        <div className="bld-canvas-wrap">
          <div className="bld-canvas">
            <AdPreview ad={ad} theme={themes[ad.theme]}/>
          </div>
          <div className="bld-canvas-foot">
            <span className="badge badge-gray">16:9 · 1920×1080</span>
            <span style={{ fontSize:12, color:"var(--slate-400)" }}>Live preview — edits apply instantly</span>
          </div>
        </div>

        {/* RIGHT — properties */}
        <div className="bld-right">
          <div className="bld-sec-t">Content</div>
          <div className="field" style={{ marginBottom:12 }}><label>Headline</label><input className="input" value={ad.headline} onChange={e=>set("headline",e.target.value)}/></div>
          <div className="field" style={{ marginBottom:12 }}><label>Subheadline</label><textarea className="textarea" style={{ minHeight:60 }} value={ad.sub} onChange={e=>set("sub",e.target.value)}/></div>
          <div className="field" style={{ marginBottom:12 }}><label>Call to action</label><input className="input" value={ad.cta} onChange={e=>set("cta",e.target.value)}/></div>
          <div className="bld-sec-t" style={{ marginTop:8 }}>Linked listing</div>
          <select className="select" value={ad.listing} onChange={e=>{const l=LISTINGS.find(x=>x.id===e.target.value); set("listing",e.target.value); setAd(p=>({...p,listing:e.target.value,price:fmtPrice(l.price),specs:`${l.beds} bd · ${l.baths} ba · ${l.sqft.toLocaleString()} sqft`}));}}>
            {LISTINGS.map(l=><option key={l.id} value={l.id}>{l.addr} — {fmtPrice(l.price)}</option>)}
          </select>
          <div style={{ display:"flex", gap:10, marginTop:12 }}>
            <div className="field" style={{ flex:1 }}><label>Price</label><input className="input" value={ad.price} onChange={e=>set("price",e.target.value)}/></div>
          </div>
          <div style={{ display:"flex", gap:10, alignItems:"center", marginTop:18, padding:"12px 14px", background:"var(--surface-2)", borderRadius:10, border:"1px solid var(--line)" }}>
            <div style={{ width:42, height:42, borderRadius:7, background:"#0b0d12", display:"grid", gridTemplateColumns:"repeat(3,1fr)", gridTemplateRows:"repeat(3,1fr)", gap:2, padding:4, flex:"none" }}>
              {[1,0,1,0,1,1,1,0,1].map((b,i)=><span key={i} style={{ background:b?"#fff":"transparent", borderRadius:1 }}/>)}
            </div>
            <div style={{ fontSize:12, color:"var(--slate-500)", lineHeight:1.45 }}>A tracked <b>QR code</b> is auto-generated and links to this listing's mobile page.</div>
          </div>
        </div>
      </div>
    </div>
  );
}

function AdPreview({ ad, theme }) {
  const QR = <div style={{ width:"22%", aspectRatio:"1", background:"#fff", borderRadius:"6%", padding:"3%", display:"grid", gridTemplateColumns:"repeat(5,1fr)", gridTemplateRows:"repeat(5,1fr)", gap:"3%" }}>
    {[1,0,1,1,0,0,1,0,1,1,1,0,1,0,1,1,1,0,1,0,0,1,1,0,1].map((b,i)=><span key={i} style={{ background:b?"#0b0d12":"transparent" }}/>)}
  </div>;
  const base = { position:"absolute", inset:0, background:theme.bg, color:theme.fg, display:"flex", overflow:"hidden" };
  if (ad.layout==="split") return (
    <div style={{...base}}>
      <div className="ph" data-label="property photo" style={{ width:"48%", background:"rgba(0,0,0,.2)" }}/>
      <div style={{ flex:1, padding:"7% 6%", display:"flex", flexDirection:"column", justifyContent:"center" }}>
        <div style={{ color:theme.accent, fontWeight:700, fontSize:"1.5cqw", letterSpacing:".1em", marginBottom:"3%" }}>FOR SALE</div>
        <div style={{ fontSize:"3.4cqw", fontWeight:700, lineHeight:1.05, letterSpacing:"-.02em" }}>{ad.headline}</div>
        <div style={{ fontSize:"1.6cqw", color:theme.sub, marginTop:"3%", lineHeight:1.4 }}>{ad.sub}</div>
        <div style={{ fontSize:"3cqw", fontWeight:700, marginTop:"5%" }}>{ad.price}</div>
        <div style={{ fontSize:"1.4cqw", color:theme.sub }}>{ad.specs}</div>
        <div style={{ display:"flex", alignItems:"center", gap:"4%", marginTop:"6%" }}>{QR}<div style={{ fontSize:"1.5cqw", color:theme.sub }}>{ad.cta}</div></div>
      </div>
    </div>
  );
  if (ad.layout==="minimal") return (
    <div style={{...base, flexDirection:"column", alignItems:"center", justifyContent:"center", textAlign:"center", padding:"6%" }}>
      <div style={{ color:theme.accent, fontWeight:700, fontSize:"1.5cqw", letterSpacing:".12em", marginBottom:"3%" }}>VANTAGE REALTY</div>
      <div style={{ fontSize:"4.4cqw", fontWeight:700, lineHeight:1.04, letterSpacing:"-.025em", maxWidth:"16ch" }}>{ad.headline}</div>
      <div style={{ fontSize:"1.7cqw", color:theme.sub, marginTop:"3%", maxWidth:"34ch" }}>{ad.sub}</div>
      <div style={{ marginTop:"5%" }}>{QR}</div>
      <div style={{ fontSize:"1.4cqw", color:theme.sub, marginTop:"3%" }}>{ad.cta}</div>
    </div>
  );
  if (ad.layout==="grid") return (
    <div style={{...base, flexDirection:"column", padding:"6%" }}>
      <div className="ph" data-label="property photo" style={{ flex:1, borderRadius:"3%", background:"rgba(0,0,0,.2)", marginBottom:"4%" }}/>
      <div style={{ display:"flex", alignItems:"flex-end", justifyContent:"space-between" }}>
        <div>
          <div style={{ fontSize:"3cqw", fontWeight:700, letterSpacing:"-.02em" }}>{ad.headline}</div>
          <div style={{ display:"flex", gap:"5%", marginTop:"2%", fontSize:"2cqw", fontWeight:700 }}><span>{ad.price}</span><span style={{ color:theme.sub, fontWeight:500, fontSize:"1.5cqw", alignSelf:"center" }}>{ad.specs}</span></div>
        </div>{QR}
      </div>
    </div>
  );
  // hero (default)
  return (
    <div style={{...base}}>
      <div className="ph" data-label="property photo" style={{ position:"absolute", inset:0, opacity:ad.theme==="light"?.5:.32 }}/>
      <div style={{ position:"absolute", inset:0, background:ad.theme==="light"?"linear-gradient(0deg,#fff,transparent 60%)":"linear-gradient(0deg,rgba(11,13,18,.9),transparent 55%)" }}/>
      <div style={{ position:"relative", marginTop:"auto", padding:"6%", width:"100%", display:"flex", alignItems:"flex-end", justifyContent:"space-between", gap:"4%" }}>
        <div style={{ flex:1 }}>
          <div style={{ color:theme.accent, fontWeight:700, fontSize:"1.5cqw", letterSpacing:".1em", marginBottom:"2%" }}>JUST LISTED</div>
          <div style={{ fontSize:"4cqw", fontWeight:700, lineHeight:1.02, letterSpacing:"-.025em" }}>{ad.headline}</div>
          <div style={{ fontSize:"1.7cqw", color:theme.sub, marginTop:"2%", maxWidth:"30ch" }}>{ad.sub}</div>
          <div style={{ display:"flex", alignItems:"baseline", gap:"3%", marginTop:"3%" }}><span style={{ fontSize:"3.4cqw", fontWeight:700 }}>{ad.price}</span><span style={{ fontSize:"1.5cqw", color:theme.sub }}>{ad.specs}</span></div>
        </div>
        <div style={{ textAlign:"center" }}>{QR}<div style={{ fontSize:"1.1cqw", color:theme.sub, marginTop:"6%", width:"100%" }}>{ad.cta}</div></div>
      </div>
    </div>
  );
}
window.Ads = Ads;
