/* RePlay icon set — clean 24px stroke icons, currentColor */
const ICONS = {
  dashboard: <><rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/></>,
  sites: <><path d="M12 21s-7-5.2-7-11a7 7 0 0 1 14 0c0 5.8-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/></>,
  screens: <><rect x="2.5" y="4" width="19" height="13" rx="2"/><path d="M8 21h8M12 17v4"/></>,
  players: <><rect x="4" y="3" width="16" height="18" rx="2"/><path d="M9 7h6M9 11h6M12 17h.01"/></>,
  listings: <><path d="M4 11.5 12 5l8 6.5"/><path d="M6 10v9h12v-9"/><path d="M10 19v-5h4v5"/></>,
  ads: <><path d="M3 11v2a1 1 0 0 0 1 1h3l4 4V6L7 10H4a1 1 0 0 0-1 1z"/><path d="M16 8a5 5 0 0 1 0 8"/><path d="M19 5a9 9 0 0 1 0 14"/></>,
  campaigns: <><circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r="1"/></>,
  playlists: <><path d="M4 7h11M4 12h11M4 17h7"/><circle cx="18" cy="16" r="3"/><path d="M21 16v-6l-3 1"/></>,
  analytics: <><path d="M4 19V5M4 19h16"/><path d="M8 16v-4M12 16V8M16 16v-6M20 16v-2" strokeWidth="2.4"/></>,
  settings: <><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-2.9 1.2V21a2 2 0 1 1-4 0v-.1A1.7 1.7 0 0 0 7 19.4l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0-1.2-2.9H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 7l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 2.9-1.2V3a2 2 0 1 1 4 0v.1A1.7 1.7 0 0 0 17 4.6l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0 1.2 2.9H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></>,
  search: <><circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2"/></>,
  bell: <><path d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9z"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></>,
  plus: <><path d="M12 5v14M5 12h14"/></>,
  chevronD: <><path d="m6 9 6 6 6-6"/></>,
  chevronR: <><path d="m9 6 6 6-6 6"/></>,
  dots: <><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></>,
  filter: <><path d="M3 5h18l-7 8v6l-4-2v-4z"/></>,
  grid: <><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></>,
  list: <><path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/></>,
  map: <><path d="m9 4-6 2v14l6-2 6 2 6-2V4l-6 2-6-2z"/><path d="M9 4v14M15 6v14"/></>,
  wifi: <><path d="M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M12 19.5h.01"/></>,
  wifiOff: <><path d="M2 8.8a15 15 0 0 1 4-2.4M9 5.2a15 15 0 0 1 13 3.6M5 12.5a10 10 0 0 1 6.5-2.9M8.5 16a5 5 0 0 1 5.4-1.1M12 19.5h.01M2 2l20 20"/></>,
  play: <><path d="M7 5v14l11-7z"/></>,
  pause: <><rect x="7" y="5" width="3.5" height="14" rx="1"/><rect x="14" y="5" width="3.5" height="14" rx="1"/></>,
  qr: <><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><path d="M14 14h3v3M21 14v.01M14 21h.01M21 17v4h-4"/></>,
  check: <><path d="M20 6 9 17l-5-5"/></>,
  x: <><path d="M18 6 6 18M6 6l12 12"/></>,
  upload: <><path d="M12 16V4m0 0L7 9m5-5 5 5"/><path d="M4 17v2a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-2"/></>,
  clock: <><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>,
  eye: <><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/></>,
  bed: <><path d="M3 18v-6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v6M3 14h18M7 10V8a2 2 0 0 1 2-2h2v4"/></>,
  bath: <><path d="M4 12h16v3a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M6 12V6a2 2 0 0 1 2-2 2 2 0 0 1 2 2"/><path d="M9 6h2M6 19l-1 2M19 19l1 2"/></>,
  sqft: <><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h4M3 15h4M17 3v4M9 3v4"/></>,
  arrowUp: <><path d="M12 19V5M5 12l7-7 7 7"/></>,
  arrowDown: <><path d="M12 5v14M5 12l7 7 7-7"/></>,
  building: <><rect x="5" y="3" width="14" height="18" rx="1.5"/><path d="M9 7h2M13 7h2M9 11h2M13 11h2M9 15h2M13 15h2M10 21v-3h4v3"/></>,
  refresh: <><path d="M21 12a9 9 0 1 1-2.6-6.4M21 3v5h-5"/></>,
  calendar: <><rect x="3" y="4.5" width="18" height="16" rx="2"/><path d="M3 9h18M8 2.5v4M16 2.5v4"/></>,
  layers: <><path d="m12 3 9 5-9 5-9-5 9-5z"/><path d="m3 13 9 5 9-5"/></>,
  zap: <><path d="M13 2 4 14h7l-1 8 9-12h-7l1-8z"/></>,
  link: <><path d="M9 15l6-6M11 6l1-1a4 4 0 0 1 6 6l-1 1M13 18l-1 1a4 4 0 0 1-6-6l1-1"/></>,
  download: <><path d="M12 3v12M7 11l5 5 5-5M4 20h16"/></>,
};

function Icon({ name, size = 18, sw = 1.7, style, className }) {
  const p = ICONS[name];
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
      stroke="currentColor" strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"
      style={style} className={className} aria-hidden="true">{p}</svg>
  );
}

window.Icon = Icon;
