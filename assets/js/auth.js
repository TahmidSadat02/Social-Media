// ── AUTH ──
function switchTab(tab) {
  document.querySelectorAll('.tab-btn').forEach((b,i) => b.classList.toggle('active', (tab==='login'&&i===0)||(tab==='signup'&&i===1)));
  document.getElementById('login-form').style.display = tab === 'login' ? 'block' : 'none';
  document.getElementById('signup-form').style.display = tab === 'signup' ? 'block' : 'none';
  document.getElementById('auth-msg').textContent = '';
}

async function login() {
  const email = document.getElementById('login-email').value;
  const pass = document.getElementById('login-pass').value;
  const msg = document.getElementById('auth-msg');
  msg.textContent = 'Signing in...';
  msg.style.color = 'var(--muted)';
  const { data, error } = await supabase.auth.signInWithPassword({ email, password: pass });
  if (error) { msg.style.color = 'var(--accent2)'; msg.textContent = error.message; return; }
  currentUser = data.user;
  await loadCurrentProfile();
  showApp();
}

async function signup() {
  const username = document.getElementById('signup-user').value.trim().toLowerCase();
  const email = document.getElementById('signup-email').value;
  const pass = document.getElementById('signup-pass').value;
  const msg = document.getElementById('auth-msg');
  if (!username || username.length < 3) { msg.style.color='var(--accent2)'; msg.textContent='Username must be 3+ chars'; return; }
  msg.textContent = 'Creating account...'; msg.style.color = 'var(--muted)';
  const { data, error } = await supabase.auth.signUp({ email, password: pass });
  if (error) { msg.style.color='var(--accent2)'; msg.textContent=error.message; return; }
  // Create profile
  await supabase.from('profiles').insert({ id: data.user.id, username, full_name: username });
  currentUser = data.user;
  await loadCurrentProfile();
  showApp();
}

async function logout() {
  await supabase.auth.signOut();
  currentUser = null; currentProfile = null;
  document.getElementById('app').style.display = 'none';
  document.getElementById('auth-screen').style.display = 'flex';
  showToast('Logged out');
}

async function checkSession() {
  const { data: { session } } = await supabase.auth.getSession();
  if (session) {
    currentUser = session.user;
    await loadCurrentProfile();
    showApp();
  } else {
    document.getElementById('auth-screen').style.display = 'flex';
  }
}

async function loadCurrentProfile() {
  const { data } = await supabase.from('profiles').select('*').eq('id', currentUser.id).single();
  currentProfile = data;
  if (data) updateSidebarUser(data);
}

function updateSidebarUser(profile) {
  document.getElementById('sidebar-name').textContent = profile.full_name || profile.username;
  document.getElementById('sidebar-handle').textContent = '@' + profile.username;
  setAvatar('sidebar-avatar', profile);
  setAvatar('composer-avatar', profile);
}

function setAvatar(elId, profile) {
  const el = document.getElementById(elId);
  if (!el) return;
  if (profile?.avatar_url) {
    el.innerHTML = `<img src="${profile.avatar_url}" onerror="this.parentElement.textContent='${(profile.username||'U')[0].toUpperCase()}'"/>`;
  } else {
    el.textContent = (profile?.username || profile?.full_name || 'U')[0].toUpperCase();
  }
}
