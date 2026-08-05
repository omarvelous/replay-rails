/* RePlay admin shell: sidebar, topbar, shared UI bits */
const { useState, useEffect, useRef, useReducer } = React;

const NAV = [
  { group: "Overview", items: [
    { id: "dashboard", label: "Dashboard", icon: "dashboard" },
    { id: "analytics", label: "Analytics", icon: "analytics" },
  ]},
  { group: "Network", items: [
    { id: "sites", label: "Sites", icon: "sites" },
    { id: "screens", label: "Screens", icon: "screens" },
    { id: "players", label: "Players", icon: "players" },
  ]},
  { group: "Content", items: [
    { id: "listings", label: "Listings", icon: "listings" },
    { id: "ads", label: "Ads", icon: "ads" },
    { id: "campaigns", label: "Campaigns", icon: "campaigns" },
    { id: "playlists", label: "Playlists", icon: "playlists" },
  ]},
];

function Logo({ light }) {
  return (
    <div className="logo">
      <span className="logo-mark">
        <svg viewBox="0 0 24 24" fill="none"><path d="M8 6.5v11l9-5.5-9-5.5z" fill="#fff"/></svg>
      </span>
      <span className="logo-word" style={{ color: light ? "#fff" : "var(--ink-900)" }}>Re<b style={{color: light ? "#7aa2ff" : "var(--blue)"}}>Play</b></span>
    </div>
  );
}

function Sidebar({ route, go }) {
  const section = route==="ad-builder" ? "ads" : route==="playlist-builder" ? "playlists" : route.startsWith("listing-") ? "listings" : route;
  return (
    <aside className="sidebar">
      <div className="sb-top"><Logo light /></div>
      <div className="sb-acct">
        <div className="sb-acct-mark">VR</div>
        <div className="sb-acct-meta">
          <div className="nm">Vantage Realty</div>
          <div className="pl">Enterprise · 5 sites</div>
        </div>
        <Icon name="chevronD" size={15} />
      </div>
      <nav className="sb-nav">
        {NAV.map(g => (
          <div className="sb-group" key={g.group}>
            <div className="sb-group-t">{g.group}</div>
            {g.items.map(it => (
              <button key={it.id} className={"sb-item" + (section === it.id ? " on" : "")} onClick={() => go(it.id)}>
                <Icon name={it.icon} size={18} />
                <span>{it.label}</span>
                {it.id === "screens" && <span className="sb-count">10</span>}
                {it.id === "players" && <span className="sb-dot-warn" title="1 offline" />}
              </button>
            ))}
          </div>
        ))}
      </nav>
      <div className="sb-bottom">
        <button className={"sb-item" + (route === "settings" ? " on" : "")} onClick={() => go("settings")}>
          <Icon name="settings" size={18} /><span>Settings</span>
        </button>
        <div className="sb-user">
          <div className="sb-user-av">MC</div>
          <div className="sb-user-meta"><div className="nm">Maya Chen</div><div className="rl">Office Manager</div></div>
          <Icon name="dots" size={16} />
        </div>
      </div>
    </aside>
  );
}

function Topbar({ title, sub, actions, onPublish, onSearch, go, pending = 2 }) {
  const [menu, setMenu] = useState(false);
  const ref = useRef(null);
  useEffect(() => {
    if (!menu) return;
    const off = (e) => { if (ref.current && !ref.current.contains(e.target)) setMenu(false); };
    document.addEventListener("pointerdown", off, true);
    return () => document.removeEventListener("pointerdown", off, true);
  }, [menu]);
  const creates = [
    ["Create an ad", "ad-builder", "ads", "Headline, media & QR — Canva-style"],
    ["Add a listing", "listings", "listings", "Pull from MLS or enter manually"],
    ["Build a playlist", "playlist-builder", "playlists", "Sequence what plays on a screen"],
    ["New campaign", "campaigns", "campaigns", "Group & schedule ads"],
    ["Register a device", "players", "players", "Pair a Fire Stick or signage stick"],
  ];
  return (
    <header className="topbar">
      <div className="tb-left">
        <h1 className="tb-title">{title}</h1>
        {sub && <span className="tb-sub">{sub}</span>}
      </div>
      <div className="tb-right">
        <button className="search tb-search" onClick={onSearch} title="Search & commands">
          <Icon name="search" size={15} />
          <span className="tb-search-ph">Search or jump to…</span>
          <span className="tb-kbd">⌘K</span>
        </button>
        {actions}
        <div className="tb-create" ref={ref}>
          <button className="btn btn-secondary" onClick={() => setMenu(m => !m)}><Icon name="plus" size={15} />Create<Icon name="chevronD" size={13} style={{ opacity: .6 }} /></button>
          {menu && (
            <div className="tb-menu">
              <div className="tb-menu-t">Create new</div>
              {creates.map(([label, route, icon, desc]) => (
                <button key={route} className="tb-menu-item" onClick={() => { setMenu(false); go(route); }}>
                  <span className="tb-menu-ic"><Icon name={icon} size={16} /></span>
                  <span><span className="nm">{label}</span><span className="ds">{desc}</span></span>
                </button>
              ))}
            </div>
          )}
        </div>
        <button className="tb-iconbtn" title="Notifications"><Icon name="bell" size={18} /><span className="tb-badge">3</span></button>
        <button className="btn btn-primary tb-publish" onClick={onPublish} title={pending + " unpublished change" + (pending===1?"":"s")}>
          <Icon name="upload" size={15} />Publish{pending > 0 && <span className="tb-publish-pill">{pending}</span>}
        </button>
      </div>
    </header>
  );
}

/* Command palette — ⌘K. Jump to any screen or quick-create. */
function CommandPalette({ open, onClose, go }) {
  const [q, setQ] = useState("");
  const inputRef = useRef(null);
  useEffect(() => { if (open) { setQ(""); setTimeout(() => inputRef.current?.focus(), 30); } }, [open]);
  if (!open) return null;
  const nav = NAV.flatMap(g => g.items.map(it => ({ ...it, group: g.group })));
  const actions = [
    { label: "Create an ad", route: "ad-builder", icon: "ads", kind: "Action" },
    { label: "Build a playlist", route: "playlist-builder", icon: "playlists", kind: "Action" },
    { label: "Add a listing", route: "listings", icon: "listings", kind: "Action" },
    { label: "Register a device", route: "players", icon: "players", kind: "Action" },
  ];
  const pages = nav.map(n => ({ label: n.label, route: n.id, icon: n.icon, kind: "Go to · " + n.group }));
  const all = [...actions, ...pages];
  const f = q.trim().toLowerCase();
  const results = f ? all.filter(r => r.label.toLowerCase().includes(f)) : all;
  return (
    <div className="cmdk-bg" onClick={onClose}>
      <div className="cmdk" onClick={e => e.stopPropagation()}>
        <div className="cmdk-input">
          <Icon name="search" size={17} style={{ color: "var(--slate-400)" }} />
          <input ref={inputRef} placeholder="Search screens, or type a command…" value={q}
            onChange={e => setQ(e.target.value)}
            onKeyDown={e => { if (e.key === "Enter" && results[0]) { go(results[0].route); onClose(); } if (e.key === "Escape") onClose(); }} />
          <span className="tb-kbd">esc</span>
        </div>
        <div className="cmdk-list">
          {results.length === 0 && <div className="cmdk-empty">No matches for “{q}”</div>}
          {results.map((r, i) => (
            <button key={r.kind + r.route} className="cmdk-item" onClick={() => { go(r.route); onClose(); }}>
              <span className="cmdk-ic"><Icon name={r.icon} size={16} /></span>
              <span className="cmdk-label">{r.label}</span>
              <span className="cmdk-kind">{r.kind}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

/* ---------- shared UI ---------- */
function Segmented({ options, value, onChange }) {
  return (
    <div className="seg">
      {options.map(o => (
        <button key={o.value} className={"seg-btn" + (value === o.value ? " on" : "")} onClick={() => onChange(o.value)}>
          {o.icon && <Icon name={o.icon} size={15} />}{o.label}
        </button>
      ))}
    </div>
  );
}

function Badge({ status }) {
  const map = {
    live: ["badge-green", "Live", true], online: ["badge-green", "Online", true],
    offline: ["badge-red", "Offline", false], idle: ["badge-gray", "Idle", false],
    draft: ["badge-amber", "Draft", false], published: ["badge-blue", "Published", false],
    scheduled: ["badge-teal", "Scheduled", false], paused: ["badge-gray", "Paused", false],
    Active: ["badge-green", "Active", false], "For Rent": ["badge-blue", "For Rent", false],
    Pending: ["badge-amber", "Pending", false],
  };
  const [cls, label, dot] = map[status] || ["badge-gray", status, false];
  return <span className={"badge " + cls}>{dot && <span className="dot" />}{label}</span>;
}

function StatCard({ label, value, delta, deltaDir, icon, accent, spark }) {
  return (
    <div className="stat">
      <div className="stat-top">
        <span className="stat-ic" style={{ background: accent + "18", color: accent }}><Icon name={icon} size={17} /></span>
        {delta != null && (
          <span className={"stat-delta " + (deltaDir === "down" ? "dn" : "up")}>
            <Icon name={deltaDir === "down" ? "arrowDown" : "arrowUp"} size={12} sw={2.4} />{delta}
          </span>
        )}
      </div>
      <div className="stat-val tabular">{value}</div>
      <div className="stat-lbl">{label}</div>
      {spark && <Sparkline data={spark} color={accent} />}
    </div>
  );
}

function Sparkline({ data, color = "#2f6bff", h = 30 }) {
  const w = 110, max = Math.max(...data), min = Math.min(...data);
  const pts = data.map((d, i) => [i / (data.length - 1) * w, h - ((d - min) / (max - min || 1)) * (h - 4) - 2]);
  const path = pts.map((p, i) => (i ? "L" : "M") + p[0].toFixed(1) + " " + p[1].toFixed(1)).join(" ");
  const area = path + ` L${w} ${h} L0 ${h} Z`;
  const gid = "sg" + Math.random().toString(36).slice(2, 7);
  return (
    <svg className="spark" viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none">
      <defs><linearGradient id={gid} x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor={color} stopOpacity="0.22" /><stop offset="1" stopColor={color} stopOpacity="0" />
      </linearGradient></defs>
      <path d={area} fill={`url(#${gid})`} />
      <path d={path} fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function Avatar({ name, color }) {
  const initials = name.split(" ").map(w => w[0]).slice(0, 2).join("");
  const c = color || "#2f6bff";
  return <span className="avatar" style={{ background: c + "20", color: c }}>{initials}</span>;
}

function PageGrid({ children }) { return <div className="page-grid">{children}</div>; }

function Note({ children }) {
  return (
    <div className="note">
      <span className="note-ic"><Icon name="layers" size={15} /></span>
      <div className="note-body">{children}</div>
    </div>
  );
}

function Donut({ value, size = 96, stroke = 11, color = "#2f6bff", track = "#eef0f3", label, sub }) {
  const r = (size - stroke) / 2, c = 2 * Math.PI * r, off = c * (1 - value / 100);
  return (
    <div className="donut" style={{ position: "relative", width: size, height: size }}>
      <svg width={size} height={size}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={track} strokeWidth={stroke} />
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth={stroke}
          strokeDasharray={c} strokeDashoffset={off} strokeLinecap="round"
          transform={`rotate(-90 ${size/2} ${size/2})`} style={{ transition: "stroke-dashoffset .6s" }} />
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", textAlign: "center" }}>
        <div>
          <div style={{ fontSize: 19, fontWeight: 700, letterSpacing: "-.02em" }} className="tabular">{label}</div>
          {sub && <div style={{ fontSize: 10.5, color: "var(--slate-400)", marginTop: 1 }}>{sub}</div>}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { Sidebar, Topbar, CommandPalette, Segmented, Badge, StatCard, Sparkline, Avatar, NAV, Logo, PageGrid, Note, Donut });
