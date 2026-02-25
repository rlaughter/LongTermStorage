/*
  # Create Storage Bucket for Documents

  ## Overview
  Sets up the storage infrastructure for document uploads with proper Row Level Security policies.

  ## Changes Made

  ### 1. Storage Bucket
  - Creates a 'documents' bucket for storing all document files
  - Public bucket set to false (requires authentication)
  - File size limit: 50MB per file
  - Allowed MIME types: PDF, images, Microsoft Office documents

  ### 2. Storage Policies
  Creates RLS policies on storage.objects to control access:

  #### Upload Policy
  - Users can upload files to their tenant's folder
  - Path structure: {tenant_id}/{program_id}/{filename}
  - Must be authenticated
  - Must have access to the program (via user_role_assignments)

  #### Read/Download Policy
  - Users can view/download files from programs they have access to
  - Checks user_role_assignments to verify program access

  #### Update Policy
  - Users can update file metadata for files in their accessible programs
  - Typically used for renaming or updating metadata

  #### Delete Policy
  - Users can delete files from programs they have access to
  - Checks user_role_assignments for program membership

  ## Security Notes
  - All policies require authentication
  - Access is restricted by tenant_id and program_id
  - Users can only access files from programs they're assigned to
  - Path-based security ensures files are organized by tenant and program
*/

-- Create the documents bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents',
  'documents',
  false,
  52428800, -- 50MB in bytes
  ARRAY[
    'application/pdf',
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
    'text/csv'
  ]
)
ON CONFLICT (id) DO NOTHING;

-- Policy: Users can upload files to programs they have access to
CREATE POLICY "Users can upload documents to accessible programs"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] IN (
    SELECT DISTINCT up.tenant_id::text
    FROM user_profiles up
    WHERE up.user_id = auth.uid()
  )
  AND (storage.foldername(name))[2] IN (
    SELECT DISTINCT ura.program_id::text
    FROM user_role_assignments ura
    WHERE ura.user_id = auth.uid()
  )
);

-- Policy: Users can view/download files from programs they have access to
CREATE POLICY "Users can view documents from accessible programs"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] IN (
    SELECT DISTINCT up.tenant_id::text
    FROM user_profiles up
    WHERE up.user_id = auth.uid()
  )
  AND (storage.foldername(name))[2] IN (
    SELECT DISTINCT ura.program_id::text
    FROM user_role_assignments ura
    WHERE ura.user_id = auth.uid()
  )
);

-- Policy: Users can update files in programs they have access to
CREATE POLICY "Users can update documents in accessible programs"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] IN (
    SELECT DISTINCT up.tenant_id::text
    FROM user_profiles up
    WHERE up.user_id = auth.uid()
  )
  AND (storage.foldername(name))[2] IN (
    SELECT DISTINCT ura.program_id::text
    FROM user_role_assignments ura
    WHERE ura.user_id = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] IN (
    SELECT DISTINCT up.tenant_id::text
    FROM user_profiles up
    WHERE up.user_id = auth.uid()
  )
  AND (storage.foldername(name))[2] IN (
    SELECT DISTINCT ura.program_id::text
    FROM user_role_assignments ura
    WHERE ura.user_id = auth.uid()
  )
);

-- Policy: Users can delete files from programs they have access to
CREATE POLICY "Users can delete documents from accessible programs"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] IN (
    SELECT DISTINCT up.tenant_id::text
    FROM user_profiles up
    WHERE up.user_id = auth.uid()
  )
  AND (storage.foldername(name))[2] IN (
    SELECT DISTINCT ura.program_id::text
    FROM user_role_assignments ura
    WHERE ura.user_id = auth.uid()
  )
);
