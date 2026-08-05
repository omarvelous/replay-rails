/* RePlay Admin — app router */
const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#2f6bff",
  "density": "comfortable",
  "corners": "rounded"
}/*EDITMODE-END*/;

const ACCENTS = {
  "#2f6bff": ["#1f54e0", "#eaf0ff"],
  "#0fb5a6": ["#0a9488", "#e2f7f4"],
  "#7c5cff": ["#5f3ee0", "#efebff"],
  "#e8990f": ["#c47e00", "#fdf3e1"],
};
const CORNERS = {
  rounded: { sm:"8px", md:"11px", lg:"16px", xl:"22px" },
  sharp:   { sm:"3px", md:"4px",  lg:"6px",  xl:"8px" },
};

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [route, setRoute] = useState(() => location.hash.replace("#","") || "dashboard");
  const [publishing, setPublishing] = useState(false);
  const [palette, setPalette] = useState(false);
  const [editor, setEditor] = useState(null);
  const [, force] = useReducer(x => x + 1, 0);
  const openEditor = (lid = null) => setEditor({ id: lid });
  const go = (r) => { setRoute(r); location.hash = r; document.querySelector(".scroll")?.scrollTo(0,0); };
  useEffect(()=>{ const h=()=>setRoute(location.hash.replace("#","")||"dashboard"); window.addEventListener("hashchange",h); return ()=>window.removeEventListener("hashchange",h); },[]);
  useEffect(()=>{
    const k=(e)=>{ if((e.metaKey||e.ctrlKey)&&e.key.toLowerCase()==="k"){ e.preventDefault(); setPalette(p=>!p); } };
    window.addEventListener("keydown",k); return ()=>window.removeEventListener("keydown",k);
  },[]);

  // apply tweaks to :root
  useEffect(()=>{
    const r = document.documentElement.style;
    const [strong, soft] = ACCENTS[t.accent] || ACCENTS["#2f6bff"];
    r.setProperty("--blue", t.accent); r.setProperty("--blue-strong", strong); r.setProperty("--blue-soft", soft);
    const c = CORNERS[t.corners] || CORNERS.rounded;
    r.setProperty("--r-sm", c.sm); r.setProperty("--r-md", c.md); r.setProperty("--r-lg", c.lg); r.setProperty("--r-xl", c.xl);
  }, [t.accent, t.corners]);

  const titles = {
    dashboard:["Dashboard","Good morning, Maya"], analytics:["Analytics",""], sites:["Sites",""],
    screens:["Screens",""], players:["Players",""], listings:["Listings",""], campaigns:["Campaigns",""], settings:["Settings",""],
    ads:["Ads",""], playlists:["Playlists",""],
  };
  const fullBleed = route==="ad-builder" || route==="playlist-builder";
  const listingId = route.startsWith("listing-") ? route.slice(8) : null;
  const Screen = listingId
    ? (props)=><ListingDetail id={listingId} {...props}/>
    : ({ dashboard:Dashboard, sites:Sites, screens:Screens, players:Players, listings:Listings,
        ads:AdsList, "ad-builder":Ads, campaigns:Campaigns, playlists:PlaylistsList, "playlist-builder":Playlists,
        analytics:Analytics, settings:Settings }[route] || Dashboard);
  const listing = listingId ? LISTINGS.find(x=>x.id===listingId) : null;
  const [title,sub] = listing ? [listing.addr, "Listing"] : (titles[route] || [route.charAt(0).toUpperCase()+route.slice(1),""]);

  return (
    <div className={"app density-"+t.density}>
      <Sidebar route={route} go={go}/>
      <div className="main">
        {fullBleed ? (
          <Screen go={go} openEditor={openEditor}/>
        ) : (
          <>
            <Topbar title={title} sub={sub} go={go} onSearch={()=>setPalette(true)} onPublish={()=>setPublishing(true)}/>
            <div className="scroll"><Screen go={go} openEditor={openEditor}/></div>
          </>
        )}
      </div>
      {editor && <ListingEditor id={editor.id} go={go} onSaved={force} onClose={()=>setEditor(null)}/>}
      {publishing && <PublishModal onClose={()=>setPublishing(false)}/>}
      <CommandPalette open={palette} onClose={()=>setPalette(false)} go={go}/>}
      <TweaksPanel>
        <TweakSection label="Brand accent" />
        <TweakColor label="Accent color" value={t.accent}
          options={["#2f6bff","#0fb5a6","#7c5cff","#e8990f"]}
          onChange={(v)=>setTweak("accent", v)} />
        <TweakSection label="Layout" />
        <TweakRadio label="Density" value={t.density}
          options={["comfortable","compact"]}
          onChange={(v)=>setTweak("density", v)} />
        <TweakRadio label="Corners" value={t.corners}
          options={["rounded","sharp"]}
          onChange={(v)=>setTweak("corners", v)} />
      </TweaksPanel>
    </div>
  );
}
ReactDOM.createRoot(document.getElementById("root")).render(<App/>);
