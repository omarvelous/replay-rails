/* Slide-over detail drawers for Screens and Players */

function Drawer({ children, onClose, width = 560 }) {
  useEffect(() => {
    const k = e => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", k);
    return () => window.removeEventListener("keydown", k);
  }, [onClose]);
  return (
    <div className="modal-bg" onClick={onClose} style={{ justifyItems: "end", placeItems: "stretch" }}>
      <div className="dw" onClick={e => e.stopPropagation()} style={{ width: `min(${width}px,100%)` }}>{children}</div>
    </div>
  );
}

function DwRow({ k, v }) {
  return <div className="dw-row"><span className="k">{k}</span><span className="v">{v}</span></div>;
}

function fakeSeries(seed, n = 14) {
  return Array.from({ length: n }, (_, i) => Math.round(40 + 30 * Math.sin(i * 0.8 + seed) + i * 1.5 + (i * seed) % 11));
}

/* ---------- Screen detail ---------- */
const SCREEN_HW = { Landscape: '55" Commercial LCD', Portrait: '49" Portrait LCD' };

function ScreenDetail({ screen: s, onClose, go }) {
  const [tab, setTab] = useState("overview");
  const player = PLAYERS.find(p => p.name === s.player);
  const site = SITES.find(x => x.name === s.site);
  const live = s.status === "live";
  const seed = s.id.length + s.name.length;
  const scans = 90 + (seed * 37) % 260;
  const items = [
    { n: "Featured listing — 124 Maple Ave", d: "12s", t: "Listing" },
    { n: "Open house — Sat 2–4PM", d: "8s", t: "Event" },
    { n: "Vantage Realty brand card", d: "6s", t: "Brand" },
    { n: "Just listed — 412 Knickerbocker", d: "12s", t: "Listing" },
  ];
  const total = items.reduce((a, b) => a + parseInt(b.d), 0);

  return (
    <Drawer onClose={onClose} width={580}>
      {/* live preview header */}
      <div className="dw-hero" style={{ aspectRatio: s.orient === "Portrait" ? "16/10" : "16/8" }}>
        <div className={"dw-stage" + (s.orient === "Portrait" ? " portrait" : "")}>
          <div className="dw-bezel"><ScreenContent screen={s} /></div>
        </div>
        <button className="icon-btn-sm dw-x" onClick={onClose}><Icon name="x" size={16} /></button>
        <span className="dw-hero-tag">
          {live ? <><span className="pulse-dot" />Live now</> : s.status === "offline" ? <><Icon name="wifiOff" size={12} />Offline</> : "No content"}
        </span>
      </div>

      <div className="dw-head">
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 5 }}>
          <h2 className="dw-title">{s.name}</h2><Badge status={s.status} />
        </div>
        <div className="dw-sub"><Icon name="sites" size={14} />{s.site} · {s.orient} · {SCREEN_HW[s.orient]}</div>
        <div className="dw-tabs">
          {[["overview", "Overview"], ["content", "Content"], ["activity", "Activity"]].map(([v, l]) => (
            <button key={v} className={"dw-tab" + (tab === v ? " on" : "")} onClick={() => setTab(v)}>{l}</button>
          ))}
        </div>
      </div>

      <div className="dw-body">
        {tab === "overview" && <>
          <div className="page-grid" style={{ gridTemplateColumns: "repeat(3,1fr)", marginBottom: 20 }}>
            <StatCard label="Scans (30d)" value={scans.toLocaleString()} icon="qr" accent="#e8990f" />
            <StatCard label="Uptime" value={live ? "99.4%" : "82.1%"} icon="players" accent={live ? "#1f9d57" : "#e5484d"} />
            <StatCard label="Loop length" value={total + "s"} icon="playlists" accent="#2f6bff" />
          </div>

          {!live && (
            <div className="dw-alert">
              <Icon name={s.status === "offline" ? "wifiOff" : "players"} size={17} style={{ flex: "none" }} />
              <div style={{ flex: 1, fontSize: 13, lineHeight: 1.45 }}>
                {s.status === "offline"
                  ? <>Last heartbeat <b>{s.heartbeat}</b>. The display is dark — check power and network on <b>{s.player}</b>.</>
                  : <>No player is paired to this screen, so nothing is playing. Register a device to bring it online.</>}
              </div>
              <button className="btn btn-sm dw-alert-btn" onClick={() => go("players")}>{s.status === "offline" ? "Troubleshoot" : "Pair device"}</button>
            </div>
          )}

          <h3 className="dw-h3">Playing now</h3>
          <div className="dw-card" onClick={() => go("playlist-builder")}>
            <span className="dw-ic"><Icon name="playlists" size={17} /></span>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div className="cell-strong" style={{ fontSize: 13.5 }}>{s.playlist === "—" ? "No playlist assigned" : s.playlist}</div>
              <div style={{ fontSize: 12, color: "var(--slate-400)" }}>{s.playlist === "—" ? "Assign one to start playing" : items.length + " items · " + total + "s loop"}</div>
            </div>
            <Icon name="chevronR" size={16} style={{ color: "var(--slate-300)" }} />
          </div>

          <h3 className="dw-h3">Hardware</h3>
          <DwRow k="Display" v={SCREEN_HW[s.orient]} />
          <DwRow k="Orientation" v={s.orient} />
          <DwRow k="Resolution" v={<span className="mono">{s.orient === "Portrait" ? "1080 × 1920" : "1920 × 1080"}</span>} />
          <DwRow k="Player" v={<span className="mono" style={{ fontSize: 12.5 }}>{s.player}</span>} />
          {player && <DwRow k="Firmware" v={<span className="mono" style={{ fontSize: 12.5, color: player.version === "2.8.1" ? "inherit" : "var(--amber)" }}>v{player.version}</span>} />}
          <DwRow k="Last heartbeat" v={<span className="mono" style={{ fontSize: 12.5 }}>{s.heartbeat}</span>} />
          <DwRow k="Site" v={site ? site.name : s.site} />
        </>}

        {tab === "content" && <>
          <h3 className="dw-h3" style={{ marginTop: 0 }}>Loop — {s.playlist === "—" ? "none" : s.playlist}</h3>
          {s.playlist === "—" ? (
            <div className="dw-empty">Nothing scheduled on this screen yet.</div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
              {items.map((it, i) => (
                <div key={i} className="dw-card">
                  <span className="dw-idx mono">{i + 1}</span>
                  <div className="ph" data-label="" style={{ width: 58, height: 36, borderRadius: 6, flex: "none", background: "var(--ink-900)" }} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div className="cell-strong" style={{ fontSize: 13.5, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{it.n}</div>
                    <div style={{ fontSize: 12, color: "var(--slate-400)" }}>{it.t}</div>
                  </div>
                  <span className="mono" style={{ fontSize: 12.5, color: "var(--slate-400)" }}>{it.d}</span>
                </div>
              ))}
            </div>
          )}
          <h3 className="dw-h3">Schedule</h3>
          <DwRow k="Playing" v="Daily · 8:00 AM – 9:00 PM" />
          <DwRow k="Timezone" v="America/New_York" />
          <DwRow k="Overrides" v="None" />
        </>}

        {tab === "activity" && <>
          <h3 className="dw-h3" style={{ marginTop: 0 }}>QR scans · last 14 days</h3>
          <Sparkline data={fakeSeries(seed)} color="var(--blue)" h={54} />
          <h3 className="dw-h3">Event log</h3>
          <div className="dw-log">
            {[
              [live ? "Heartbeat received" : "Heartbeat lost", s.heartbeat, live ? "ok" : "bad"],
              ["Playlist published", "2h ago", "ok"],
              ["Content swapped to " + (s.playlist === "—" ? "none" : s.playlist), "Yesterday", "ok"],
              ["Player restarted", "3d ago", "warn"],
              ["Screen registered", "Mar 14, 2026", "ok"],
            ].map(([t, when, tone], i) => (
              <div key={i} className="dw-log-row">
                <span className={"dw-dot " + tone} />
                <span style={{ flex: 1, fontSize: 13 }}>{t}</span>
                <span className="mono" style={{ fontSize: 12, color: "var(--slate-400)" }}>{when}</span>
              </div>
            ))}
          </div>
        </>}
      </div>

      <div className="dw-foot">
        <button className="btn btn-secondary" style={{ flex: 1 }} onClick={() => go("playlist-builder")}><Icon name="playlists" size={15} />Change content</button>
        <button className="btn btn-primary" style={{ flex: 1 }} onClick={() => go("players")}><Icon name="refresh" size={15} />Restart screen</button>
      </div>
    </Drawer>
  );
}

/* ---------- Player detail ---------- */
const HW_TONE = { "Amazon Fire TV Stick 4K": "#ff9900", "RePlay Signage Stick": "#2f6bff", "Raspberry Pi 4 (4GB)": "#c51a4a" };

function PlayerDetail({ player: p, onClose, go }) {
  const [tab, setTab] = useState("overview");
  const tone = HW_TONE[p.hw] || "#5b6470";
  const online = p.status === "online";
  const stale = p.version !== "2.8.1";
  const screen = SCREENS.find(s => s.name === p.screen);
  const seed = p.id.length + p.name.length;

  return (
    <Drawer onClose={onClose} width={560}>
      <div className="dw-hero dw-hero-dev" style={{ background: `linear-gradient(150deg, ${tone}22, var(--surface-2))` }}>
        <span className="dw-dev-ic" style={{ background: tone + "1f", color: tone }}><Icon name="players" size={30} /></span>
        <button className="icon-btn-sm dw-x" onClick={onClose}><Icon name="x" size={16} /></button>
        <span className="dw-hero-tag dw-hero-tag-light">
          {online ? <><span className="pulse-dot" />Online · up {p.uptime}</> : <><Icon name="wifiOff" size={12} />Offline</>}
        </span>
      </div>

      <div className="dw-head">
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 5 }}>
          <h2 className="dw-title mono" style={{ fontSize: 19 }}>{p.name}</h2>
          {online ? <span className="badge badge-green"><span className="dot" />Online</span> : <span className="badge badge-red"><span className="dot" />Offline</span>}
        </div>
        <div className="dw-sub"><Icon name="players" size={14} />{p.hw} · {p.site}</div>
        <div className="dw-tabs">
          {[["overview", "Overview"], ["diag", "Diagnostics"], ["activity", "Activity"]].map(([v, l]) => (
            <button key={v} className={"dw-tab" + (tab === v ? " on" : "")} onClick={() => setTab(v)}>{l}</button>
          ))}
        </div>
      </div>

      <div className="dw-body">
        {tab === "overview" && <>
          {!online && (
            <div className="dw-alert">
              <Icon name="wifiOff" size={17} style={{ flex: "none" }} />
              <div style={{ flex: 1, fontSize: 13, lineHeight: 1.45 }}>Unreachable since <b>2 hours ago</b>. <b>{p.screen}</b> is dark. Most often this is a pulled power cable or a dropped Wi-Fi network.</div>
              <button className="btn btn-sm dw-alert-btn">Troubleshoot</button>
            </div>
          )}
          {stale && online && (
            <div className="dw-alert warn">
              <Icon name="refresh" size={17} style={{ flex: "none" }} />
              <div style={{ flex: 1, fontSize: 13, lineHeight: 1.45 }}>Running <b className="mono">v{p.version}</b> — two versions behind. Update to <b className="mono">v2.8.1</b>.</div>
              <button className="btn btn-sm dw-alert-btn">Update</button>
            </div>
          )}

          <div className="page-grid" style={{ gridTemplateColumns: "repeat(3,1fr)", marginBottom: 20 }}>
            <StatCard label="Uptime" value={p.uptime} icon="players" accent={online ? "#1f9d57" : "#e5484d"} />
            <StatCard label="Firmware" value={"v" + p.version} icon="refresh" accent={stale ? "#e8990f" : "#2f6bff"} />
            <StatCard label="Restarts (30d)" value={online ? (seed % 4) : 6} icon="zap" accent="#7c5cff" />
          </div>

          <h3 className="dw-h3">Assigned screen</h3>
          {screen ? (
            <div className="dw-card">
              <div style={{ width: 62, height: 38, borderRadius: 6, overflow: "hidden", flex: "none", position: "relative", background: "var(--ink-900)" }}><ScreenContent screen={screen} mini /></div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="cell-strong" style={{ fontSize: 13.5 }}>{screen.name}</div>
                <div style={{ fontSize: 12, color: "var(--slate-400)" }}>{screen.playlist === "—" ? "No playlist" : screen.playlist}</div>
              </div>
              <Badge status={screen.status} />
            </div>
          ) : <div className="dw-empty">Not assigned to a screen.</div>}

          <h3 className="dw-h3">Device</h3>
          <DwRow k="Hardware" v={p.hw} />
          <DwRow k="RePlay app" v={<span className="mono" style={{ fontSize: 12.5 }}>v{p.version}</span>} />
          <DwRow k="Device ID" v={<span className="mono" style={{ fontSize: 12.5 }}>{("rp-" + p.id + "-9f4c").toUpperCase()}</span>} />
          <DwRow k="Site" v={p.site} />
          <DwRow k="Paired" v="Mar 14, 2026" />
          <DwRow k="Uptime" v={p.uptime} />
        </>}

        {tab === "diag" && <>
          <h3 className="dw-h3" style={{ marginTop: 0 }}>Connectivity</h3>
          <DwRow k="Network" v={online ? "Vantage-Guest · Wi-Fi 5 GHz" : "—"} />
          <DwRow k="Signal" v={online ? <span style={{ color: "var(--green)", fontWeight: 600 }}>Strong (−48 dBm)</span> : <span style={{ color: "var(--red)", fontWeight: 600 }}>No link</span>} />
          <DwRow k="IP address" v={<span className="mono" style={{ fontSize: 12.5 }}>{online ? "10.0.1." + (20 + seed % 60) : "—"}</span>} />
          <DwRow k="Last sync" v={<span className="mono" style={{ fontSize: 12.5 }}>{online ? "42s ago" : "2h ago"}</span>} />
          <h3 className="dw-h3">Resources</h3>
          {[["CPU", online ? 18 + seed % 22 : 0, "#2f6bff"], ["Memory", online ? 44 + seed % 20 : 0, "#0fb5a6"], ["Storage", 31 + seed % 14, "#7c5cff"], ["Media cache", 62, "#e8990f"]].map(([k, v, c]) => (
            <div key={k} className="dw-meter">
              <span className="dw-meter-k">{k}</span>
              <span className="dw-meter-bar"><span style={{ width: v + "%", background: c }} /></span>
              <span className="mono dw-meter-v">{v}%</span>
            </div>
          ))}
          <div style={{ display: "flex", gap: 9, marginTop: 18, flexWrap: "wrap" }}>
            <button className="btn btn-secondary btn-sm"><Icon name="refresh" size={14} />Restart player</button>
            <button className="btn btn-secondary btn-sm"><Icon name="download" size={14} />Pull logs</button>
            <button className="btn btn-secondary btn-sm"><Icon name="zap" size={14} />Clear cache</button>
          </div>
        </>}

        {tab === "activity" && <>
          <h3 className="dw-h3" style={{ marginTop: 0 }}>Hours online · last 14 days</h3>
          <Sparkline data={fakeSeries(seed + 3)} color={online ? "var(--teal)" : "var(--red)"} h={54} />
          <h3 className="dw-h3">Event log</h3>
          <div className="dw-log">
            {[
              [online ? "Content sync complete" : "Connection lost", online ? "42s ago" : "2h ago", online ? "ok" : "bad"],
              ["Playlist received", "2h ago", "ok"],
              [stale ? "Update available — v2.8.1" : "Updated to v2.8.1", "2d ago", stale ? "warn" : "ok"],
              ["Player restarted", "3d ago", "warn"],
              ["Device paired", "Mar 14, 2026", "ok"],
            ].map(([t, when, tone2], i) => (
              <div key={i} className="dw-log-row">
                <span className={"dw-dot " + tone2} />
                <span style={{ flex: 1, fontSize: 13 }}>{t}</span>
                <span className="mono" style={{ fontSize: 12, color: "var(--slate-400)" }}>{when}</span>
              </div>
            ))}
          </div>
        </>}
      </div>

      <div className="dw-foot">
        <button className="btn btn-secondary" style={{ flex: 1 }} onClick={() => go("screens")}><Icon name="screens" size={15} />Reassign screen</button>
        <button className="btn btn-primary" style={{ flex: 1 }}><Icon name="refresh" size={15} />Restart player</button>
      </div>
    </Drawer>
  );
}

Object.assign(window, { Drawer, ScreenDetail, PlayerDetail });
