// ─── Icons ────────────────────────────────────────────────────────────────────
var Icons = {
  Map: function() {
    return React.createElement('svg', { width:22, height:22, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M20.5 3l-.16.03L15 5.1 9 3 3.36 4.9c-.21.07-.36.25-.36.48V20.5c0 .28.22.5.5.5l.16-.03L9 18.9l6 2.1 5.64-1.9c.21-.07.36-.25.36-.48V3.5c0-.28-.22-.5-.5-.5zM15 19l-6-2.11V5l6 2.11V19z' })
    );
  },
  Feed: function() {
    return React.createElement('svg', { width:22, height:22, viewBox:'0 0 24 24', fill:'none', stroke:'currentColor', strokeWidth:2, strokeLinecap:'round' },
      React.createElement('line', { x1:8, y1:6, x2:21, y2:6 }),
      React.createElement('line', { x1:8, y1:12, x2:21, y2:12 }),
      React.createElement('line', { x1:8, y1:18, x2:21, y2:18 }),
      React.createElement('circle', { cx:3.5, cy:6, r:1.5, fill:'currentColor', stroke:'none' }),
      React.createElement('circle', { cx:3.5, cy:12, r:1.5, fill:'currentColor', stroke:'none' }),
      React.createElement('circle', { cx:3.5, cy:18, r:1.5, fill:'currentColor', stroke:'none' })
    );
  },
  Profile: function() {
    return React.createElement('svg', { width:22, height:22, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z' })
    );
  },
  Settings: function() {
    return React.createElement('svg', { width:22, height:22, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.44.17-.47.41l-.36 2.54c-.59.24-1.13.56-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.32-.07.64-.07.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.04.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.21.08-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z' })
    );
  },
  Plus: function() {
    return React.createElement('svg', { width:26, height:26, viewBox:'0 0 24 24', fill:'#000' },
      React.createElement('path', { d:'M19 13H13v6h-2v-6H5v-2h6V5h2v6h6v2z' })
    );
  },
  Back: function() {
    return React.createElement('svg', { width:20, height:20, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z' })
    );
  },
  Send: function() {
    return React.createElement('svg', { width:20, height:20, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M2 21l21-9L2 3v7l15 2-15 2z' })
    );
  },
  Chat: function() {
    return React.createElement('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z' })
    );
  },
  Clock: function() {
    return React.createElement('svg', { width:13, height:13, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z' })
    );
  },
  Fire: function() {
    return React.createElement('svg', { width:13, height:13, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M13.5.67s.74 2.65.74 4.8c0 2.06-1.35 3.73-3.41 3.73-2.07 0-3.63-1.67-3.63-3.73l.03-.36C5.21 7.51 4 10.62 4 14c0 4.42 3.58 8 8 8s8-3.58 8-8C20 8.61 17.41 2.8 13.5.67z' })
    );
  },
  Members: function() {
    return React.createElement('svg', { width:13, height:13, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z' })
    );
  },
  ChevronRight: function() {
    return React.createElement('svg', { width:16, height:16, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z' })
    );
  },
  Eye: function() {
    return React.createElement('svg', { width:20, height:20, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z' })
    );
  },
  Delete: function() {
    return React.createElement('svg', { width:16, height:16, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z' })
    );
  },
  Sort: function() {
    return React.createElement('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M3 18h6v-2H3v2zM3 6v2h18V6H3zm0 7h12v-2H3v2z' })
    );
  },
  Location: function() {
    return React.createElement('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M12 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm8.94 3A8.994 8.994 0 0013 3.06V1h-2v2.06A8.994 8.994 0 003.06 11H1v2h2.06A8.994 8.994 0 0011 20.94V23h2v-2.06A8.994 8.994 0 0020.94 13H23v-2h-2.06zM12 19c-3.87 0-7-3.13-7-7s3.13-7 7-7 7 3.13 7 7-3.13 7-7 7z' })
    );
  },
  Check: function() {
    return React.createElement('svg', { width:16, height:16, viewBox:'0 0 24 24', fill:'currentColor' },
      React.createElement('path', { d:'M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z' })
    );
  },
};

// ─── Status Bar ────────────────────────────────────────────────────────────────
function StatusBar({ light }) {
  var [time, setTime] = React.useState('');
  React.useEffect(function() {
    function tick() {
      var n = new Date();
      var h = n.getHours().toString().padStart(2,'0');
      var m = n.getMinutes().toString().padStart(2,'0');
      setTime(h + ':' + m);
    }
    tick();
    var t = setInterval(tick, 15000);
    return function() { clearInterval(t); };
  }, []);

  var col = light ? '#fff' : 'var(--text)';
  return React.createElement('div', {
    style: { height:54, display:'flex', alignItems:'flex-end', justifyContent:'space-between',
      padding:'0 26px 10px', flexShrink:0 }
  },
    React.createElement('span', { style:{ fontFamily:'Syne', fontWeight:700, fontSize:15, color:col, letterSpacing:'-0.3px' }}, time),
    React.createElement('div', { style:{ display:'flex', gap:6, alignItems:'center' }},
      React.createElement('svg', { width:16, height:11, viewBox:'0 0 16 11', fill:col },
        React.createElement('rect', { x:0, y:5, width:3, height:6, rx:1 }),
        React.createElement('rect', { x:4.5, y:3, width:3, height:8, rx:1 }),
        React.createElement('rect', { x:9, y:1, width:3, height:10, rx:1 }),
        React.createElement('rect', { x:13.5, y:0, width:2.5, height:11, rx:1, opacity:.3 })
      ),
      React.createElement('svg', { width:15, height:11, viewBox:'0 0 24 17', fill:'none', stroke:col, strokeWidth:2.2, strokeLinecap:'round' },
        React.createElement('path', { d:'M1 5.5C6 1.8 18 1.8 23 5.5' }),
        React.createElement('path', { d:'M4.5 9.5C8 6.8 16 6.8 19.5 9.5' }),
        React.createElement('path', { d:'M8.5 13C10.5 11.2 13.5 11.2 15.5 13' }),
        React.createElement('circle', { cx:12, cy:16.5, r:1.5, fill:col, stroke:'none' })
      ),
      React.createElement('div', { style:{ position:'relative', width:24, height:12 }},
        React.createElement('div', { style:{ width:21, height:12, border:'1.5px solid '+col, borderRadius:3 }},
          React.createElement('div', { style:{ position:'absolute', top:2.5, left:2, right:5, bottom:2.5, background:col, borderRadius:1 }})
        ),
        React.createElement('div', { style:{ position:'absolute', right:0, top:3.5, width:3, height:5, background:col, borderRadius:'0 2px 2px 0' }})
      )
    )
  );
}

// ─── Dynamic Island ────────────────────────────────────────────────────────────
function DynamicIsland() {
  return React.createElement('div', {
    style: { position:'absolute', top:14, left:'50%', transform:'translateX(-50%)',
      width:120, height:34, background:'#000', borderRadius:20, zIndex:200, pointerEvents:'none' }
  });
}

// ─── Tab Bar ──────────────────────────────────────────────────────────────────
function TabBar({ activeTab, onTabChange }) {
  var tabs = [
    { id:'map', label:'Map', Icon: Icons.Map },
    { id:'feed', label:'Feed', Icon: Icons.Feed },
    { id:'profile', label:'Profile', Icon: Icons.Profile },
    { id:'settings', label:'Settings', Icon: Icons.Settings },
  ];
  return React.createElement('div', {
    style: { position:'absolute', bottom:0, left:0, right:0, height:82, zIndex:500,
      background:'rgba(9,9,18,0.92)', backdropFilter:'blur(24px)',
      WebkitBackdropFilter:'blur(24px)',
      borderTop:'1px solid rgba(255,255,255,0.06)',
      display:'flex', alignItems:'flex-start', paddingTop:8 }
  },
    tabs.map(function(t) {
      var active = activeTab === t.id;
      return React.createElement('button', {
        key: t.id,
        onClick: function() { onTabChange(t.id); },
        style: { flex:1, display:'flex', flexDirection:'column', alignItems:'center', gap:3,
          border:'none', background:'none', cursor:'pointer',
          color: active ? 'var(--accent)' : 'var(--text-secondary)',
          padding:'4px 0', transition:'color 0.2s' }
      },
        React.createElement('div', {
          style: { width:44, height:28, display:'flex', alignItems:'center', justifyContent:'center',
            borderRadius:14, background: active ? 'rgba(245,166,35,0.13)' : 'transparent',
            transition:'background 0.2s' }
        }, React.createElement(t.Icon)),
        React.createElement('span', {
          style: { fontFamily:'DM Sans', fontSize:10, fontWeight: active ? 600 : 400, letterSpacing:'0.3px' }
        }, t.label)
      );
    })
  );
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
function Avatar({ username, color, size }) {
  size = size || 36;
  var bg = color || window.PINGIT_HELPERS.getUserColor(username || '?');
  var init = (username || '?')[0].toUpperCase();
  return React.createElement('div', {
    style: { width:size, height:size, borderRadius:'50%', background:bg,
      display:'flex', alignItems:'center', justifyContent:'center',
      fontFamily:'Syne', fontWeight:800, fontSize:size*0.4, color:'#fff', flexShrink:0 }
  }, init);
}

// ─── Hot Badge ────────────────────────────────────────────────────────────────
function HotBadge() {
  return React.createElement('span', {
    style: { display:'inline-flex', alignItems:'center', gap:3,
      background:'var(--hot)', color:'#fff', fontFamily:'DM Sans', fontWeight:700,
      fontSize:10, letterSpacing:'0.8px', padding:'2px 8px', borderRadius:20,
      textTransform:'uppercase' }
  }, '🔥 HOT');
}

// ─── Urgency Label ────────────────────────────────────────────────────────────
function UrgencyLabel({ expiresAt }) {
  var urgency = window.PINGIT_HELPERS.getUrgency(expiresAt);
  var color = urgency === 'critical' ? 'var(--hot)' : urgency === 'urgent' ? 'var(--accent)' : 'var(--text-secondary)';
  return React.createElement('span', {
    style: { display:'inline-flex', alignItems:'center', gap:4, color:color,
      fontFamily:'DM Sans', fontSize:12, fontWeight: urgency !== 'normal' ? 600 : 400 }
  },
    React.createElement(Icons.Clock),
    window.PINGIT_HELPERS.formatTimeRemaining(expiresAt)
  );
}

// ─── Ping Card ────────────────────────────────────────────────────────────────
function PingCard({ ping, onClick }) {
  var urgency = window.PINGIT_HELPERS.getUrgency(ping.expiresAt);
  var accentLeft = urgency === 'critical' ? 'var(--hot)' : urgency === 'urgent' ? 'var(--accent)' : null;
  return React.createElement('div', {
    onClick: function() { onClick(ping); },
    style: { background:'var(--surface)', borderRadius:16, padding:'14px 16px', cursor:'pointer',
      border: '1px solid ' + (ping.isHot ? 'rgba(232,57,42,0.2)' : 'var(--border)'),
      position:'relative', overflow:'hidden', transition:'transform 0.15s, box-shadow 0.15s',
      boxShadow: ping.isHot ? '0 0 20px rgba(232,57,42,0.08)' : 'none' }
  },
    accentLeft && React.createElement('div', {
      style: { position:'absolute', left:0, top:0, bottom:0, width:3, background:accentLeft,
        borderRadius:'16px 0 0 16px' }
    }),
    React.createElement('div', { style:{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:6 }},
      React.createElement('div', { style:{ display:'flex', alignItems:'center', gap:8 }},
        React.createElement(Avatar, { username: ping.author, color: ping.authorColor, size: 26 }),
        React.createElement('span', { style:{ fontFamily:'DM Sans', fontSize:12, color:'var(--text-secondary)', fontWeight:500 }},
          '@' + ping.author)
      ),
      ping.isHot && React.createElement(HotBadge)
    ),
    React.createElement('div', { style:{ fontFamily:'Syne', fontWeight:700, fontSize:17, color:'var(--text)',
      marginBottom:8, paddingLeft:34, lineHeight:1.2, textWrap:'pretty' }},
      ping.emoji + ' ' + ping.title),
    React.createElement('div', { style:{ display:'flex', alignItems:'center', gap:14, paddingLeft:34 }},
      React.createElement(UrgencyLabel, { expiresAt: ping.expiresAt }),
      React.createElement('span', { style:{ color:'var(--text-secondary)', fontSize:12,
        display:'flex', alignItems:'center', gap:3 }},
        React.createElement(Icons.Fire),
        React.createElement('span', { style:{ color: ping.boosts > 0 ? 'var(--accent)' : 'var(--text-secondary)' }},
          ping.boosts)
      ),
      React.createElement('span', { style:{ color:'var(--text-secondary)', fontSize:12,
        display:'flex', alignItems:'center', gap:3 }},
        React.createElement(Icons.Members), ping.members)
    )
  );
}

// ─── Back Button ──────────────────────────────────────────────────────────────
function BackBtn({ onClick, light }) {
  return React.createElement('button', {
    onClick: onClick,
    style: { width:38, height:38, borderRadius:'50%', border:'1px solid ' + (light ? 'rgba(255,255,255,0.2)' : 'var(--border)'),
      background: light ? 'rgba(255,255,255,0.12)' : 'var(--surface)',
      color: light ? '#fff' : 'var(--text)', cursor:'pointer',
      display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0,
      backdropFilter: light ? 'blur(12px)' : 'none' }
  }, React.createElement(Icons.Back));
}

Object.assign(window, { Icons, StatusBar, DynamicIsland, TabBar, Avatar, HotBadge, UrgencyLabel, PingCard, BackBtn });
