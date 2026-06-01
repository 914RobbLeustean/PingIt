// ─── Map Screen ───────────────────────────────────────────────────────────────
function MapScreen({ pings, onPingSelect, onCreatePing }) {
  var containerRef = React.useRef(null);
  var mapRef = React.useRef(null);
  var markersRef = React.useRef({});

  // Init Leaflet map
  React.useEffect(function() {
    if (!containerRef.current || mapRef.current) return;

    var map = L.map(containerRef.current, {
      center: [46.7710, 23.5928],
      zoom: 15,
      zoomControl: false,
      attributionControl: false,
    });

    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd',
      maxZoom: 19,
    }).addTo(map);

    // Subtle attribution
    L.control.attribution({ position: 'bottomleft', prefix: '' })
      .addAttribution('© <a href="https://carto.com" style="color:#555">CARTO</a>')
      .addTo(map);

    mapRef.current = map;

    return function() {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  // Add / refresh markers when pings change
  React.useEffect(function() {
    if (!mapRef.current) return;

    // Remove stale markers
    Object.values(markersRef.current).forEach(function(m) { m.remove(); });
    markersRef.current = {};

    pings.forEach(function(ping) {
      var urgency = window.PINGIT_HELPERS.getUrgency(ping.expiresAt);
      var isHot = ping.isHot || urgency === 'critical';
      var cls = 'pm-wrap' + (isHot ? ' hot' : '') + (urgency === 'critical' ? ' critical' : '');

      var badge = ping.members > 1
        ? '<div class="pm-badge">' + ping.members + '</div>'
        : '';

      var html = '<div class="' + cls + '">'
        + '<div class="pm-pulse"></div>'
        + '<div class="pm-pulse pm-p2"></div>'
        + '<div class="pm-dot">' + ping.emoji + '</div>'
        + badge
        + '</div>';

      var icon = L.divIcon({ html: html, className: '', iconSize: [52, 52], iconAnchor: [26, 26] });
      var marker = L.marker([ping.lat, ping.lng], { icon: icon });

      marker.on('click', function() { onPingSelect(ping); });
      marker.addTo(mapRef.current);
      markersRef.current[ping.id] = marker;
    });
  }, [pings]);

  return React.createElement('div', { style: { position: 'absolute', inset: 0 } },

    // Leaflet container
    React.createElement('div', {
      ref: containerRef,
      style: { position: 'absolute', inset: 0 }
    }),

    // Top gradient for legibility
    React.createElement('div', {
      style: {
        position: 'absolute', top: 0, left: 0, right: 0, height: 130, zIndex: 1000,
        background: 'linear-gradient(to bottom, rgba(9,9,18,0.92) 0%, transparent 100%)',
        pointerEvents: 'none',
      }
    }),

    // Status bar
    React.createElement('div', { style: { position: 'absolute', top: 0, left: 0, right: 0, zIndex: 1001 } },
      React.createElement(StatusBar, { light: true })
    ),

    // "Map" label top-left
    React.createElement('div', {
      style: {
        position: 'absolute', top: 58, left: 20, zIndex: 1001,
        fontFamily: 'Syne', fontWeight: 800, fontSize: 28, color: '#fff',
        letterSpacing: '-0.5px', pointerEvents: 'none',
      }
    }, 'Map'),

    // Location re-center button
    React.createElement('button', {
      onClick: function() {
        if (mapRef.current) mapRef.current.flyTo([46.7710, 23.5928], 15, { duration: 0.8 });
      },
      style: {
        position: 'absolute', top: 62, right: 20, zIndex: 1002,
        width: 42, height: 42, borderRadius: 21,
        background: 'rgba(9,9,18,0.85)', backdropFilter: 'blur(12px)',
        border: '1px solid rgba(255,255,255,0.1)',
        color: 'var(--accent)', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }
    }, React.createElement(Icons.Location)),

    // Create Ping FAB
    React.createElement('button', {
      onClick: onCreatePing,
      style: {
        position: 'absolute', bottom: 98, right: 20, zIndex: 1002,
        width: 60, height: 60, borderRadius: 30,
        background: 'var(--accent)',
        border: 'none', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 0 28px rgba(245,166,35,0.55), 0 8px 24px rgba(0,0,0,0.5)',
        animation: 'fab-glow 2.5s ease-in-out infinite',
      }
    }, React.createElement(Icons.Plus))
  );
}

// ─── Map Ping Sheet (bottom preview card) ─────────────────────────────────────
function MapPingSheet({ ping, onClose, onViewDetails, onJoinChat }) {
  var [visible, setVisible] = React.useState(false);

  React.useEffect(function() {
    var t = requestAnimationFrame(function() { setVisible(true); });
    return function() { cancelAnimationFrame(t); };
  }, []);

  function handleClose() {
    setVisible(false);
    setTimeout(onClose, 280);
  }

  var urgency = window.PINGIT_HELPERS.getUrgency(ping.expiresAt);

  return React.createElement('div', {
    style: {
      position: 'absolute', inset: 0, zIndex: 600, pointerEvents: 'none',
    }
  },
    // Backdrop (tap to close)
    React.createElement('div', {
      onClick: handleClose,
      style: { position: 'absolute', inset: 0, pointerEvents: 'all' }
    }),

    // Sheet
    React.createElement('div', {
      style: {
        position: 'absolute', bottom: 82, left: 12, right: 12,
        background: 'var(--surface)',
        borderRadius: 24,
        border: '1px solid var(--border2)',
        padding: '20px 20px 20px',
        boxShadow: '0 -8px 40px rgba(0,0,0,0.6)',
        pointerEvents: 'all',
        transform: visible ? 'translateY(0)' : 'translateY(110%)',
        transition: 'transform 0.3s cubic-bezier(0.32,0.72,0,1)',
        backdropFilter: 'blur(20px)',
      }
    },

      // Drag handle
      React.createElement('div', {
        style: { width: 36, height: 4, borderRadius: 2, background: 'var(--border2)',
          margin: '0 auto 16px' }
      }),

      // Author row
      React.createElement('div', { style: { display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 } },
        React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 9 } },
          React.createElement(Avatar, { username: ping.author, color: ping.authorColor, size: 32 }),
          React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 13, color: 'var(--text-secondary)', fontWeight: 500 } },
            '@' + ping.author)
        ),
        React.createElement(UrgencyLabel, { expiresAt: ping.expiresAt })
      ),

      // Title
      React.createElement('div', {
        style: { fontFamily: 'Syne', fontWeight: 800, fontSize: 20, color: 'var(--text)',
          marginBottom: 6, lineHeight: 1.2 }
      }, ping.emoji + ' ' + ping.title),

      // Description
      ping.description && React.createElement('p', {
        style: { margin: '0 0 14px', fontFamily: 'DM Sans', fontSize: 13,
          color: 'var(--text-secondary)', lineHeight: 1.5 }
      }, ping.description),

      // Stats row
      React.createElement('div', {
        style: { display: 'flex', gap: 16, marginBottom: 18,
          fontFamily: 'DM Sans', fontSize: 13, color: 'var(--text-secondary)' }
      },
        React.createElement('span', { style: { display: 'flex', alignItems: 'center', gap: 4 } },
          React.createElement(Icons.Fire),
          React.createElement('span', { style: { color: ping.boosts > 0 ? 'var(--accent)' : 'inherit' } }, ping.boosts + ' boosts')
        ),
        React.createElement('span', { style: { display: 'flex', alignItems: 'center', gap: 4 } },
          React.createElement(Icons.Members), ping.members + ' in chat'
        )
      ),

      // Buttons
      React.createElement('div', { style: { display: 'flex', gap: 10 } },
        React.createElement('button', {
          onClick: onJoinChat,
          style: { flex: 1, height: 48, borderRadius: 24, border: 'none', cursor: 'pointer',
            background: 'var(--accent)', color: '#000',
            fontFamily: 'Syne', fontWeight: 800, fontSize: 14,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7,
            boxShadow: '0 0 20px rgba(245,166,35,0.3)' }
        },
          React.createElement(Icons.Chat), 'JOIN CHAT'
        ),
        React.createElement('button', {
          onClick: onViewDetails,
          style: { height: 48, padding: '0 18px', borderRadius: 24,
            border: '1px solid var(--border2)', cursor: 'pointer',
            background: 'var(--surface2)', color: 'var(--text)',
            fontFamily: 'DM Sans', fontWeight: 500, fontSize: 14 }
        }, 'Details')
      )
    )
  );
}

Object.assign(window, { MapScreen, MapPingSheet });
