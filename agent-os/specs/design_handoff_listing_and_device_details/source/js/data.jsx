/* RePlay mock data */
const SITES = [
  { id: "s1", name: "Bushwick Flagship", type: "Brokerage", addr: "1247 Myrtle Ave, Brooklyn NY", screens: 4, online: 4, scans: 1840, color: "#2f6bff", x: 62, y: 44 },
  { id: "s2", name: "Williamsburg Leasing", type: "Leasing", addr: "88 Bedford Ave, Brooklyn NY", screens: 3, online: 2, scans: 1120, color: "#0fb5a6", x: 48, y: 38 },
  { id: "s3", name: "Hudson Yards Gallery", type: "Sales Gallery", addr: "20 Hudson Yards, New York NY", screens: 6, online: 6, scans: 3210, color: "#7c5cff", x: 30, y: 30 },
  { id: "s4", name: "Park Slope Office", type: "Brokerage", addr: "300 7th Ave, Brooklyn NY", screens: 2, online: 1, scans: 640, color: "#e8990f", x: 55, y: 58 },
  { id: "s5", name: "Astoria Pop-Up", type: "Event", addr: "31-01 Steinway St, Queens NY", screens: 1, online: 1, scans: 410, color: "#e5484d", x: 74, y: 26 },
];

const SCREENS = [
  { id: "scr1", name: "North Window", site: "Bushwick Flagship", player: "FireStick-4K · A1", playlist: "Bushwick · Featured", status: "live", heartbeat: "12s ago", orient: "Landscape" },
  { id: "scr2", name: "South Window", site: "Bushwick Flagship", player: "Signage Stick · A2", playlist: "Open Houses · Wknd", status: "live", heartbeat: "8s ago", orient: "Portrait" },
  { id: "scr3", name: "Lobby Display", site: "Bushwick Flagship", player: "FireStick-4K · A3", playlist: "Brand Loop", status: "live", heartbeat: "20s ago", orient: "Landscape" },
  { id: "scr4", name: "Desk Monitor", site: "Bushwick Flagship", player: "Raspberry Pi · A4", playlist: "Bushwick · Featured", status: "live", heartbeat: "5s ago", orient: "Landscape" },
  { id: "scr5", name: "Street Window", site: "Williamsburg Leasing", player: "FireStick-4K · B1", playlist: "WMSBG · Rentals", status: "live", heartbeat: "31s ago", orient: "Portrait" },
  { id: "scr6", name: "Corner Display", site: "Williamsburg Leasing", player: "Signage Stick · B2", playlist: "WMSBG · Rentals", status: "offline", heartbeat: "2h ago", orient: "Landscape" },
  { id: "scr7", name: "Interior Wall", site: "Williamsburg Leasing", player: "— unassigned —", playlist: "—", status: "idle", heartbeat: "—", orient: "Landscape" },
  { id: "scr8", name: "Gallery Hero", site: "Hudson Yards Gallery", player: "Signage Stick · C1", playlist: "HY · Luxury Showcase", status: "live", heartbeat: "3s ago", orient: "Landscape" },
  { id: "scr9", name: "Video Wall L", site: "Hudson Yards Gallery", player: "FireStick-4K · C2", playlist: "HY · Luxury Showcase", status: "live", heartbeat: "6s ago", orient: "Portrait" },
  { id: "scr10", name: "Video Wall R", site: "Hudson Yards Gallery", player: "FireStick-4K · C3", playlist: "HY · Luxury Showcase", status: "live", heartbeat: "6s ago", orient: "Portrait" },
];

const PLAYERS = [
  { id: "p1", name: "FireStick-4K · A1", site: "Bushwick Flagship", screen: "North Window", hw: "Amazon Fire TV Stick 4K", version: "2.8.1", status: "online", uptime: "14d" },
  { id: "p2", name: "Signage Stick · A2", site: "Bushwick Flagship", screen: "South Window", hw: "RePlay Signage Stick", version: "2.8.1", status: "online", uptime: "14d" },
  { id: "p3", name: "FireStick-4K · A3", site: "Bushwick Flagship", screen: "Lobby Display", hw: "Amazon Fire TV Stick 4K", version: "2.7.4", status: "online", uptime: "6d" },
  { id: "p4", name: "Raspberry Pi · A4", site: "Bushwick Flagship", screen: "Desk Monitor", hw: "Raspberry Pi 4 (4GB)", version: "2.8.1", status: "online", uptime: "21d" },
  { id: "p5", name: "FireStick-4K · B1", site: "Williamsburg Leasing", screen: "Street Window", hw: "Amazon Fire TV Stick 4K", version: "2.8.1", status: "online", uptime: "9d" },
  { id: "p6", name: "Signage Stick · B2", site: "Williamsburg Leasing", screen: "Corner Display", hw: "RePlay Signage Stick", version: "2.6.9", status: "offline", uptime: "—" },
  { id: "p7", name: "Signage Stick · C1", site: "Hudson Yards Gallery", screen: "Gallery Hero", hw: "RePlay Signage Stick", version: "2.8.1", status: "online", uptime: "30d" },
  { id: "p8", name: "FireStick-4K · C2", site: "Hudson Yards Gallery", screen: "Video Wall L", hw: "Amazon Fire TV Stick 4K", version: "2.8.1", status: "online", uptime: "30d" },
];

const LISTINGS = [
  { id: "l1", addr: "124 Maple Ave", area: "Bushwick", price: 1250000, beds: 3, baths: 2, sqft: 1840, status: "Active", type: "Townhouse", tone: "#3a5f8a", year: 1998, mls: "RP-124MA", dom: 14, agent: "Maya Chen", lscans: 401 },
  { id: "l2", addr: "88 Bedford Ave #4R", area: "Williamsburg", price: 4200, beds: 2, baths: 1, sqft: 950, status: "For Rent", type: "Apartment", tone: "#6a7c8a", year: 2015, mls: "RP-88BD", dom: 9, agent: "Dev Patel", lscans: 140 },
  { id: "l3", addr: "20 Hudson Yards #72A", area: "Manhattan", price: 8950000, beds: 4, baths: 4.5, sqft: 3600, status: "Active", type: "Condo", tone: "#8a6f5f", year: 2019, mls: "RP-20HY", dom: 31, agent: "Jordan Lee", lscans: 612 },
  { id: "l4", addr: "300 7th Ave #2", area: "Park Slope", price: 1875000, beds: 3, baths: 2, sqft: 1620, status: "Active", type: "Co-op", tone: "#5f7a6a", year: 1925, mls: "RP-300S", dom: 21, agent: "Maya Chen", lscans: 88 },
  { id: "l5", addr: "55 Steinway St", area: "Astoria", price: 3100, beds: 1, baths: 1, sqft: 720, status: "For Rent", type: "Apartment", tone: "#7a5f6f", year: 2008, mls: "RP-55ST", dom: 6, agent: "Dev Patel", lscans: 54 },
  { id: "l6", addr: "412 Knickerbocker", area: "Bushwick", price: 985000, beds: 2, baths: 1, sqft: 1100, status: "Pending", type: "Condo", tone: "#5f6a8a", year: 2021, mls: "RP-412K", dom: 44, agent: "Jordan Lee", lscans: 132 },
  { id: "l7", addr: "19 Greenpoint Ave", area: "Greenpoint", price: 2350000, beds: 3, baths: 2.5, sqft: 2100, status: "Active", type: "Townhouse", tone: "#4a6a7a", year: 1912, mls: "RP-19GP", dom: 18, agent: "Maya Chen", lscans: 96 },
  { id: "l8", addr: "77 Berry St #6F", area: "Williamsburg", price: 5400, beds: 2, baths: 2, sqft: 1080, status: "For Rent", type: "Apartment", tone: "#7a6a5f", year: 2017, mls: "RP-77BR", dom: 4, agent: "Dev Patel", lscans: 73 },
];

const CAMPAIGNS = [
  { id: "c1", name: "Spring Open Houses", ads: 6, status: "live", sites: 4, scans: 2140, start: "May 1", end: "Jun 15", color: "#2f6bff" },
  { id: "c2", name: "Luxury Showcase — HY", ads: 4, status: "live", sites: 1, scans: 3210, start: "Apr 12", end: "Jul 1", color: "#7c5cff" },
  { id: "c3", name: "Agent Recruiting Q2", ads: 3, status: "scheduled", sites: 3, scans: 0, start: "Jun 1", end: "Aug 31", color: "#0fb5a6" },
  { id: "c4", name: "Williamsburg Rentals", ads: 5, status: "live", sites: 2, scans: 1120, start: "Mar 1", end: "Ongoing", color: "#e8990f" },
  { id: "c5", name: "Brand Awareness Loop", ads: 2, status: "paused", sites: 5, scans: 880, start: "Feb 1", end: "Ongoing", color: "#5b6470" },
];

const ACTIVITY = [
  { who: "Maya Chen", act: "published", obj: "Bushwick · Featured", time: "4m ago", kind: "publish" },
  { who: "System", act: "player offline", obj: "Signage Stick · B2", time: "1h ago", kind: "alert" },
  { who: "Dev Patel", act: "created ad", obj: "124 Maple Ave — Hero", time: "2h ago", kind: "create" },
  { who: "Maya Chen", act: "scheduled", obj: "Agent Recruiting Q2", time: "3h ago", kind: "schedule" },
  { who: "System", act: "1,840 QR scans today across", obj: "5 sites", time: "today", kind: "metric" },
  { who: "Jordan Lee", act: "rolled back", obj: "WMSBG · Rentals → v4", time: "yesterday", kind: "rollback" },
];

const TOP_ADS = [
  { name: "20 HY #72A — Hero", camp: "Luxury Showcase", scans: 612, ctr: 18.4 },
  { name: "Spring Open House — Sat", camp: "Spring Open Houses", scans: 488, ctr: 14.1 },
  { name: "124 Maple Ave — Hero", camp: "Spring Open Houses", scans: 401, ctr: 12.8 },
  { name: "Join Our Team", camp: "Agent Recruiting Q2", scans: 233, ctr: 9.2 },
];

const fmtPrice = (n) => n >= 100000 ? "$" + (n/1000000).toFixed(2).replace(/\.?0+$/,"") + "M" : "$" + n.toLocaleString() + "/mo";

const ADS = [
  { id:"a1", name:"20 HY #72A — Hero", campaign:"Luxury Showcase", type:"Listing", status:"live", scans:612, ctr:18.4, updated:"1d ago", tone:"#8a6f5f", layout:"Hero" },
  { id:"a2", name:"Spring Open House — Sat", campaign:"Spring Open Houses", type:"Open House", status:"live", scans:488, ctr:14.1, updated:"3h ago", tone:"#0fb5a6", layout:"Minimal" },
  { id:"a3", name:"124 Maple Ave — Hero", campaign:"Spring Open Houses", type:"Listing", status:"live", scans:401, ctr:12.8, updated:"2h ago", tone:"#3a5f8a", layout:"Hero" },
  { id:"a4", name:"Join Our Team", campaign:"Agent Recruiting Q2", type:"Recruiting", status:"scheduled", scans:233, ctr:9.2, updated:"3h ago", tone:"#7c5cff", layout:"Minimal" },
  { id:"a5", name:"Vantage — #1 in Brooklyn", campaign:"Brand Awareness", type:"Branding", status:"live", scans:188, ctr:6.4, updated:"5d ago", tone:"#1c2230", layout:"Stat" },
  { id:"a6", name:"88 Bedford — Rental", campaign:"Williamsburg Rentals", type:"Listing", status:"live", scans:140, ctr:7.1, updated:"1d ago", tone:"#6a7c8a", layout:"Split" },
  { id:"a7", name:"412 Knickerbocker — Hero", campaign:"Spring Open Houses", type:"Listing", status:"draft", scans:0, ctr:0, updated:"just now", tone:"#5f6a8a", layout:"Hero" },
  { id:"a8", name:"Price Improved — 300 7th", campaign:"—", type:"Listing", status:"draft", scans:0, ctr:0, updated:"yesterday", tone:"#5f7a6a", layout:"Grid" },
];

const PLAYLISTS = [
  { id:"pl1", name:"Bushwick · Featured", site:"Bushwick Flagship", screens:2, slides:7, dur:"1:10", status:"published", version:"v6", updated:"4m ago", segs:[["#2f6bff",11],["#3a5f8a",17],["#5f6a8a",17],["#0fb5a6",14],["#7c5cff",20],["#3b414e",9],["#e8990f",11]] },
  { id:"pl2", name:"Open Houses · Weekend", site:"Bushwick Flagship", screens:1, slides:5, dur:"0:52", status:"published", version:"v3", updated:"3h ago", segs:[["#0fb5a6",30],["#3a5f8a",22],["#0fb5a6",18],["#7c5cff",15],["#e8990f",15]] },
  { id:"pl3", name:"Brand Loop", site:"Bushwick Flagship", screens:1, slides:4, dur:"0:38", status:"published", version:"v2", updated:"2d ago", segs:[["#1c2230",30],["#2f6bff",25],["#1c2230",25],["#e8990f",20]] },
  { id:"pl4", name:"WMSBG · Rentals", site:"Williamsburg Leasing", screens:2, slides:6, dur:"1:04", status:"draft", version:"v5", updated:"1h ago", segs:[["#2f6bff",15],["#6a7c8a",20],["#7a6a5f",18],["#0fb5a6",17],["#7c5cff",15],["#e8990f",15]] },
  { id:"pl5", name:"HY · Luxury Showcase", site:"Hudson Yards Gallery", screens:3, slides:8, dur:"1:32", status:"published", version:"v9", updated:"6h ago", segs:[["#7c5cff",14],["#8a6f5f",16],["#8a6f5f",16],["#2f6bff",12],["#0fb5a6",13],["#1c2230",11],["#7c5cff",10],["#e8990f",8]] },
  { id:"pl6", name:"Astoria Pop-Up", site:"Astoria Pop-Up", screens:1, slides:3, dur:"0:30", status:"draft", version:"v1", updated:"5d ago", segs:[["#e5484d",40],["#3a5f8a",35],["#e8990f",25]] },
];

Object.assign(window, { SITES, SCREENS, PLAYERS, LISTINGS, CAMPAIGNS, ACTIVITY, TOP_ADS, ADS, PLAYLISTS, fmtPrice });
