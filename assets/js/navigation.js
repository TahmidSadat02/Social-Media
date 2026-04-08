// ── NAVIGATION ──
function showApp() {
  document.getElementById('auth-screen').style.display = 'none';
  document.getElementById('app').style.display = 'block';
  showFeed();
  // Start listening for new messages
  if (typeof subscribeToNewMessages === 'function') {
    subscribeToNewMessages();
  }
}

function showFeed() {
  document.getElementById('feed-page').style.display = 'block';
  document.getElementById('profile-page').style.display = 'none';
  if (document.getElementById('chat-page')) {
    document.getElementById('chat-page').style.display = 'none';
  }
  document.getElementById('nav-feed').classList.add('active');
  document.getElementById('nav-profile').classList.remove('active');
  if (document.getElementById('nav-messages')) {
    document.getElementById('nav-messages').classList.remove('active');
  }
  loadPosts();
  loadSuggestions();
}
