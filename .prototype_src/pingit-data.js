(function () {
  var _now = Date.now();

  window.PINGIT_DATA = {
    currentUser: {
      id: 'u1',
      username: 'Radiana',
      email: 'trvpapes@gmail.com',
      memberSince: 'May 2, 2026',
      color: '#F5A623',
    },

    pings: [
      {
        id: 'p1', authorId: 'u2', author: 'alex_m', authorColor: '#5DB8FE',
        title: 'Pickup basketball @ Iulius', category: 'sports', emoji: '🏀',
        lat: 46.7690, lng: 23.5930,
        createdAt: _now - 30 * 60000, expiresAt: _now + 5.5 * 3600000,
        boosts: 12, members: 8, isHot: true,
        description: 'Need 2 more players. I have the ball.',
      },
      {
        id: 'p2', authorId: 'u3', author: 'mia.eth', authorColor: '#8B7FE8',
        title: 'Study session @ Central Library', category: 'study', emoji: '📚',
        lat: 46.7715, lng: 23.5892,
        createdAt: _now - 2 * 3600000, expiresAt: _now + 21.5 * 3600000,
        boosts: 3, members: 5, isHot: false,
        description: 'Quiet table, 3rd floor. Laptop ok.',
      },
      {
        id: 'p3', authorId: 'u4', author: 'cluj.nights', authorColor: '#E8392A',
        title: 'Rooftop drinks @ Memo', category: 'social', emoji: '🍻',
        lat: 46.7728, lng: 23.5912,
        createdAt: _now - 3600000, expiresAt: _now + 23 * 3600000,
        boosts: 24, members: 14, isHot: true,
        description: 'Bring whoever. BYOB. Rooftop access tonight.',
      },
      {
        id: 'p4', authorId: 'u5', author: 'skate.cluj', authorColor: '#78E8A0',
        title: 'Skate session, NOW', category: 'sports', emoji: '🛹',
        lat: 46.7703, lng: 23.5955,
        createdAt: _now - 45 * 60000, expiresAt: _now + 44 * 60000,
        boosts: 7, members: 4, isHot: true,
        description: 'Central Park skate zone. Almost gone — come now.',
      },
      {
        id: 'p5', authorId: 'u1', author: 'Radiana', authorColor: '#F5A623',
        title: 'Coffee & remote work @ Joe', category: 'chill', emoji: '☕',
        lat: 46.7695, lng: 23.5905,
        createdAt: _now - 20 * 60000, expiresAt: _now + 47 * 3600000,
        boosts: 2, members: 1, isHot: false,
        description: 'Working on a project here. Drop in.',
      },
      {
        id: 'p6', authorId: 'u6', author: 'vibe.check', authorColor: '#FF9F7A',
        title: 'Jam session @ Casa', category: 'music', emoji: '🎸',
        lat: 46.7720, lng: 23.5945,
        createdAt: _now - 15 * 60000, expiresAt: _now + 11 * 3600000,
        boosts: 9, members: 6, isHot: false,
        description: 'Guitar and keys here. Bring your thing.',
      },
    ],

    chatMessages: {
      'p3': [
        { id: 'cm1', author: 'cluj.nights', text: "who's coming tonight??", time: '21:04', isOwn: false },
        { id: 'cm2', author: 'alex_m', text: 'omw, 10 mins', time: '21:06', isOwn: false },
        { id: 'cm3', author: 'mia.eth', text: 'is there actually a rooftop lol', time: '21:07', isOwn: false },
        { id: 'cm4', author: 'cluj.nights', text: 'yes + vibes 😭', time: '21:07', isOwn: false },
        { id: 'cm5', author: 'Radiana', text: 'just arrived, elevator?', time: '21:09', isOwn: true },
        { id: 'cm6', author: 'cluj.nights', text: 'right side, go up', time: '21:09', isOwn: false },
        { id: 'cm7', author: 'vibe.check', text: 'never done this before. WILD.', time: '21:11', isOwn: false },
        { id: 'cm8', author: 'alex_m', text: 'pingit diff fr 🔥', time: '21:11', isOwn: false },
      ],
      'p1': [
        { id: 'cm1', author: 'alex_m', text: 'need guards rn', time: '15:30', isOwn: false },
        { id: 'cm2', author: 'hoop.life', text: 'pg here, 5 mins', time: '15:31', isOwn: false },
        { id: 'cm3', author: 'alex_m', text: '🔥🔥 let\'s run it', time: '15:32', isOwn: false },
        { id: 'cm4', author: 'Radiana', text: 'sg, walking over', time: '15:33', isOwn: true },
      ],
      'p4': [
        { id: 'cm1', author: 'skate.cluj', text: 'yall where are you', time: '16:18', isOwn: false },
        { id: 'cm2', author: 'kick.flip', text: 'omw 🛹', time: '16:19', isOwn: false },
      ],
      'p6': [
        { id: 'cm1', author: 'vibe.check', text: 'who plays keys?', time: '18:04', isOwn: false },
        { id: 'cm2', author: 'sol.keys', text: 'me! omw', time: '18:05', isOwn: false },
        { id: 'cm3', author: 'vibe.check', text: "let's GO", time: '18:05', isOwn: false },
      ],
    },

    liveMessages: [
      "this is different 👀",
      "just joined!",
      "omw 🏃",
      "3 mins away",
      "who else is here?",
      "this spot is 🔥",
      "pingit W fr",
      "saw this on someone's phone, had to come",
      "never done this before",
      "lmao who are you people",
      "great vibes tho ngl",
      "adding this to my daily",
    ],
  };

  window.PINGIT_HELPERS = {
    formatTimeRemaining: function (expiresAt) {
      var ms = expiresAt - Date.now();
      if (ms <= 0) return 'expired';
      var h = Math.floor(ms / 3600000);
      var m = Math.floor((ms % 3600000) / 60000);
      if (h === 0) return m + 'm left';
      if (h >= 24) return Math.floor(h / 24) + 'd ' + (h % 24) + 'h';
      if (m === 0) return h + 'h left';
      return h + 'h ' + m + 'm';
    },

    getUrgency: function (expiresAt) {
      var ms = expiresAt - Date.now();
      if (ms <= 0) return 'expired';
      if (ms < 1.5 * 3600000) return 'critical';
      if (ms < 6 * 3600000) return 'urgent';
      return 'normal';
    },

    getUserColor: function (username) {
      var colors = ['#F5A623', '#5DB8FE', '#8B7FE8', '#E8392A', '#78E8A0', '#FF9F7A', '#F472B6'];
      var h = 0;
      var s = username || '?';
      for (var i = 0; i < s.length; i++) h = ((h * 31) + s.charCodeAt(i)) & 0xFFFF;
      return colors[h % colors.length];
    },
  };
})();
