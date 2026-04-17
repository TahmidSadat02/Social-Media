-- PixoGram Messages Table
-- Run this SQL in your Supabase dashboard to create the messages table

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for faster queries
CREATE INDEX messages_sender_id_idx ON messages(sender_id);
CREATE INDEX messages_receiver_id_idx ON messages(receiver_id);
CREATE INDEX messages_conversation_idx ON messages(sender_id, receiver_id, created_at);

-- Enable RLS (Row Level Security)
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Create policies to allow users to only see their own messages
CREATE POLICY "Users can view their own messages"
  ON messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert messages"
  ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their received messages"
  ON messages FOR UPDATE
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);
