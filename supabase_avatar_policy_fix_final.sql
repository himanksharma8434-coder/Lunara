-- Drop the previous policies
DROP POLICY IF EXISTS "Users can upload their own avatars." ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars." ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars." ON storage.objects;

-- Recreate using foolproof string prefix matching and targeting only authenticated users
CREATE POLICY "Users can upload their own avatars."
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars' 
    AND name LIKE (auth.uid()::text || '/%')
  );

CREATE POLICY "Users can update their own avatars."
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars' 
    AND name LIKE (auth.uid()::text || '/%')
  );

CREATE POLICY "Users can delete their own avatars."
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars' 
    AND name LIKE (auth.uid()::text || '/%')
  );
