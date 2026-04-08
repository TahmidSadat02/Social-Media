// ── USER SEARCH ──
let searchTimeout;

async function searchUsers(query) {
  const resultsDiv = document.getElementById('search-results');

  // Clear previous timeout
  clearTimeout(searchTimeout);

  // If query is empty, clear results
  if (!query || query.trim().length < 2) {
    resultsDiv.innerHTML = '';
    return;
  }

  // Show loading state
  resultsDiv.innerHTML = '<div class="loading" style="padding:12px 0;"><div class="spinner" style="width:20px;height:20px;margin:0 auto 6px;"></div><div style="font-size:0.8rem;">Searching...</div></div>';

  // Debounce search
  searchTimeout = setTimeout(async () => {
    await performSearch(query.trim());
  }, 300);
}

async function performSearch(query) {
  const resultsDiv = document.getElementById('search-results');

  try {
    // Search by username or full_name (case-insensitive)
    const { data: users, error } = await window.supabase
      .from('profiles')
      .select('*')
      .or(`username.ilike.%${query}%,full_name.ilike.%${query}%`)
      .neq('id', currentUser?.id)
      .limit(10);

    if (error) {
      resultsDiv.innerHTML = '<div style="padding:12px 10px;color:var(--muted);font-size:0.8rem;">Search failed</div>';
      return;
    }

    if (!users || users.length === 0) {
      resultsDiv.innerHTML = '<div style="padding:12px 10px;color:var(--muted);font-size:0.8rem;">No users found</div>';
      return;
    }

    // Get following status for each user
    const { data: following } = await window.supabase
      .from('follows')
      .select('following_id')
      .eq('follower_id', currentUser.id);

    const followingIds = new Set((following || []).map(f => f.following_id));

    // Render results
    resultsDiv.innerHTML = users.map(user => {
      const isFollowing = followingIds.has(user.id);
      const initials = (user.username || 'U')[0].toUpperCase();
      const avatarHtml = user.avatar_url
        ? `<img src="${user.avatar_url}" onerror="this.parentElement.textContent='${initials}'"/>`
        : initials;

      return `
        <div class="search-result-card">
          <div class="avatar" onclick="showProfile('${user.id}')" style="cursor:pointer">${avatarHtml}</div>
          <div class="search-result-info">
            <div class="search-result-name" onclick="showProfile('${user.id}')">${escHtml(user.full_name || user.username)}</div>
            <div class="search-result-handle">@${escHtml(user.username)}</div>
          </div>
          <button class="follow-btn-small ${isFollowing ? 'following' : ''}" id="sfbtn-search-${user.id}" onclick="toggleFollowFromSearch('${user.id}', ${isFollowing}, this)">
            ${isFollowing ? 'Following' : 'Follow'}
          </button>
        </div>`;
    }).join('');
  } catch (err) {
    console.error('Search error:', err);
    resultsDiv.innerHTML = '<div style="padding:12px 10px;color:var(--muted);font-size:0.8rem;">Search error</div>';
  }
}

async function toggleFollowFromSearch(userId, isFollowing, btn) {
  if (isFollowing) {
    await window.supabase
      .from('follows')
      .delete()
      .eq('follower_id', currentUser.id)
      .eq('following_id', userId);
    btn.textContent = 'Follow';
    btn.classList.remove('following');
    btn.onclick = () => toggleFollowFromSearch(userId, false, btn);
  } else {
    await window.supabase
      .from('follows')
      .insert({ follower_id: currentUser.id, following_id: userId });
    btn.textContent = 'Following';
    btn.classList.add('following');
    btn.onclick = () => toggleFollowFromSearch(userId, true, btn);
  }

  // Update profile if viewing
  if (viewingProfileId === userId) {
    showProfile(userId);
  }
}
