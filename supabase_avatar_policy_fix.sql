-- Drop the existing flawed policies
DROP POLICY IF EXISTS "Users can upload their own avatars." ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars." ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars." ON storage.objects;

-- Recreate them with the proper path-based checks (verifying the folder matches the user ID)
CREATE POLICY "Users can upload their own avatars."
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' 
    AND (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update their own avatars."
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' 
    AND (auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own avatars."
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' 
    AND (auth.uid())::text = (storage.foldername(name))[1]
  );
