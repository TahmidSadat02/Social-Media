// ── PROFILE ──
async function showProfile(userId) {
  if (!userId) return;
  viewingProfileId = userId;
  document.getElementById('feed-page').style.display = 'none';
  document.getElementById('profile-page').style.display = 'block';
  if (document.getElementById('chat-page')) {
    document.getElementById('chat-page').style.display = 'none';
  }
  document.getElementById('nav-feed').classList.remove('active');
  if (document.getElementById('nav-messages')) {
    document.getElementById('nav-messages').classList.remove('active');
  }

  const { data: profile } = await supabase.from('profiles').select('*').eq('id', userId).single();
  if (!profile) return;

  document.getElementById('profile-header-name').textContent = profile.full_name || profile.username;
  document.getElementById('profile-display-name').textContent = profile.full_name || profile.username;
  document.getElementById('profile-handle').textContent = '@' + profile.username;
  document.getElementById('profile-bio').textContent = profile.bio || '';

  const lgAvatar = document.getElementById('profile-avatar-lg');
  if (profile.avatar_url) {
    lgAvatar.innerHTML = `<img src="${profile.avatar_url}"/>`;
  } else {
    lgAvatar.textContent = (profile.username||'U')[0].toUpperCase();
  }

  // Stats
  const [postsRes, followersRes, followingRes] = await Promise.all([
    supabase.from('posts').select('id', { count: 'exact' }).eq('user_id', userId),
    supabase.from('follows').select('id', { count: 'exact' }).eq('following_id', userId),
    supabase.from('follows').select('id', { count: 'exact' }).eq('follower_id', userId),
  ]);
  document.getElementById('stat-posts').textContent = postsRes.count || 0;
  document.getElementById('stat-followers').textContent = followersRes.count || 0;
  document.getElementById('stat-following').textContent = followingRes.count || 0;

  // Follow button
  const followBtn = document.getElementById('follow-action-btn');
  const messageBtn = document.getElementById('message-action-btn');

  if (userId !== currentUser?.id) {
    followBtn.style.display = 'inline-block';
    messageBtn.style.display = 'inline-block';

    const { data: followData } = await supabase.from('follows')
      .select('id').eq('follower_id', currentUser.id).eq('following_id', userId).single();
    const isFollowing = !!followData;
    followBtn.textContent = isFollowing ? 'Following' : 'Follow';
    followBtn.className = 'follow-btn' + (isFollowing ? ' following' : '');
    followBtn.onclick = () => toggleFollow(userId, isFollowing, followBtn);
  } else {
    followBtn.style.display = 'none';
    messageBtn.style.display = 'none';
  }

  // Posts
  loadProfilePosts(userId);
}

async function loadProfilePosts(userId) {
  const list = document.getElementById('profile-posts-list');
  list.innerHTML = '<div class="loading"><div class="spinner"></div></div>';

  const { data: posts } = await supabase
    .from('posts')
    .select(`*, profiles(id, username, full_name, avatar_url), likes(id, user_id)`)
    .eq('user_id', userId)
    .order('created_at', { ascending: false });

  if (!posts?.length) { list.innerHTML = '<div class="empty-state"><div class="empty-text">No posts yet.</div></div>'; return; }
  list.innerHTML = posts.map(p => renderPost(p)).join('');
}
