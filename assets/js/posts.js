// ── POSTS ──
async function loadPosts() {
  const list = document.getElementById('posts-list');
  list.innerHTML = '<div class="loading"><div class="spinner"></div>Loading...</div>';

  const { data: posts, error } = await supabase
    .from('posts')
    .select(`*, profiles(id, username, full_name, avatar_url), likes(id, user_id)`)
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) { list.innerHTML = '<div class="empty-state"><div class="empty-text">Failed to load posts.<br/>Check your Supabase setup.</div></div>'; return; }
  if (!posts?.length) { list.innerHTML = '<div class="empty-state"><div class="empty-text">No posts yet.<br/>Be the first to post!</div></div>'; return; }

  list.innerHTML = posts.map(p => renderPost(p)).join('');
}

function renderPost(post) {
  const profile = post.profiles;
  const likeCount = post.likes?.length || 0;
  const isLiked = post.likes?.some(l => l.user_id === currentUser?.id);
  const isOwn = post.user_id === currentUser?.id;
  const timeAgo = getTimeAgo(post.created_at);
  const initials = (profile?.username || 'U')[0].toUpperCase();
  const avatarHtml = profile?.avatar_url
    ? `<img src="${profile.avatar_url}" onerror="this.parentElement.textContent='${initials}'"/>`
    : initials;

  return `
    <div class="post-card" id="post-${post.id}">
      <div class="post-header">
        <div class="avatar" onclick="showProfile('${profile?.id}')" style="cursor:pointer">${avatarHtml}</div>
        <div class="post-user">
          <div class="post-user-name" onclick="showProfile('${profile?.id}')">${profile?.full_name || profile?.username || 'Unknown'}</div>
          <div class="post-user-handle">@${profile?.username || '?'} · ${timeAgo}</div>
        </div>
        ${isOwn ? `<button class="post-delete" onclick="deletePost('${post.id}')">Delete</button>` : ''}
      </div>
      <div class="post-content">${escHtml(post.content)}</div>
      ${post.image_url ? `<img class="post-image" src="${escHtml(post.image_url)}" onerror="this.style.display='none'" alt="post image"/>` : ''}
      <div class="post-actions">
        <button class="action-btn ${isLiked ? 'liked' : ''}" onclick="toggleLike('${post.id}', ${isLiked})">
          ${isLiked ? 'Like' : 'Like'} <span>${likeCount}</span>
        </button>
      </div>
    </div>`;
}

async function createPost() {
  const content = document.getElementById('post-text').value.trim();
  const imageUrl = document.getElementById('post-img').value.trim();
  if (!content) { showToast('Write something first!', 'error'); return; }

  const { error } = await supabase.from('posts').insert({
    user_id: currentUser.id,
    content,
    image_url: imageUrl || null
  });

  if (error) { showToast('Failed to post', 'error'); return; }
  document.getElementById('post-text').value = '';
  document.getElementById('post-img').value = '';
  showToast('Posted!', 'success');
  loadPosts();
}

async function deletePost(postId) {
  const { error } = await supabase.from('posts').delete().eq('id', postId);
  if (!error) {
    document.getElementById(`post-${postId}`)?.remove();
    showToast('Deleted');
  }
}
