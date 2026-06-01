// ─── Profile Screen ───────────────────────────────────────────────────────────
function ProfileScreen() {
  var user = window.PINGIT_DATA.currentUser;
  var pings = window.PINGIT_DATA.pings;
  var myPings = pings.filter(function(p) { return p.authorId === 'u1'; });
  var totalBoosts = myPings.reduce(function(s, p) { return s + p.boosts; }, 0);

  return React.createElement('div', {
    style: { position: 'absolute', inset: 0, background: 'var(--bg)', display: 'flex', flexDirection: 'column' }
  },
    React.createElement(StatusBar),

    React.createElement('div', { style: { flex: 1, overflowY: 'auto', paddingBottom: 90 } },

      // Header section
      React.createElement('div', { style: { padding: '8px 20px 24px' } },
        React.createElement('span', { style: { fontFamily: 'Syne', fontWeight: 800, fontSize: 30,
          color: 'var(--text)', letterSpacing: '-0.5px' } }, 'Profile')
      ),

      // Avatar + identity
      React.createElement('div', { style: { display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: 28 } },
        React.createElement('div', { style: { position: 'relative', marginBottom: 12 } },
          React.createElement('div', { style: { width: 86, height: 86, borderRadius: '50%',
            background: user.color, display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Syne', fontWeight: 800, fontSize: 36, color: '#fff',
            border: '3px solid rgba(245,166,35,0.4)',
            boxShadow: '0 0 24px rgba(245,166,35,0.2)' } },
            user.username[0].toUpperCase()
          ),
          React.createElement('button', {
            style: { position: 'absolute', bottom: 0, right: 0, width: 28, height: 28,
              borderRadius: '50%', background: 'var(--accent)', border: 'none', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center' }
          },
            React.createElement('svg', { width: 14, height: 14, viewBox: '0 0 24 24', fill: '#000' },
              React.createElement('path', { d: 'M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z' }))
          )
        ),
        React.createElement('div', { style: { fontFamily: 'Syne', fontWeight: 800, fontSize: 22, color: 'var(--text)', letterSpacing: '-0.3px' } },
          '@' + user.username),
        React.createElement('div', { style: { fontFamily: 'DM Sans', fontSize: 13, color: 'var(--text-secondary)', marginTop: 4 } },
          user.email)
      ),

      // Stats row
      React.createElement('div', {
        style: { display: 'flex', margin: '0 20px 24px', background: 'var(--surface)',
          borderRadius: 20, border: '1px solid var(--border)', overflow: 'hidden' }
      },
        [
          { label: 'Pings', value: myPings.length },
          { label: 'Boosts', value: totalBoosts },
          { label: 'Member', value: '1mo' },
        ].map(function(stat, i, arr) {
          return React.createElement('div', { key: stat.label,
            style: { flex: 1, padding: '16px 0', textAlign: 'center',
              borderRight: i < arr.length - 1 ? '1px solid var(--border)' : 'none' }
          },
            React.createElement('div', { style: { fontFamily: 'Syne', fontWeight: 800, fontSize: 22,
              color: 'var(--accent)', letterSpacing: '-0.5px' } }, stat.value),
            React.createElement('div', { style: { fontFamily: 'DM Sans', fontSize: 11, color: 'var(--text-secondary)',
              marginTop: 2, textTransform: 'uppercase', letterSpacing: '0.5px' } }, stat.label)
          );
        })
      ),

      // Info rows
      React.createElement('div', {
        style: { margin: '0 20px', background: 'var(--surface)', borderRadius: 20,
          border: '1px solid var(--border)', overflow: 'hidden' }
      },
        [
          { label: 'Username', value: '@' + user.username },
          { label: 'Email', value: user.email },
          { label: 'Member since', value: user.memberSince },
        ].map(function(row, i, arr) {
          return React.createElement('div', { key: row.label,
            style: { display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              padding: '14px 18px',
              borderBottom: i < arr.length - 1 ? '1px solid var(--border)' : 'none' }
          },
            React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 14, color: 'var(--text-secondary)' } },
              row.label),
            React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 14, color: 'var(--text)', fontWeight: 500 } },
              row.value)
          );
        })
      )
    )
  );
}

// ─── Settings Screen ──────────────────────────────────────────────────────────
function SettingsScreen({ onSignOut }) {
  var [notifyNearby, setNotifyNearby] = React.useState(true);
  var [notifyHot, setNotifyHot] = React.useState(true);
  var [privateProfile, setPrivateProfile] = React.useState(false);

  function Toggle({ on, onChange }) {
    return React.createElement('div', {
      onClick: function() { onChange(!on); },
      style: { width: 48, height: 28, borderRadius: 14, cursor: 'pointer',
        background: on ? 'var(--live)' : 'var(--surface2)',
        border: '1px solid ' + (on ? 'var(--live)' : 'var(--border)'),
        position: 'relative', transition: 'all 0.2s', flexShrink: 0 }
    },
      React.createElement('div', { style: { position: 'absolute', top: 2,
        left: on ? 22 : 2, width: 22, height: 22, borderRadius: 11,
        background: '#fff', transition: 'left 0.2s',
        boxShadow: '0 1px 4px rgba(0,0,0,0.3)' } })
    );
  }

  function SettingsRow({ label, rightEl, color, onClick, dimmed }) {
    return React.createElement('div', {
      onClick: onClick,
      style: { display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '15px 18px', cursor: onClick ? 'pointer' : 'default' }
    },
      React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 15,
        color: color || 'var(--text)', fontWeight: 500, opacity: dimmed ? 0.5 : 1 } },
        label),
      rightEl || React.createElement(Icons.ChevronRight)
    );
  }

  function SettingsSection({ title, children }) {
    return React.createElement('div', { style: { margin: '0 20px 20px' } },
      React.createElement('div', { style: { fontFamily: 'DM Sans', fontSize: 11, color: 'var(--text-secondary)',
        fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.8px',
        marginBottom: 8, paddingLeft: 4 } }, title),
      React.createElement('div', { style: { background: 'var(--surface)', borderRadius: 20,
        border: '1px solid var(--border)', overflow: 'hidden' } },
        children)
    );
  }

  function Divider() {
    return React.createElement('div', { style: { height: 1, background: 'var(--border)', margin: '0 18px' } });
  }

  return React.createElement('div', {
    style: { position: 'absolute', inset: 0, background: 'var(--bg)', display: 'flex', flexDirection: 'column' }
  },
    React.createElement(StatusBar),
    React.createElement('div', { style: { padding: '8px 20px 20px' } },
      React.createElement('span', { style: { fontFamily: 'Syne', fontWeight: 800, fontSize: 30, color: 'var(--text)', letterSpacing: '-0.5px' } }, 'Settings')
    ),

    React.createElement('div', { style: { flex: 1, overflowY: 'auto', paddingBottom: 90 } },
      React.createElement(SettingsSection, { title: 'Account' },
        React.createElement(SettingsRow, { label: 'Sign Out', color: 'var(--hot)', onClick: onSignOut,
          rightEl: React.createElement('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'var(--hot)' },
            React.createElement('path', { d: 'M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z' })) })
      ),

      React.createElement(SettingsSection, { title: 'Notifications' },
        React.createElement(SettingsRow, { label: 'Nearby Pings', rightEl: React.createElement(Toggle, { on: notifyNearby, onChange: setNotifyNearby }) }),
        React.createElement(Divider),
        React.createElement(SettingsRow, { label: 'Hot Pings', rightEl: React.createElement(Toggle, { on: notifyHot, onChange: setNotifyHot }) })
      ),

      React.createElement(SettingsSection, { title: 'Privacy & Safety' },
        React.createElement(SettingsRow, { label: 'Private Profile', rightEl: React.createElement(Toggle, { on: privateProfile, onChange: setPrivateProfile }) }),
        React.createElement(Divider),
        React.createElement(SettingsRow, { label: 'Blocked Users' }),
        React.createElement(Divider),
        React.createElement(SettingsRow, { label: 'Export My Data', color: 'var(--accent)',
          rightEl: React.createElement('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'var(--accent)' },
            React.createElement('path', { d: 'M9 16h6v-6h4l-7-7-7 7h4v6zm-4 2h14v2H5v-2z' })) })
      ),

      React.createElement(SettingsSection, { title: 'Legal' },
        React.createElement(SettingsRow, { label: 'Terms of Service' }),
        React.createElement(Divider),
        React.createElement(SettingsRow, { label: 'Privacy Policy' })
      ),

      React.createElement('div', { style: { margin: '0 20px 20px' } },
        React.createElement('div', { style: { background: 'var(--surface)', borderRadius: 20,
          border: '1px solid rgba(232,57,42,0.2)', overflow: 'hidden' } },
          React.createElement(SettingsRow, { label: 'Delete Account', color: 'var(--hot)' })
        )
      )
    )
  );
}

// ─── Create Ping Modal ────────────────────────────────────────────────────────
var CATEGORIES = [
  { id:'sports', emoji:'🏀', label:'Sports' }, { id:'study', emoji:'📚', label:'Study' },
  { id:'social', emoji:'🍻', label:'Social' }, { id:'music', emoji:'🎸', label:'Music' },
  { id:'food', emoji:'🍕', label:'Food' },   { id:'skate', emoji:'🛹', label:'Skate' },
  { id:'chill', emoji:'☕', label:'Chill' }, { id:'gaming', emoji:'🎮', label:'Gaming' },
  { id:'art', emoji:'🎨', label:'Art' },
];
var EXPIRY_OPTS = [
  { label:'1h', ms: 3600000 }, { label:'6h', ms: 21600000 },
  { label:'12h', ms: 43200000 }, { label:'24h', ms: 86400000 }, { label:'48h', ms: 172800000 },
];

function CreatePingModal({ onClose, onCreate }) {
  var [visible, setVisible] = React.useState(false);
  var [category, setCategory] = React.useState(null);
  var [text, setText] = React.useState('');
  var [expiry, setExpiry] = React.useState(EXPIRY_OPTS[1]);

  React.useEffect(function() {
    var t = requestAnimationFrame(function() { setVisible(true); });
    return function() { cancelAnimationFrame(t); };
  }, []);

  function handleClose() {
    setVisible(false);
    setTimeout(onClose, 300);
  }

  function handleCreate() {
    if (!text.trim() || !category) return;
    var cat = CATEGORIES.find(function(c) { return c.id === category; });
    onCreate({
      title: text.trim(),
      category: category,
      emoji: cat ? cat.emoji : '📍',
      lat: 46.7710 + (Math.random() - 0.5) * 0.01,
      lng: 23.5930 + (Math.random() - 0.5) * 0.01,
      expiresAt: Date.now() + expiry.ms,
      description: '',
    });
    handleClose();
  }

  var canCreate = text.trim().length > 0 && category;

  return React.createElement('div', {
    style: { position: 'absolute', inset: 0, zIndex: 800 }
  },
    // Backdrop
    React.createElement('div', {
      onClick: handleClose,
      style: { position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.7)',
        backdropFilter: 'blur(6px)', opacity: visible ? 1 : 0, transition: 'opacity 0.3s' }
    }),

    // Sheet
    React.createElement('div', {
      style: { position: 'absolute', bottom: 0, left: 0, right: 0,
        background: 'var(--surface)',
        borderRadius: '28px 28px 0 0',
        border: '1px solid var(--border2)',
        padding: '0 0 40px',
        transform: visible ? 'translateY(0)' : 'translateY(105%)',
        transition: 'transform 0.35s cubic-bezier(0.32,0.72,0,1)',
        maxHeight: '88%', overflowY: 'auto' }
    },
      // Handle + header
      React.createElement('div', { style: { padding: '14px 20px 16px', borderBottom: '1px solid var(--border)' } },
        React.createElement('div', { style: { width: 36, height: 4, borderRadius: 2, background: 'var(--border2)', margin: '0 auto 16px' } }),
        React.createElement('div', { style: { display: 'flex', alignItems: 'center', justifyContent: 'space-between' } },
          React.createElement('span', { style: { fontFamily: 'Syne', fontWeight: 800, fontSize: 22, color: 'var(--text)' } },
            'New Ping'),
          React.createElement('button', {
            onClick: handleClose,
            style: { background: 'var(--surface2)', border: '1px solid var(--border)', borderRadius: '50%',
              width: 32, height: 32, cursor: 'pointer', color: 'var(--text-secondary)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'DM Sans', fontSize: 18, lineHeight: 1 }
          }, '×')
        )
      ),

      // Category chips
      React.createElement('div', { style: { padding: '16px 20px 0' } },
        React.createElement('div', { style: { fontFamily: 'DM Sans', fontSize: 11, color: 'var(--text-secondary)',
          textTransform: 'uppercase', letterSpacing: '0.8px', fontWeight: 600, marginBottom: 10 } },
          'What kind of moment?'),
        React.createElement('div', { style: { display: 'flex', flexWrap: 'wrap', gap: 8 } },
          CATEGORIES.map(function(cat) {
            var sel = category === cat.id;
            return React.createElement('button', {
              key: cat.id,
              onClick: function() { setCategory(cat.id); },
              style: { display: 'flex', alignItems: 'center', gap: 6, height: 36, padding: '0 14px',
                borderRadius: 18, cursor: 'pointer', transition: 'all 0.2s',
                border: '1px solid ' + (sel ? 'var(--accent)' : 'var(--border)'),
                background: sel ? 'rgba(245,166,35,0.15)' : 'var(--surface2)',
                color: sel ? 'var(--accent)' : 'var(--text-secondary)',
                fontFamily: 'DM Sans', fontSize: 13, fontWeight: sel ? 600 : 400 }
            }, cat.emoji + ' ' + cat.label);
          })
        )
      ),

      // Text input
      React.createElement('div', { style: { padding: '20px 20px 0' } },
        React.createElement('div', { style: { fontFamily: 'DM Sans', fontSize: 11, color: 'var(--text-secondary)',
          textTransform: 'uppercase', letterSpacing: '0.8px', fontWeight: 600, marginBottom: 10 } },
          "What's happening right now?"),
        React.createElement('textarea', {
          value: text,
          onChange: function(e) { setText(e.target.value.slice(0, 280)); },
          placeholder: 'Be specific. Be real.',
          rows: 3,
          style: { width: '100%', background: 'var(--surface2)', border: '1px solid var(--border)',
            borderRadius: 16, padding: '14px 16px', outline: 'none', resize: 'none',
            fontFamily: 'DM Sans', fontSize: 15, color: 'var(--text)', lineHeight: 1.5,
            boxSizing: 'border-box' }
        }),
        React.createElement('div', { style: { textAlign: 'right', fontFamily: 'DM Sans', fontSize: 12,
          color: 'var(--text-secondary)', marginTop: 4 } },
          text.length + '/280')
      ),

      // Expiry
      React.createElement('div', { style: { padding: '20px 20px 0' } },
        React.createElement('div', { style: { fontFamily: 'DM Sans', fontSize: 11, color: 'var(--text-secondary)',
          textTransform: 'uppercase', letterSpacing: '0.8px', fontWeight: 600, marginBottom: 10 } },
          'Expires in'),
        React.createElement('div', { style: { display: 'flex', gap: 8 } },
          EXPIRY_OPTS.map(function(opt) {
            var sel = expiry.label === opt.label;
            return React.createElement('button', {
              key: opt.label,
              onClick: function() { setExpiry(opt); },
              style: { flex: 1, height: 40, borderRadius: 20, cursor: 'pointer', transition: 'all 0.2s',
                border: '1px solid ' + (sel ? 'var(--accent)' : 'var(--border)'),
                background: sel ? 'rgba(245,166,35,0.15)' : 'var(--surface2)',
                color: sel ? 'var(--accent)' : 'var(--text-secondary)',
                fontFamily: 'DM Sans', fontSize: 13, fontWeight: sel ? 700 : 400 }
            }, opt.label);
          })
        )
      ),

      // Location row
      React.createElement('div', { style: { margin: '20px 20px 0', background: 'var(--surface2)',
        borderRadius: 16, border: '1px solid var(--border)', padding: '14px 16px',
        display: 'flex', alignItems: 'center', gap: 10 } },
        React.createElement(Icons.Location),
        React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 14, color: 'var(--text-secondary)' } },
          'Current location (auto-detected)')
      ),

      // Create button
      React.createElement('div', { style: { padding: '24px 20px 0' } },
        React.createElement('button', {
          onClick: handleCreate,
          style: { width: '100%', height: 56, borderRadius: 28, border: 'none', cursor: canCreate ? 'pointer' : 'default',
            background: canCreate ? 'var(--accent)' : 'var(--surface2)',
            color: canCreate ? '#000' : 'var(--text-secondary)',
            fontFamily: 'Syne', fontWeight: 800, fontSize: 18, letterSpacing: '-0.3px',
            transition: 'all 0.2s',
            boxShadow: canCreate ? '0 0 28px rgba(245,166,35,0.35)' : 'none' }
        }, canCreate ? '⚡ PING IT' : 'Fill in the details')
      )
    )
  );
}

Object.assign(window, { ProfileScreen, SettingsScreen, CreatePingModal });
