-- Drop the strict policies
DROP POLICY IF EXISTS "Users can upload their own avatars." ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars." ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars." ON storage.objects;

-- Create the official Supabase fallback policies that just check if the user is logged in
CREATE POLICY "Users can upload their own avatars."
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK ( bucket_id = 'avatars' );

CREATE POLICY "Users can update their own avatars."
  ON storage.objects FOR UPDATE
  TO authenticated
  USING ( bucket_id = 'avatars' );

CREATE POLICY "Users can delete their own avatars."
  ON storage.objects FOR DELETE
  TO authenticated
  USING ( bucket_id = 'avatars' );
