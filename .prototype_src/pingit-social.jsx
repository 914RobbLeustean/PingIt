// ─── Feed Screen ──────────────────────────────────────────────────────────────
function FeedScreen({ pings, onPingSelect }) {
  var [sort, setSort] = React.useState('hot');

  var sorted = pings.slice().sort(function(a, b) {
    if (sort === 'hot') {
      var scoreA = (a.isHot ? 100 : 0) + a.boosts * 2 + a.members;
      var scoreB = (b.isHot ? 100 : 0) + b.boosts * 2 + b.members;
      return scoreB - scoreA;
    }
    if (sort === 'new') return b.createdAt - a.createdAt;
    if (sort === 'near') return a.expiresAt - b.expiresAt;
    return 0;
  });

  return React.createElement('div', {
    style: { position: 'absolute', inset: 0, background: 'var(--bg)',
      display: 'flex', flexDirection: 'column' }
  },
    React.createElement(StatusBar),

    // Header
    React.createElement('div', { style: { padding: '4px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' } },
      React.createElement('div', null,
        React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 10 } },
          React.createElement('span', { style: { fontFamily: 'Syne', fontWeight: 800, fontSize: 30, color: 'var(--text)', letterSpacing: '-0.5px' } }, 'Feed'),
          React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 5 } },
            React.createElement('div', { style: { width: 7, height: 7, borderRadius: '50%', background: 'var(--live)', animation: 'live-pulse 1.5s ease-in-out infinite' } }),
            React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 11, color: 'var(--live)', fontWeight: 600, letterSpacing: '0.5px', textTransform: 'uppercase' } }, 'Live')
          )
        )
      ),
      // Sort button
      React.createElement('div', { style: { display: 'flex', gap: 6 } },
        ['hot', 'new', 'near'].map(function(s) {
          return React.createElement('button', {
            key: s,
            onClick: function() { setSort(s); },
            style: { height: 30, padding: '0 12px', borderRadius: 15,
              border: '1px solid ' + (sort === s ? 'var(--accent)' : 'var(--border)'),
              background: sort === s ? 'rgba(245,166,35,0.13)' : 'var(--surface)',
              color: sort === s ? 'var(--accent)' : 'var(--text-secondary)',
              fontFamily: 'DM Sans', fontSize: 12, fontWeight: 500, cursor: 'pointer',
              textTransform: 'capitalize' }
          }, s === 'near' ? 'expiring' : s);
        })
      )
    ),

    // Ping list
    React.createElement('div', {
      style: { flex: 1, overflowY: 'auto', padding: '14px 16px 90px',
        display: 'flex', flexDirection: 'column', gap: 10 }
    },
      sorted.length === 0
        ? React.createElement('div', { style: { textAlign: 'center', paddingTop: 80, color: 'var(--text-secondary)', fontFamily: 'DM Sans' } },
            'No pings nearby. Drop one.')
        : sorted.map(function(p) {
            return React.createElement(PingCard, { key: p.id, ping: p, onClick: onPingSelect });
          })
    )
  );
}

// ─── Ping Detail Screen ───────────────────────────────────────────────────────
function PingDetailScreen({ ping, onBack, onJoinChat }) {
  var [boosted, setBoosted] = React.useState(false);
  var [boostCount, setBoostCount] = React.useState(ping.boosts);
  var isOwn = ping.authorId === 'u1';

  function handleBoost() {
    if (boosted) return;
    setBoosted(true);
    setBoostCount(function(n) { return n + 1; });
  }

  var urgency = window.PINGIT_HELPERS.getUrgency(ping.expiresAt);
  var urgencyColor = urgency === 'critical' ? 'var(--hot)' : urgency === 'urgent' ? 'var(--accent)' : 'var(--text-secondary)';

  return React.createElement('div', {
    style: { position: 'absolute', inset: 0, background: 'var(--bg)', display: 'flex', flexDirection: 'column', zIndex: 400 }
  },
    React.createElement(StatusBar),

    // Header
    React.createElement('div', {
      style: { display: 'flex', alignItems: 'center', gap: 14, padding: '8px 20px 16px' }
    },
      React.createElement(BackBtn, { onClick: onBack }),
      React.createElement('span', { style: { fontFamily: 'Syne', fontWeight: 800, fontSize: 20, color: 'var(--text)' } },
        'Ping Details')
    ),

    // Content (scrollable)
    React.createElement('div', { style: { flex: 1, overflowY: 'auto', padding: '0 20px 32px' } },

      // Author + timer row
      React.createElement('div', { style: { display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 } },
        React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 10 } },
          React.createElement(Avatar, { username: ping.author, color: ping.authorColor, size: 40 }),
          React.createElement('div', null,
            React.createElement('div', { style: { fontFamily: 'Syne', fontWeight: 700, fontSize: 16, color: 'var(--text)' } },
              '@' + ping.author),
            React.createElement('div', { style: { fontFamily: 'DM Sans', fontSize: 12, color: 'var(--text-secondary)' } },
              'just now')
          )
        ),
        React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 5,
          background: 'rgba(245,166,35,0.1)', borderRadius: 20, padding: '6px 12px',
          border: '1px solid rgba(245,166,35,0.2)' } },
          React.createElement(Icons.Clock),
          React.createElement('span', { style: { fontFamily: 'DM Sans', fontWeight: 700, fontSize: 13, color: urgencyColor } },
            window.PINGIT_HELPERS.formatTimeRemaining(ping.expiresAt))
        )
      ),

      // Title
      React.createElement('div', { style: { fontFamily: 'Syne', fontWeight: 800, fontSize: 26,
        color: 'var(--text)', marginBottom: 10, lineHeight: 1.15, letterSpacing: '-0.5px' } },
        ping.emoji + '  ' + ping.title),

      // Description
      ping.description && React.createElement('p', {
        style: { margin: '0 0 18px', fontFamily: 'DM Sans', fontSize: 15,
          color: 'var(--text-secondary)', lineHeight: 1.6 }
      }, ping.description),

      // Stats card
      React.createElement('div', {
        style: { background: 'var(--surface)', borderRadius: 16, padding: '14px 18px',
          border: '1px solid var(--border)', display: 'flex', gap: 24, marginBottom: 20 }
      },
        React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 7 } },
          React.createElement('button', {
            onClick: handleBoost,
            style: { background: boosted ? 'rgba(245,166,35,0.15)' : 'var(--surface2)',
              border: '1px solid ' + (boosted ? 'var(--accent)' : 'var(--border)'),
              borderRadius: 20, padding: '6px 14px', cursor: boosted ? 'default' : 'pointer',
              display: 'flex', alignItems: 'center', gap: 6,
              fontFamily: 'DM Sans', fontWeight: 600, fontSize: 13,
              color: boosted ? 'var(--accent)' : 'var(--text-secondary)',
              transition: 'all 0.2s' }
          },
            React.createElement(Icons.Fire),
            boostCount + (boosted ? ' boosted' : ' boost')
          )
        ),
        React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 6,
          fontFamily: 'DM Sans', fontSize: 13, color: 'var(--text-secondary)' } },
          React.createElement(Icons.Members),
          React.createElement('span', null, ping.members + ' in chat')
        )
      ),

      // Hot badge
      ping.isHot && React.createElement('div', { style: { marginBottom: 20 } },
        React.createElement(HotBadge)
      ),

      // JOIN CHAT button
      React.createElement('button', {
        onClick: onJoinChat,
        style: { width: '100%', height: 56, borderRadius: 28, border: 'none', cursor: 'pointer',
          background: 'var(--accent)', color: '#000',
          fontFamily: 'Syne', fontWeight: 800, fontSize: 17, letterSpacing: '-0.3px',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          marginBottom: 14,
          boxShadow: '0 0 28px rgba(245,166,35,0.4), 0 8px 24px rgba(0,0,0,0.4)' }
      },
        React.createElement(Icons.Chat), 'JOIN CHAT'
      ),

      // Delete (own pings only)
      isOwn && React.createElement('button', {
        style: { width: '100%', height: 48, borderRadius: 24,
          border: '1px solid rgba(232,57,42,0.25)', cursor: 'pointer',
          background: 'rgba(232,57,42,0.07)', color: 'var(--hot)',
          fontFamily: 'DM Sans', fontWeight: 600, fontSize: 14,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }
      },
        React.createElement(Icons.Delete), 'Delete Ping'
      )
    )
  );
}

// ─── Chat Screen ──────────────────────────────────────────────────────────────
function ChatScreen({ ping, onBack }) {
  var baseMessages = window.PINGIT_DATA.chatMessages[ping.id] || [];
  var [messages, setMessages] = React.useState(baseMessages);
  var [input, setInput] = React.useState('');
  var [typing, setTyping] = React.useState(false);
  var [memberCount, setMemberCount] = React.useState(ping.members);
  var listRef = React.useRef(null);
  var livePool = window.PINGIT_DATA.liveMessages;
  var liveIndex = React.useRef(0);

  // Auto-scroll
  React.useEffect(function() {
    if (listRef.current) {
      listRef.current.scrollTop = listRef.current.scrollHeight;
    }
  }, [messages, typing]);

  // Simulate live incoming messages
  React.useEffect(function() {
    function scheduleNext() {
      var delay = 3000 + Math.random() * 5000;
      return setTimeout(function() {
        setTyping(true);
        var typingDelay = 800 + Math.random() * 800;
        setTimeout(function() {
          setTyping(false);
          var authors = ['stranger_0x', 'nightcrawler', 'idk.who', 'just.passing', 'uni.kid'];
          var author = authors[Math.floor(Math.random() * authors.length)];
          var text = livePool[liveIndex.current % livePool.length];
          liveIndex.current++;
          setMessages(function(prev) {
            return prev.concat([{ id: 'live_' + Date.now(), author: author, text: text,
              time: (function() { var n = new Date(); return n.getHours().toString().padStart(2,'0') + ':' + n.getMinutes().toString().padStart(2,'0'); })(),
              isOwn: false }]);
          });
          setMemberCount(function(n) { return n + (Math.random() > 0.6 ? 1 : 0); });
          timerRef.current = scheduleNext();
        }, typingDelay);
      }, delay);
    }
    var timerRef = { current: scheduleNext() };
    return function() { clearTimeout(timerRef.current); };
  }, []);

  function handleSend() {
    var text = input.trim();
    if (!text) return;
    var now = new Date();
    var time = now.getHours().toString().padStart(2,'0') + ':' + now.getMinutes().toString().padStart(2,'0');
    setMessages(function(prev) {
      return prev.concat([{ id: 'own_' + Date.now(), author: 'Radiana', text: text, time: time, isOwn: true }]);
    });
    setInput('');
  }

  function handleKeyDown(e) {
    if (e.key === 'Enter') handleSend();
  }

  return React.createElement('div', {
    style: { position: 'absolute', inset: 0, background: 'var(--bg)',
      display: 'flex', flexDirection: 'column', zIndex: 410 }
  },
    React.createElement(StatusBar),

    // Header
    React.createElement('div', { style: { padding: '4px 16px 12px', borderBottom: '1px solid var(--border)' } },
      React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 12 } },
        React.createElement(BackBtn, { onClick: onBack }),
        React.createElement('div', { style: { flex: 1 } },
          React.createElement('div', { style: { fontFamily: 'Syne', fontWeight: 800, fontSize: 16, color: 'var(--text)', lineHeight: 1.2 } },
            ping.emoji + ' ' + ping.title),
          React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 8, marginTop: 2 } },
            React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 5 } },
              React.createElement('div', { style: { width: 6, height: 6, borderRadius: '50%', background: 'var(--live)', animation: 'live-pulse 1.5s ease-in-out infinite' } }),
              React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 11, color: 'var(--live)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' } }, 'Live')
            ),
            React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 12, color: 'var(--text-secondary)' } },
              memberCount + ' in here')
          )
        ),
        React.createElement(UrgencyLabel, { expiresAt: ping.expiresAt })
      )
    ),

    // Messages
    React.createElement('div', {
      ref: listRef,
      style: { flex: 1, overflowY: 'auto', padding: '12px 16px', display: 'flex', flexDirection: 'column', gap: 8 }
    },
      messages.map(function(msg) {
        if (msg.isOwn) {
          return React.createElement('div', { key: msg.id, style: { display: 'flex', justifyContent: 'flex-end' } },
            React.createElement('div', {
              style: { maxWidth: '72%', background: 'var(--accent)', borderRadius: '18px 18px 4px 18px',
                padding: '10px 14px' }
            },
              React.createElement('p', { style: { margin: 0, fontFamily: 'DM Sans', fontSize: 14, color: '#000', lineHeight: 1.4 } }, msg.text),
              React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 10, color: 'rgba(0,0,0,0.5)', marginTop: 3, display: 'block', textAlign: 'right' } }, msg.time)
            )
          );
        }
        return React.createElement('div', { key: msg.id, style: { display: 'flex', flexDirection: 'column', alignItems: 'flex-start', maxWidth: '76%' } },
          React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 11, color: 'var(--text-secondary)', marginBottom: 3, paddingLeft: 4 } },
            '@' + msg.author),
          React.createElement('div', {
            style: { background: 'var(--surface)', borderRadius: '4px 18px 18px 18px',
              padding: '10px 14px', border: '1px solid var(--border)' }
          },
            React.createElement('p', { style: { margin: 0, fontFamily: 'DM Sans', fontSize: 14, color: 'var(--text)', lineHeight: 1.4 } }, msg.text),
            React.createElement('span', { style: { fontFamily: 'DM Sans', fontSize: 10, color: 'var(--text-secondary)', marginTop: 3, display: 'block' } }, msg.time)
          )
        );
      }),

      // Typing indicator
      typing && React.createElement('div', { style: { display: 'flex', alignItems: 'flex-end', gap: 8 } },
        React.createElement('div', {
          style: { background: 'var(--surface)', borderRadius: '4px 18px 18px 18px',
            padding: '12px 16px', display: 'flex', gap: 4, border: '1px solid var(--border)' }
        },
          [0, 0.18, 0.36].map(function(delay, i) {
            return React.createElement('div', {
              key: i,
              style: { width: 7, height: 7, borderRadius: '50%', background: 'var(--text-secondary)',
                animation: 'typing-dot 0.8s ease-in-out ' + delay + 's infinite' }
            });
          })
        )
      )
    ),

    // Input bar
    React.createElement('div', {
      style: { padding: '10px 12px 20px', borderTop: '1px solid var(--border)',
        display: 'flex', gap: 10, alignItems: 'center',
        background: 'rgba(9,9,18,0.95)', backdropFilter: 'blur(20px)' }
    },
      React.createElement('input', {
        value: input,
        onChange: function(e) { setInput(e.target.value); },
        onKeyDown: handleKeyDown,
        placeholder: 'say something…',
        style: { flex: 1, height: 44, borderRadius: 22, border: '1px solid var(--border2)',
          background: 'var(--surface)', padding: '0 16px', outline: 'none',
          fontFamily: 'DM Sans', fontSize: 14, color: 'var(--text)' }
      }),
      React.createElement('button', {
        onClick: handleSend,
        style: { width: 44, height: 44, borderRadius: 22, border: 'none', cursor: 'pointer',
          background: input.trim() ? 'var(--accent)' : 'var(--surface)',
          color: input.trim() ? '#000' : 'var(--text-secondary)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          transition: 'all 0.2s', flexShrink: 0 }
      }, React.createElement(Icons.Send))
    )
  );
}

Object.assign(window, { FeedScreen, PingDetailScreen, ChatScreen });
