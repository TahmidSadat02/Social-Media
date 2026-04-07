// ── FOLLOWS ──
async function loadSuggestions() {
  const list = document.getElementById('suggestions-list');
  const { data: profiles } = await supabase
    .from('profiles')
    .select('*')
    .neq('id', currentUser?.id)
    .limit(6);

  if (!profiles?.length) { list.innerHTML = '<div style="color:var(--muted);font-size:0.82rem;padding:8px 10px;">No users yet.</div>'; return; }

  // Check who we follow
  const { data: following } = await supabase.from('follows').select('following_id').eq('follower_id', currentUser.id);
  const followingIds = new Set((following || []).map(f => f.following_id));

  list.innerHTML = profiles.map(p => {
    const isF = followingIds.has(p.id);
    const init = (p.username||'U')[0].toUpperCase();
    const avatarHtml = p.avatar_url ? `<img src="${p.avatar_url}" onerror="this.parentElement.textContent='${init}'"/>` : init;
    return `
      <div class="suggest-card">
        <div class="avatar" onclick="showProfile('${p.id}')" style="cursor:pointer">${avatarHtml}</div>
        <div class="suggest-info">
          <div class="suggest-name" onclick="showProfile('${p.id}')">${p.full_name || p.username}</div>
          <div class="suggest-handle">@${p.username}</div>
        </div>
        <button class="follow-btn ${isF ? 'following' : ''}" id="sfbtn-${p.id}" onclick="toggleFollow('${p.id}', ${isF}, this)">
          ${isF ? 'Following' : 'Follow'}
        </button>
      </div>`;
  }).join('');
}

async function toggleFollow(userId, isFollowing, btn) {
  if (isFollowing) {
    await supabase.from('follows').delete().eq('follower_id', currentUser.id).eq('following_id', userId);
    btn.textContent = 'Follow';
    btn.classList.remove('following');
    btn.onclick = () => toggleFollow(userId, false, btn);
  } else {
    await supabase.from('follows').insert({ follower_id: currentUser.id, following_id: userId });
    btn.textContent = 'Following';
    btn.classList.add('following');
    btn.onclick = () => toggleFollow(userId, true, btn);
  }
  // Update stats if on profile
  if (viewingProfileId === userId) showProfile(userId);
}
