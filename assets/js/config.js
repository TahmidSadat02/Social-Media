const SQL_SETUP = `-- Run this in Supabase SQL Editor

-- Profiles table
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  full_name text,
  avatar_url text,
  bio text,
  created_at timestamptz default now()
);

-- Posts table
create table if not exists posts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade not null,
  content text not null,
  image_url text,
  created_at timestamptz default now()
);

-- Likes table
create table if not exists likes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade not null,
  post_id uuid references posts(id) on delete cascade not null,
  unique(user_id, post_id)
);

-- Follows table
create table if not exists follows (
  id uuid default gen_random_uuid() primary key,
  follower_id uuid references profiles(id) on delete cascade not null,
  following_id uuid references profiles(id) on delete cascade not null,
  unique(follower_id, following_id)
);

-- Enable RLS
alter table profiles enable row level security;
alter table posts enable row level security;
alter table likes enable row level security;
alter table follows enable row level security;

-- RLS Policies
create policy "Public profiles" on profiles for select using (true);
create policy "Users update own profile" on profiles for update using (auth.uid() = id);
create policy "Users insert own profile" on profiles for insert with check (auth.uid() = id);
create policy "Public posts" on posts for select using (true);
create policy "Users insert posts" on posts for insert with check (auth.uid() = user_id);
create policy "Users delete own posts" on posts for delete using (auth.uid() = user_id);
create policy "Public likes" on likes for select using (true);
create policy "Users manage likes" on likes for all using (auth.uid() = user_id);
create policy "Public follows" on follows for select using (true);
create policy "Users manage follows" on follows for all using (auth.uid() = follower_id);`;

let supabase = null;
let currentUser = null;
let currentProfile = null;
let viewingProfileId = null;

// ── CONFIG ──
function saveConfig() {
  const url = document.getElementById('sb-url').value.trim();
  const key = document.getElementById('sb-key').value.trim();
  if (!url || !key) { showToast('Enter both URL and Key', 'error'); return; }
  localStorage.setItem('sb_url', url);
  localStorage.setItem('sb_key', key);
  initSupabase(url, key);
}

function initSupabase(url, key) {
  try {
    supabase = window.supabase.createClient(url, key);
    document.getElementById('config-modal').style.display = 'none';
    checkSession();
  } catch(e) {
    showToast('Invalid credentials', 'error');
  }
}

// ── INIT ──
window.onload = () => {
  const sqlDisplay = document.getElementById('sql-display');
  if (sqlDisplay) sqlDisplay.textContent = SQL_SETUP;
  
  const url = localStorage.getItem('sb_url');
  const key = localStorage.getItem('sb_key');
  if (url && key) {
    const sbUrlEl = document.getElementById('sb-url');
    const sbKeyEl = document.getElementById('sb-key');
    if (sbUrlEl) sbUrlEl.value = url;
    if (sbKeyEl) sbKeyEl.value = key;
    initSupabase(url, key);
  } else {
    document.getElementById('config-modal').style.display = 'flex';
  }
};
