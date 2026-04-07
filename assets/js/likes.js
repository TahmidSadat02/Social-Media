// ── LIKES ──
async function toggleLike(postId, isLiked) {
  if (isLiked) {
    await supabase.from('likes').delete().eq('post_id', postId).eq('user_id', currentUser.id);
  } else {
    await supabase.from('likes').insert({ post_id: postId, user_id: currentUser.id });
  }
  // Reload posts for updated count
  if (viewingProfileId && document.getElementById('profile-page').style.display !== 'none') {
    loadProfilePosts(viewingProfileId);
  } else {
    loadPosts();
  }
}
