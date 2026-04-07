// ── NAVIGATION ──
function showApp() {
  document.getElementById('auth-screen').style.display = 'none';
  document.getElementById('app').style.display = 'block';
  showFeed();
}

function showFeed() {
  document.getElementById('feed-page').style.display = 'block';
  document.getElementById('profile-page').style.display = 'none';
  document.getElementById('nav-feed').classList.add('active');
  document.getElementById('nav-profile').classList.remove('active');
  loadPosts();
  loadSuggestions();
}
