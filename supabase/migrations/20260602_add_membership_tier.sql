-- Add membership tier to profiles for VIP / cryptocurrency access
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS membership_tier text NOT NULL DEFAULT 'free';
