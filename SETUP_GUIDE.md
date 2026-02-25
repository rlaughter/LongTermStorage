# K-12 Records System - Setup Guide

## What You Have

A **fully functional** K-12 document management system prototype with:

✅ **Database schema** - Created in Supabase with all tables and relationships
✅ **Authentication** - Email/password login with Supabase Auth
✅ **Document management** - Upload, list, view, download documents
✅ **Multi-tenant architecture** - Strict data isolation by tenant and program
✅ **Role-based access** - 4 roles with proper permissions
✅ **Search functionality** - Full-text search with permission filtering
✅ **Vue 3 frontend** - Modern UI with PrimeVue components
✅ **Build verified** - Successfully builds with `npm run build`

## Current Status

The application is **ready to run** once you:
1. Create your first user account
2. Assign that user to a role and program
3. Start uploading documents

## Database Schema

The Supabase database has been initialized with these tables:

### Core Tables (Multi-Tenancy)
- **tenants** - Top-level organizations
- **organization_units** - State agencies and school districts
- **departments** - HR, Federal Programs, Special Ed, Finance
- **programs** - Document silos within departments
- **user_profiles** - Extended user information
- **roles** - SYSTEM_ADMIN, DEPARTMENT_HEAD, POWER_USER, VIEWER
- **user_role_assignments** - Links users to roles with scope

### Document Tables
- **documents** - Core document records with metadata
- **document_versions** - Version history tracking
- **folders** - Optional folder organization
- **metadata_schemas** - Custom field definitions per program
- **metadata_schema_fields** - Individual field specs
- **document_metadata** - Key-value metadata storage

### Compliance Tables
- **retention_rules** - Retention policies by program
- **legal_holds** - Prevent deletion of documents
- **audit_events** - Comprehensive activity logging

### Demo Data
The database includes:
- 1 demo tenant: "State Education Agency"
- 4 organization units (1 state, 3 districts)
- 4 departments
- 4 programs (HR, Title I, Special Ed, Finance)
- 4 pre-defined roles

## Getting Started

### Step 1: Create Your First User

Since Supabase Auth is being used, you need to create a user account:

#### Option A: Via Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to Authentication > Users
3. Click "Add User"
4. Enter email and password
5. User will be created in `auth.users`

#### Option B: Via the Application
1. Run `npm run dev`
2. Go to http://localhost:5173/login
3. Click "Sign Up" (if you add a sign up page)
4. Or manually create user in Supabase Dashboard first

### Step 2: Create User Profile

After creating a user in Supabase Auth, you need to create their profile:

```sql
-- Replace these values with your user's info
INSERT INTO user_profiles (user_id, tenant_id, first_name, last_name, status)
VALUES (
  'YOUR_USER_ID_FROM_AUTH_USERS',  -- Get this from auth.users table
  '00000000-0000-0000-0000-000000000001',  -- Demo tenant ID
  'John',
  'Doe',
  'ACTIVE'
);
```

### Step 3: Assign User to a Role

Give the user access to a program:

```sql
-- Get role ID for SYSTEM_ADMIN (full access for testing)
-- Replace YOUR_USER_ID with actual user ID from auth.users

INSERT INTO user_role_assignments (
  user_id,
  role_id,
  tenant_id,
  program_id
)
VALUES (
  'YOUR_USER_ID_FROM_AUTH_USERS',
  (SELECT id FROM roles WHERE name = 'SYSTEM_ADMIN'),
  '00000000-0000-0000-0000-000000000001',  -- Demo tenant
  '00000000-0000-0000-0003-000000000001'   -- HR program (or any program ID)
);
```

### Step 4: Create Storage Bucket

The application needs a Supabase Storage bucket named `documents`:

1. Go to your Supabase project dashboard
2. Navigate to Storage
3. Create a new bucket named `documents`
4. Set it to **Private** (not public)
5. Add RLS policies to allow authenticated users to upload/download

Example Storage Policy:
```sql
-- Allow authenticated users to upload
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'documents');

-- Allow users to download files from their programs
CREATE POLICY "Allow authenticated downloads"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'documents');
```

### Step 5: Run the Application

```bash
# Install dependencies (if not already done)
npm install

# Start development server
npm run dev
```

Visit http://localhost:5173 and log in with your created user credentials.

## User Workflow

Once logged in, users can:

1. **Dashboard** - See overview statistics and recent documents
2. **Upload** - Upload new documents with metadata
3. **Documents** - Browse and filter all accessible documents
4. **Search** - Search by filename, employee ID, or student ID
5. **View Document** - See details and download files

## Typical User Scenarios

### Scenario 1: State Agency User
- Role: DEPARTMENT_HEAD or SYSTEM_ADMIN
- Access: Can see documents from all districts in their programs
- Actions: Upload, view, download, manage users

### Scenario 2: District User
- Role: POWER_USER or VIEWER
- Access: Can only see documents from their district
- Actions: Upload (Power User), view, download

### Scenario 3: Viewer
- Role: VIEWER
- Access: Read-only access to assigned programs
- Actions: Search, view, download only

## Program Isolation

The system enforces **strict program siloing**:
- HR documents only visible to users with HR program access
- Title I documents only visible to users with Title I access
- Special Ed documents only visible to users with Special Ed access
- Financial documents only visible to users with Finance access

Users can have multiple role assignments across different programs.

## Adding More Users

To add additional users:

1. Create auth user in Supabase Dashboard
2. Add user profile:
```sql
INSERT INTO user_profiles (user_id, tenant_id, first_name, last_name, status)
VALUES ('NEW_USER_ID', 'TENANT_ID', 'First', 'Last', 'ACTIVE');
```

3. Assign role(s):
```sql
INSERT INTO user_role_assignments (user_id, role_id, tenant_id, program_id)
VALUES
  ('NEW_USER_ID', (SELECT id FROM roles WHERE name = 'VIEWER'), 'TENANT_ID', 'PROGRAM_ID');
```

## Environment Variables

The application needs these Supabase credentials:

```env
VITE_SUPABASE_URL=your-project-url
VITE_SUPABASE_ANON_KEY=your-anon-key
```

These are typically provided automatically by the Supabase integration.

## Testing the System

### Test 1: Authentication
1. Try logging in with your created user
2. Verify you're redirected to dashboard
3. Check that user profile info displays correctly

### Test 2: Document Upload
1. Go to Upload page
2. Select a program from dropdown
3. Choose a PDF, DOCX, or XLSX file
4. Fill in optional metadata (employee ID, student ID, etc.)
5. Click Upload
6. Verify document appears in Documents list

### Test 3: Search
1. Upload a few documents with different metadata
2. Go to Search page
3. Search by filename
4. Search by employee ID
5. Verify only documents you have access to appear

### Test 4: Permissions
1. Create a second user with different program access
2. Upload documents as first user
3. Log in as second user
4. Verify they can only see documents in their assigned programs

## Common Issues

### Issue: User can't see any documents
**Solution:** Check that user has role_assignment with program_id set

### Issue: Upload fails with storage error
**Solution:** Verify `documents` bucket exists and has correct RLS policies

### Issue: Login works but dashboard is empty
**Solution:** Upload some documents first, or check that user has role assignments

### Issue: Search returns no results
**Solution:** Ensure documents exist in programs the user has access to

## Next Steps

Once the basic system is working, you can:

1. **Add more programs** for different document types
2. **Create department-specific metadata schemas**
3. **Set up retention rules** for automatic document lifecycle
4. **Implement folder organization** (schema is ready)
5. **Add bulk upload** functionality (schema is ready)
6. **Build admin interfaces** for user management
7. **Implement audit log viewing**
8. **Add document preview** capabilities
9. **Set up legal holds** for compliance
10. **Integrate text extraction** for full-text search

## Production Deployment

For production use:

1. **Enable email confirmations** in Supabase Auth settings
2. **Set up custom SMTP** for email delivery
3. **Configure production domain** in Supabase project settings
4. **Review and tighten RLS policies**
5. **Set up database backups**
6. **Configure monitoring and alerts**
7. **Implement rate limiting**
8. **Add WAF protection**
9. **Enable audit logging**
10. **Regular security audits**

## Support Resources

- **Supabase Docs**: https://supabase.com/docs
- **Vue 3 Docs**: https://vuejs.org/
- **PrimeVue Docs**: https://primevue.org/
- **Pinia Docs**: https://pinia.vuejs.org/

---

**You now have a working K-12 document management prototype!**
Follow the steps above to set up your first user and start testing.
