function App() {
  var [screen, setScreen] = React.useState('welcome');
  var [appTab, setAppTab] = React.useState('map');
  var [selectedPing, setSelectedPing] = React.useState(null);
  var [chatPing, setChatPing] = React.useState(null);
  var [mapSheetPing, setMapSheetPing] = React.useState(null);
  var [showCreatePing, setShowCreatePing] = React.useState(false);
  var [pings, setPings] = React.useState(window.PINGIT_DATA.pings.slice());

  function goToApp() { setScreen('app'); setAppTab('map'); }
  function goToWelcome() { setScreen('welcome'); setAppTab('map'); }

  function openPingDetail(ping) {
    setSelectedPing(ping);
    setScreen('pingDetail');
  }

  function openChat(ping) {
    setChatPing(ping);
    setScreen('chat');
  }

  function handleTabChange(tab) {
    setAppTab(tab);
    setMapSheetPing(null);
  }

  function handleCreatePing(data) {
    var newPing = Object.assign({
      id: 'p' + Date.now(),
      authorId: 'u1',
      author: window.PINGIT_DATA.currentUser.username,
      authorColor: window.PINGIT_DATA.currentUser.color,
      boosts: 0,
      members: 1,
      isHot: false,
      createdAt: Date.now(),
    }, data);
    setPings(function(prev) { return [newPing].concat(prev); });
    setShowCreatePing(false);
    setAppTab('map');
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return React.createElement('div', { style: { position: 'absolute', inset: 0, background: 'var(--bg)' } },

    // Auth screens
    screen === 'welcome' && React.createElement(WelcomeScreen, {
      onCreateAccount: function() { setScreen('signup'); },
      onSignIn: function() { setScreen('signin'); },
    }),

    screen === 'signin' && React.createElement(SignInScreen, {
      onBack: function() { setScreen('welcome'); },
      onSignIn: goToApp,
    }),

    screen === 'signup' && React.createElement(CreateAccountScreen, {
      onBack: function() { setScreen('welcome'); },
      onSignIn: goToApp,
    }),

    // Main app
    screen === 'app' && React.createElement(React.Fragment, null,
      appTab === 'map' && React.createElement(MapScreen, {
        pings: pings,
        onPingSelect: function(p) { setMapSheetPing(p); },
        onCreatePing: function() { setShowCreatePing(true); },
      }),
      appTab === 'feed' && React.createElement(FeedScreen, {
        pings: pings,
        onPingSelect: openPingDetail,
      }),
      appTab === 'profile' && React.createElement(ProfileScreen, null),
      appTab === 'settings' && React.createElement(SettingsScreen, { onSignOut: goToWelcome }),

      React.createElement(TabBar, { activeTab: appTab, onTabChange: handleTabChange }),

      // Map ping bottom sheet
      mapSheetPing && React.createElement(MapPingSheet, {
        ping: mapSheetPing,
        onClose: function() { setMapSheetPing(null); },
        onViewDetails: function() { openPingDetail(mapSheetPing); setMapSheetPing(null); },
        onJoinChat: function() { openChat(mapSheetPing); setMapSheetPing(null); },
      }),

      // Create ping modal
      showCreatePing && React.createElement(CreatePingModal, {
        onClose: function() { setShowCreatePing(false); },
        onCreate: handleCreatePing,
      })
    ),

    // Detail screens (full-screen overlays)
    screen === 'pingDetail' && selectedPing && React.createElement(PingDetailScreen, {
      ping: selectedPing,
      onBack: function() { setScreen(appTab === 'map' ? 'app' : 'app'); },
      onJoinChat: function() { openChat(selectedPing); },
    }),

    screen === 'chat' && chatPing && React.createElement(ChatScreen, {
      ping: chatPing,
      onBack: function() { setScreen('pingDetail'); },
    })
  );
}

// ── Phone Frame + Mount ────────────────────────────────────────────────────────
function PhoneFrame() {
  return React.createElement('div', {
    style: {
      width: 393, height: 852,
      background: '#1c1c1e',
      borderRadius: 54,
      border: '10px solid #1c1c1e',
      boxShadow: [
        '0 0 0 1.5px #3a3a3c',
        '0 0 0 3px #2a2a2c',
        '0 50px 100px rgba(0,0,0,0.7)',
        '0 20px 40px rgba(0,0,0,0.5)',
        'inset 0 0 0 1px rgba(255,255,255,0.08)',
      ].join(', '),
      position: 'relative',
      flexShrink: 0,
    }
  },
    // Screen
    React.createElement('div', {
      style: { width: '100%', height: '100%', borderRadius: 44,
        background: 'var(--bg)', overflow: 'hidden', position: 'relative' }
    },
      React.createElement(DynamicIsland),
      React.createElement(App)
    ),

    // Side buttons (left)
    React.createElement('div', {
      style: { position: 'absolute', left: -13, top: 140, width: 4, height: 32,
        background: '#3a3a3c', borderRadius: '2px 0 0 2px' }
    }),
    React.createElement('div', {
      style: { position: 'absolute', left: -13, top: 184, width: 4, height: 64,
        background: '#3a3a3c', borderRadius: '2px 0 0 2px' }
    }),
    React.createElement('div', {
      style: { position: 'absolute', left: -13, top: 260, width: 4, height: 64,
        background: '#3a3a3c', borderRadius: '2px 0 0 2px' }
    }),
    // Right button
    React.createElement('div', {
      style: { position: 'absolute', right: -13, top: 200, width: 4, height: 80,
        background: '#3a3a3c', borderRadius: '0 2px 2px 0' }
    })
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(
  React.createElement('div', {
    style: {
      minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'radial-gradient(ellipse at 40% 30%, #14141f 0%, #08080f 100%)',
      padding: '24px',
    }
  },
    React.createElement(PhoneFrame)
  )
);
