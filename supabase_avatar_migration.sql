-- 1. Add avatar_url column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. Create the avatars storage bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Set up Storage Policies for the avatars bucket

-- Allow public access to view avatars
CREATE POLICY "Avatar images are publicly accessible."
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'avatars' );

-- Allow authenticated users to upload avatars
CREATE POLICY "Users can upload their own avatars."
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.uid() = owner
  );

-- Allow users to update their own avatars
CREATE POLICY "Users can update their own avatars."
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' 
    AND auth.uid() = owner
  );

-- Allow users to delete their own avatars
CREATE POLICY "Users can delete their own avatars."
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' 
    AND auth.uid() = owner
  );
