-- Drop old profiles table (no real users yet)
DROP TABLE IF EXISTS profiles CASCADE;

-- Recreate with new schema
CREATE TABLE profiles (
  id                    uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  username              text UNIQUE NOT NULL,
  display_name          text,
  security_question     text NOT NULL,
  security_answer_hash  text NOT NULL,
  created_at            timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can manage their own profile
CREATE POLICY "Users can manage own profile"
  ON profiles FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Anyone can read profiles for password recovery (username → security_question)
CREATE POLICY "Public can read profiles for recovery"
  ON profiles FOR SELECT
  USING (true);
