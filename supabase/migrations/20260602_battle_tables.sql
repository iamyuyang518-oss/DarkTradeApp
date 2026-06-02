-- Battle rooms table
CREATE TABLE battle_rooms (
  id               text PRIMARY KEY,
  invite_code      text UNIQUE NOT NULL,
  name             text NOT NULL,
  creator_id       uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  duration_days    int NOT NULL CHECK (duration_days IN (1, 3, 7)),
  initial_balance  float NOT NULL DEFAULT 100000,
  status           text NOT NULL DEFAULT 'waiting'
                   CHECK (status IN ('waiting', 'active', 'completed', 'cancelled')),
  started_at       timestamptz,
  ends_at          timestamptz,
  winner_id        uuid REFERENCES auth.users ON DELETE SET NULL,
  created_at       timestamptz DEFAULT now()
);

-- Battle participants table
CREATE TABLE battle_participants (
  id          text PRIMARY KEY,
  room_id     text NOT NULL REFERENCES battle_rooms ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  career_id   text NOT NULL,
  joined_at   timestamptz DEFAULT now(),
  UNIQUE (room_id, user_id)
);

-- Indexes
CREATE INDEX idx_battle_rooms_invite_code ON battle_rooms (invite_code);
CREATE INDEX idx_battle_rooms_creator_id ON battle_rooms (creator_id);
CREATE INDEX idx_battle_rooms_status ON battle_rooms (status);
CREATE INDEX idx_battle_participants_room_id ON battle_participants (room_id);
CREATE INDEX idx_battle_participants_user_id ON battle_participants (user_id);

-- RLS on battle_rooms
ALTER TABLE battle_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read battle rooms"
  ON battle_rooms FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own rooms"
  ON battle_rooms FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creator can update own rooms"
  ON battle_rooms FOR UPDATE
  USING (auth.uid() = creator_id);

-- RLS on battle_participants
ALTER TABLE battle_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read participants"
  ON battle_participants FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own participation"
  ON battle_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);
