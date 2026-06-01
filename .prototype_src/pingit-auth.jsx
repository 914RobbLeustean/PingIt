// ─── Welcome Screen ───────────────────────────────────────────────────────────
function WelcomeScreen({ onCreateAccount, onSignIn }) {
  var rings = [0, 1.1, 2.2];
  var dots = [
    { cx:72,  cy:210, delay:0.4 },
    { cx:295, cy:148, delay:1.7 },
    { cx:328, cy:272, delay:0.1 },
    { cx:55,  cy:318, delay:2.5 },
    { cx:248, cy:362, delay:1.0 },
    { cx:140, cy:430, delay:2.9 },
    { cx:340, cy:195, delay:0.7 },
    { cx:180, cy:165, delay:1.4 },
  ];

  return React.createElement('div', {
    style: { position:'absolute', inset:0, background:'var(--bg)',
      display:'flex', flexDirection:'column', overflow:'hidden' }
  },
    /* Radar SVG */
    React.createElement('svg', {
      viewBox:'0 0 390 650', preserveAspectRatio:'xMidYMid slice',
      style: { position:'absolute', inset:0, width:'100%', height:'100%', opacity:0.55 }
    },
      rings.map(function(delay, i) {
        return React.createElement('g', { key:i, transform:'translate(195,300)',
          style: { animation:'radar-ring 3s ease-out '+delay+'s infinite', transformOrigin:'0 0' }},
          React.createElement('circle', { r:120, fill:'none', stroke:'#F5A623', strokeWidth:1.2 })
        );
      }),
      dots.map(function(d, i) {
        return React.createElement('g', { key:i, transform:'translate('+d.cx+','+d.cy+')',
          style: { animation:'dot-blink 5s ease-in-out '+d.delay+'s infinite' }},
          React.createElement('circle', { r:6, fill:'rgba(245,166,35,0.25)' }),
          React.createElement('circle', { r:3.5, fill:'#F5A623' })
        );
      })
    ),
    /* Top safe area */
    React.createElement('div', { style:{ height:54 }}),
    /* Spacer */
    React.createElement('div', { style:{ flex:1 }}),
    /* Logo block */
    React.createElement('div', { style:{ padding:'0 32px', zIndex:10 }},
      React.createElement('div', { style:{ display:'flex', alignItems:'center', gap:12, marginBottom:14 }},
        React.createElement('div', { style:{ position:'relative', width:18, height:18 }},
          React.createElement('div', { style:{ position:'absolute', inset:-5, borderRadius:'50%',
            background:'rgba(245,166,35,0.2)', animation:'logo-pulse 2s ease-in-out infinite' }}),
          React.createElement('div', { style:{ position:'absolute', inset:-2, borderRadius:'50%',
            background:'rgba(245,166,35,0.35)' }}),
          React.createElement('div', { style:{ width:18, height:18, borderRadius:'50%',
            background:'#F5A623', position:'absolute', inset:0 }})
        ),
        React.createElement('span', {
          style: { fontFamily:'Syne', fontWeight:800, fontSize:34, color:'var(--text)',
            letterSpacing:'-1px', lineHeight:1 }
        }, 'PINGIT')
      ),
      React.createElement('p', {
        style: { fontFamily:'DM Sans', fontSize:16, color:'var(--text-secondary)',
          margin:0, lineHeight:1.5, maxWidth:280, textWrap:'pretty' }
      }, 'The city is live. Feel it.')
    ),
    /* Spacer */
    React.createElement('div', { style:{ flex:1 }}),
    /* Buttons */
    React.createElement('div', { style:{ padding:'0 24px 48px', display:'flex', flexDirection:'column', gap:12, zIndex:10 }},
      React.createElement('button', {
        onClick: onCreateAccount,
        style: { width:'100%', height:56, borderRadius:28, border:'none', cursor:'pointer',
          background:'var(--accent)', color:'#000',
          fontFamily:'Syne', fontWeight:800, fontSize:16, letterSpacing:'-0.3px',
          boxShadow:'0 0 32px rgba(245,166,35,0.35), 0 8px 24px rgba(0,0,0,0.4)',
          transition:'transform 0.15s, box-shadow 0.15s' }
      }, 'Create Account'),
      React.createElement('button', {
        onClick: onSignIn,
        style: { width:'100%', height:56, borderRadius:28, border:'1px solid var(--border)',
          cursor:'pointer', background:'var(--surface)',
          color:'var(--text)', fontFamily:'DM Sans', fontWeight:500, fontSize:16 }
      }, 'Sign In')
    )
  );
}

// ─── Input Field ──────────────────────────────────────────────────────────────
function AuthInput({ placeholder, type, value, onChange, icon }) {
  var [showPw, setShowPw] = React.useState(false);
  var inputType = type === 'password' ? (showPw ? 'text' : 'password') : (type || 'text');
  return React.createElement('div', {
    style: { position:'relative', background:'var(--surface2)', borderRadius:14,
      border:'1px solid var(--border)', overflow:'hidden' }
  },
    React.createElement('input', {
      type: inputType,
      placeholder: placeholder,
      value: value,
      onChange: function(e) { onChange(e.target.value); },
      style: { width:'100%', height:52, background:'transparent', border:'none', outline:'none',
        padding: icon ? '0 48px 0 44px' : '0 16px',
        fontFamily:'DM Sans', fontSize:15, color:'var(--text)',
        boxSizing:'border-box' }
    }),
    icon && React.createElement('div', {
      style: { position:'absolute', left:14, top:'50%', transform:'translateY(-50%)',
        color:'var(--text-secondary)', pointerEvents:'none', display:'flex' }
    }, icon),
    type === 'password' && React.createElement('button', {
      onClick: function() { setShowPw(function(p){ return !p; }); },
      style: { position:'absolute', right:14, top:'50%', transform:'translateY(-50%)',
        background:'none', border:'none', cursor:'pointer', color:'var(--text-secondary)',
        display:'flex', alignItems:'center' }
    }, React.createElement(Icons.Eye))
  );
}

// ─── Sign In Screen ───────────────────────────────────────────────────────────
function SignInScreen({ onBack, onSignIn }) {
  var [email, setEmail] = React.useState('');
  var [password, setPassword] = React.useState('');
  var [error, setError] = React.useState('');
  var [loading, setLoading] = React.useState(false);

  function handleSignIn() {
    if (!email || !password) { setError('Fill in all fields.'); return; }
    setLoading(true);
    setError('');
    setTimeout(function() { setLoading(false); onSignIn(); }, 900);
  }

  return React.createElement('div', {
    style: { position:'absolute', inset:0, background:'var(--bg)', display:'flex', flexDirection:'column' }
  },
    React.createElement(StatusBar),
    /* Header */
    React.createElement('div', { style:{ display:'flex', alignItems:'center', gap:14, padding:'8px 20px 24px' }},
      React.createElement(BackBtn, { onClick: onBack }),
      React.createElement('span', { style:{ fontFamily:'Syne', fontWeight:800, fontSize:22, color:'var(--text)' }},
        'Sign In')
    ),
    /* Form */
    React.createElement('div', { style:{ padding:'0 24px', display:'flex', flexDirection:'column', gap:12 }},
      React.createElement(AuthInput, { placeholder:'Email', type:'email', value:email, onChange:setEmail,
        icon: React.createElement('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'currentColor' },
          React.createElement('path', { d:'M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z' })) }),
      React.createElement(AuthInput, { placeholder:'Password', type:'password', value:password, onChange:setPassword,
        icon: React.createElement('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'currentColor' },
          React.createElement('path', { d:'M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z' })) }),
      error && React.createElement('p', { style:{ margin:0, fontFamily:'DM Sans', fontSize:13, color:'var(--hot)' }}, error),
      React.createElement('button', {
        onClick: handleSignIn,
        style: { width:'100%', height:54, borderRadius:27, border:'none', cursor:'pointer',
          background: (!email || !password) ? 'var(--surface2)' : 'var(--accent)',
          color: (!email || !password) ? 'var(--text-secondary)' : '#000',
          fontFamily:'Syne', fontWeight:800, fontSize:16, marginTop:8,
          transition:'all 0.2s', opacity: loading ? 0.7 : 1 }
      }, loading ? 'Signing in…' : 'Sign In'),
      React.createElement('button', {
        style: { background:'none', border:'none', cursor:'pointer', color:'var(--text-secondary)',
          fontFamily:'DM Sans', fontSize:13, marginTop:4 }
      }, 'Forgot Password?')
    )
  );
}

// ─── Create Account Screen ────────────────────────────────────────────────────
function CreateAccountScreen({ onBack, onSignIn }) {
  var [email, setEmail] = React.useState('');
  var [username, setUsername] = React.useState('');
  var [password, setPassword] = React.useState('');
  var [confirm, setConfirm] = React.useState('');
  var [agreed, setAgreed] = React.useState(false);
  var [error, setError] = React.useState('');
  var [loading, setLoading] = React.useState(false);

  var canSubmit = email && username && password && confirm && agreed;

  function handleCreate() {
    if (!canSubmit) return;
    if (password !== confirm) { setError('Passwords do not match.'); return; }
    if (password.length < 6) { setError('Password must be 6+ characters.'); return; }
    setLoading(true); setError('');
    setTimeout(function() { setLoading(false); onSignIn(); }, 1100);
  }

  var lockIcon = React.createElement('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'currentColor' },
    React.createElement('path', { d:'M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z' }));

  return React.createElement('div', {
    style: { position:'absolute', inset:0, background:'var(--bg)', display:'flex', flexDirection:'column' }
  },
    React.createElement(StatusBar),
    React.createElement('div', { style:{ display:'flex', alignItems:'center', gap:14, padding:'8px 20px 24px' }},
      React.createElement(BackBtn, { onClick: onBack }),
      React.createElement('span', { style:{ fontFamily:'Syne', fontWeight:800, fontSize:22, color:'var(--text)' }},
        'Create Account')
    ),
    React.createElement('div', { style:{ padding:'0 24px', display:'flex', flexDirection:'column', gap:12 }},
      React.createElement(AuthInput, { placeholder:'Email', type:'email', value:email, onChange:setEmail,
        icon: React.createElement('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'currentColor' },
          React.createElement('path', { d:'M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z' })) }),
      React.createElement(AuthInput, { placeholder:'Username', type:'text', value:username, onChange:setUsername,
        icon: React.createElement('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'currentColor' },
          React.createElement('path', { d:'M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z' })) }),
      React.createElement(AuthInput, { placeholder:'Password', type:'password', value:password, onChange:setPassword, icon: lockIcon }),
      React.createElement(AuthInput, { placeholder:'Confirm Password', type:'password', value:confirm, onChange:setConfirm, icon: lockIcon }),
      React.createElement('label', {
        style: { display:'flex', alignItems:'center', gap:10, cursor:'pointer',
          fontFamily:'DM Sans', fontSize:13, color:'var(--text-secondary)', paddingLeft:2 }
      },
        React.createElement('div', {
          onClick: function() { setAgreed(function(a){ return !a; }); },
          style: { width:20, height:20, borderRadius:6, border:'1.5px solid ' + (agreed ? 'var(--accent)' : 'var(--border)'),
            background: agreed ? 'var(--accent)' : 'var(--surface2)',
            display:'flex', alignItems:'center', justifyContent:'center',
            flexShrink:0, transition:'all 0.2s', cursor:'pointer' }
        }, agreed && React.createElement('svg', { width:12, height:12, viewBox:'0 0 24 24', fill:'#000' },
          React.createElement('path', { d:'M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z' }))),
        React.createElement('span', null, 'I agree to the ',
          React.createElement('span', { style:{ color:'var(--accent)' }}, 'Terms'),
          ' and ',
          React.createElement('span', { style:{ color:'var(--accent)' }}, 'Privacy Policy'))
      ),
      error && React.createElement('p', { style:{ margin:0, fontFamily:'DM Sans', fontSize:13, color:'var(--hot)' }}, error),
      React.createElement('button', {
        onClick: handleCreate,
        style: { width:'100%', height:54, borderRadius:27, border:'none', cursor:'pointer',
          background: canSubmit ? 'var(--accent)' : 'var(--surface2)',
          color: canSubmit ? '#000' : 'var(--text-secondary)',
          fontFamily:'Syne', fontWeight:800, fontSize:16, marginTop:8,
          transition:'all 0.2s', opacity: loading ? 0.7 : 1 }
      }, loading ? 'Creating…' : 'Create Account')
    )
  );
}

Object.assign(window, { WelcomeScreen, SignInScreen, CreateAccountScreen });
