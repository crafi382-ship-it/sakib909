-- ChatApp Supabase Setup SQL
-- Run this in your Supabase SQL Editor

-- 1. Users table
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL,
  phone_number TEXT,
  profile_image TEXT,
  user_chat_code TEXT NOT NULL UNIQUE,
  is_online BOOLEAN DEFAULT FALSE,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  onesignal_player_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Chat rooms
CREATE TABLE IF NOT EXISTS public.chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1 UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user2 UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  last_message TEXT,
  last_message_type TEXT DEFAULT 'text',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user1, user2)
);

-- 3. Messages
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  chat_room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
  message TEXT NOT NULL DEFAULT '',
  message_type TEXT DEFAULT 'text',
  file_url TEXT,
  file_name TEXT,
  is_seen BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  is_deleted_for_everyone BOOLEAN DEFAULT FALSE,
  reply_to_message_id UUID,
  reply_to_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Typing status
CREATE TABLE IF NOT EXISTS public.typing_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(chat_room_id, user_id)
);

-- 5. User chat settings
CREATE TABLE IF NOT EXISTS public.user_chat_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  is_muted BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(chat_room_id, user_id)
);

-- 6. User status (WhatsApp-style stories)
CREATE TABLE IF NOT EXISTS public.user_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT,
  image_url TEXT,
  type TEXT DEFAULT 'text',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours')
);

-- 7. Status views
CREATE TABLE IF NOT EXISTS public.status_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status_id UUID NOT NULL REFERENCES public.user_status(id) ON DELETE CASCADE,
  viewer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  viewed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(status_id, viewer_id)
);

-- ===================== Row Level Security =====================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.typing_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_chat_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles" ON public.users FOR SELECT USING (TRUE);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view their chat rooms" ON public.chat_rooms FOR SELECT USING (auth.uid() = user1 OR auth.uid() = user2);
CREATE POLICY "Users can create chat rooms" ON public.chat_rooms FOR INSERT WITH CHECK (auth.uid() = user1 OR auth.uid() = user2);
CREATE POLICY "Users can update their chat rooms" ON public.chat_rooms FOR UPDATE USING (auth.uid() = user1 OR auth.uid() = user2);

CREATE POLICY "Users can view messages in their rooms" ON public.chats FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users can send messages" ON public.chats FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users can update their messages" ON public.chats FOR UPDATE USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can view typing" ON public.typing_status FOR SELECT USING (TRUE);
CREATE POLICY "Users can update own typing" ON public.typing_status FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage own settings" ON public.user_chat_settings FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view all statuses" ON public.user_status FOR SELECT USING (TRUE);
CREATE POLICY "Users can create own status" ON public.user_status FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own status" ON public.user_status FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view status views" ON public.status_views FOR SELECT USING (TRUE);
CREATE POLICY "Users can insert views" ON public.status_views FOR INSERT WITH CHECK (auth.uid() = viewer_id);

-- ===================== Realtime =====================
ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;
ALTER PUBLICATION supabase_realtime ADD TABLE public.typing_status;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_rooms;

-- ===================== Indexes =====================
CREATE INDEX IF NOT EXISTS idx_chats_room ON public.chats(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_chats_sender ON public.chats(sender_id);
CREATE INDEX IF NOT EXISTS idx_chats_receiver ON public.chats(receiver_id);
CREATE INDEX IF NOT EXISTS idx_chats_created ON public.chats(created_at);
CREATE INDEX IF NOT EXISTS idx_rooms_user1 ON public.chat_rooms(user1);
CREATE INDEX IF NOT EXISTS idx_rooms_user2 ON public.chat_rooms(user2);
CREATE INDEX IF NOT EXISTS idx_rooms_updated ON public.chat_rooms(updated_at);
CREATE INDEX IF NOT EXISTS idx_users_chat_code ON public.users(user_chat_code);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone_number);
