// ── CHAT / MESSAGES ──
let activeChat = null;
let messageChannel = null;

// Show Messages/Chat page
function showMessages() {
  document.getElementById('feed-page').style.display = 'none';
  document.getElementById('profile-page').style.display = 'none';
  document.getElementById('chat-page').style.display = 'block';
  document.getElementById('nav-feed').classList.remove('active');
  document.getElementById('nav-profile').classList.remove('active');
  document.getElementById('nav-messages').classList.add('active');

  // Hide chat window, show conversations
  document.getElementById('conversations-view').style.display = 'block';
  document.getElementById('chat-window').style.display = 'none';

  loadConversations();
  updateUnreadCount();
}

// Load conversations list
async function loadConversations() {
  const list = document.getElementById('conversations-list');
  list.innerHTML = '<div class="loading"><div class="spinner"></div>Loading...</div>';

  // Get all messages where current user is sender or receiver
  const { data: messages, error } = await window.supabase
    .from('messages')
    .select('*, sender:profiles!sender_id(id, username, full_name, avatar_url), receiver:profiles!receiver_id(id, username, full_name, avatar_url)')
    .or(`sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}`)
    .order('created_at', { ascending: false });

  if (error) {
    list.innerHTML = '<div class="empty-state"><div class="empty-text">Failed to load messages.</div></div>';
    return;
  }

  if (!messages?.length) {
    list.innerHTML = '<div class="chat-empty"><div class="chat-empty-text">No messages yet.<br/>Start a conversation!</div></div>';
    return;
  }

  // Group by conversation partner
  const conversations = new Map();
  messages.forEach(msg => {
    const partnerId = msg.sender_id === currentUser.id ? msg.receiver_id : msg.sender_id;
    if (!conversations.has(partnerId)) {
      const partner = msg.sender_id === currentUser.id ? msg.receiver : msg.sender;
      conversations.set(partnerId, {
        partner,
        lastMessage: msg.content,
        lastTime: msg.created_at,
        unread: msg.sender_id !== currentUser.id && !msg.is_read
      });
    }
  });

  list.innerHTML = Array.from(conversations.entries()).map(([partnerId, conv]) => {
    const initials = (conv.partner?.username || 'U')[0].toUpperCase();
    const avatarHtml = conv.partner?.avatar_url
      ? `<img src="${conv.partner.avatar_url}" onerror="this.parentElement.textContent='${initials}'"/>`
      : initials;
    const timeAgo = getTimeAgo(conv.lastTime);

    return `
      <div class="conversation-card ${conv.unread ? 'unread' : ''}" onclick="openChat('${partnerId}')">
        <div class="avatar">${avatarHtml}</div>
        <div class="conversation-info">
          <div class="conversation-name">${conv.partner?.full_name || conv.partner?.username || 'Unknown'}</div>
          <div class="conversation-preview">${escHtml(conv.lastMessage)}</div>
        </div>
        <div class="conversation-time">${timeAgo}</div>
        ${conv.unread ? '<div class="unread-badge">•</div>' : ''}
      </div>`;
  }).join('');
}

// Open chat window with a user
async function openChat(userId) {
  activeChat = userId;

  // Get user profile
  const { data: profile } = await window.supabase.from('profiles').select('*').eq('id', userId).single();
  if (!profile) return;

  // Show chat window
  document.getElementById('conversations-view').style.display = 'none';
  document.getElementById('chat-window').style.display = 'flex';

  // Set header info
  document.getElementById('chat-user-name').textContent = profile.full_name || profile.username;
  document.getElementById('chat-user-handle').textContent = '@' + profile.username;

  const chatAvatar = document.getElementById('chat-avatar');
  if (profile.avatar_url) {
    chatAvatar.innerHTML = `<img src="${profile.avatar_url}"/>`;
  } else {
    chatAvatar.textContent = (profile.username || 'U')[0].toUpperCase();
  }

  // Load messages
  await loadMessages(userId);

  // Mark messages as read
  await window.supabase
    .from('messages')
    .update({ is_read: true })
    .eq('receiver_id', currentUser.id)
    .eq('sender_id', userId);

  // Subscribe to real-time updates for this conversation
  subscribeToMessages(userId);

  // Auto scroll to bottom
  scrollToBottom();

  // Update unread count
  updateUnreadCount();
}

// Load message history
async function loadMessages(userId) {
  const area = document.getElementById('messages-area');
  area.innerHTML = '<div class="loading"><div class="spinner"></div></div>';

  const { data: messages } = await window.supabase
    .from('messages')
    .select('*')
    .or(`and(sender_id.eq.${currentUser.id},receiver_id.eq.${userId}),and(sender_id.eq.${userId},receiver_id.eq.${currentUser.id})`)
    .order('created_at', { ascending: true });

  if (!messages?.length) {
    area.innerHTML = '<div class="chat-empty"><div class="chat-empty-text">No messages yet.<br/>Start the conversation!</div></div>';
    return;
  }

  area.innerHTML = messages.map(msg => renderMessage(msg)).join('');
}

// Render a single message
function renderMessage(msg) {
  const isSent = msg.sender_id === currentUser.id;
  const timeStr = new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  return `
    <div class="message-bubble ${isSent ? 'sent' : 'received'}">
      ${escHtml(msg.content)}
      <div class="message-time">${timeStr}</div>
    </div>`;
}

// Send a message
async function sendMessage() {
  if (!activeChat) return;

  const input = document.getElementById('chat-input');
  const content = input.value.trim();

  if (!content) return;

  const { error } = await window.supabase.from('messages').insert({
    sender_id: currentUser.id,
    receiver_id: activeChat,
    content
  });

  if (error) {
    showToast('Failed to send message', 'error');
    return;
  }

  input.value = '';
  input.style.height = 'auto';
}

// Subscribe to real-time message updates
function subscribeToMessages(userId) {
  // Unsubscribe from previous channel
  if (messageChannel) {
    window.supabase.removeChannel(messageChannel);
  }

  // Create new channel for this conversation
  messageChannel = window.supabase
    .channel(`messages:${userId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `sender_id=eq.${userId}`
      },
      (payload) => {
        // Only add if this message is for current user
        if (payload.new.receiver_id === currentUser.id) {
          appendMessage(payload.new);
          scrollToBottom();

          // Mark as read immediately
          window.supabase
            .from('messages')
            .update({ is_read: true })
            .eq('id', payload.new.id);
        }
      }
    )
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `sender_id=eq.${currentUser.id}`
      },
      (payload) => {
        // Add our own sent messages
        if (payload.new.receiver_id === userId) {
          appendMessage(payload.new);
          scrollToBottom();
        }
      }
    )
    .subscribe();
}

// Append a message to the chat
function appendMessage(msg) {
  const area = document.getElementById('messages-area');

  // Remove empty state if present
  const empty = area.querySelector('.chat-empty');
  if (empty) empty.remove();

  const loading = area.querySelector('.loading');
  if (loading) loading.remove();

  area.insertAdjacentHTML('beforeend', renderMessage(msg));
}

// Scroll chat to bottom
function scrollToBottom() {
  const area = document.getElementById('messages-area');
  setTimeout(() => {
    area.scrollTop = area.scrollHeight;
  }, 100);
}

// Back to conversations list
function backToConversations() {
  // Unsubscribe from real-time
  if (messageChannel) {
    window.supabase.removeChannel(messageChannel);
    messageChannel = null;
  }

  activeChat = null;
  document.getElementById('conversations-view').style.display = 'block';
  document.getElementById('chat-window').style.display = 'none';
  loadConversations();
}

// Handle Enter key in chat input
function handleChatKeydown(e) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    sendMessage();
  }
}

// Auto-resize textarea
function autoResizeChatInput(textarea) {
  textarea.style.height = 'auto';
  textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
}

// Update unread message count
async function updateUnreadCount() {
  const { count } = await window.supabase
    .from('messages')
    .select('*', { count: 'exact', head: true })
    .eq('receiver_id', currentUser.id)
    .eq('is_read', false);

  const badge = document.getElementById('messages-badge');
  if (count > 0) {
    if (!badge) {
      document.getElementById('nav-messages').insertAdjacentHTML('beforeend', `<span class="nav-badge" id="messages-badge">${count}</span>`);
    } else {
      badge.textContent = count;
    }
  } else {
    badge?.remove();
  }
}

// Subscribe to new messages for unread count
function subscribeToNewMessages() {
  window.supabase
    .channel('new-messages')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `receiver_id=eq.${currentUser.id}`
      },
      () => {
        updateUnreadCount();
        // Reload conversations if on messages page
        if (document.getElementById('chat-page').style.display !== 'none' &&
            document.getElementById('conversations-view').style.display !== 'none') {
          loadConversations();
        }
      }
    )
    .subscribe();
}

// Start a chat from profile page
function startChatFromProfile(userId) {
  showMessages();
  setTimeout(() => openChat(userId), 100);
}
