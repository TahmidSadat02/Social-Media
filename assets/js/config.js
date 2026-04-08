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

let supabaseClient = null;
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
    if (supabaseClient !== null) {
      console.log('Supabase already initialized');
      return;
    }

    // Create Supabase client using the global supabase object from CDN
    supabaseClient = window.supabase.createClient(url, key);
    // Also set it as global 'supabase' for other files
    window.supabase = supabaseClient;
    console.log('Supabase initialized successfully');
    document.getElementById('config-modal').style.display = 'none';
    checkSession();
  } catch(e) {
    console.error('Supabase init error:', e);
    showToast('Failed to connect to Supabase', 'error');
    // Show auth screen as fallback
    document.getElementById('auth-screen').style.display = 'flex';
  }
}

// ── INIT ──
const SUPABASE_URL = 'https://szvcogdwiaycvanebokd.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6dmNvZ2R3aWF5Y3ZhbmVib2tkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1NTU1MDYsImV4cCI6MjA5MTEzMTUwNn0.VakSgW5dYgaAV1syQYjdBCSq2SjaUBYn3EGjJOj8dtE';

// Auto-initialize on load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initApp);
} else {
  initApp();
}

function initApp() {
  // Hide config modal
  const modal = document.getElementById('config-modal');
  if (modal) modal.style.display = 'none';

  // Initialize Supabase
  initSupabase(SUPABASE_URL, SUPABASE_KEY);
}