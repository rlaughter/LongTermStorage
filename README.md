# K-12 Records Management System

A multi-tenant document management system built for K-12 agencies and districts, featuring secure authentication, role-based access control, and document lifecycle management.

## ✅ Build Status

**Successfully built!** ✓ `npm run build` completed without errors.

## 🏗️ Technology Stack

### Frontend
- **Vue 3** - Progressive JavaScript framework
- **TypeScript** - Type-safe development
- **Pinia** - State management
- **PrimeVue** - UI component library with Lara Light Blue theme
- **Vue Router** - Client-side routing
- **Vite** - Fast build tool

### Backend
- **Supabase** - Backend-as-a-Service
  - PostgreSQL database with Row Level Security (RLS)
  - Authentication with JWT tokens
  - Storage for documents
  - Real-time subscriptions (ready to use)

## 📦 Features

### ✅ Implemented

1. **Multi-Tenant Architecture**
   - Strict tenant isolation at database level
   - Organization units (state agencies and school districts)
   - Departments and program silos
   - Row Level Security (RLS) policies enforce access control

2. **Authentication & Authorization**
   - Email/password authentication via Supabase Auth
   - JWT token-based sessions
   - Role-Based Access Control (RBAC)
   - Four role types: SYSTEM_ADMIN, DEPARTMENT_HEAD, POWER_USER, VIEWER
   - Role assignments scoped by tenant, department, and program

3. **Document Management**
   - Document upload with metadata
   - Support for PDF, DOCX, XLSX files
   - File storage in Supabase Storage
   - Document versioning support (schema ready)
   - Metadata fields: employee_id, student_id, school_year, campus, category
   - Document listing with pagination
   - Document detail view with download

4. **Search & Filtering**
   - Full-text search across filename, employee ID, student ID
   - Permission-aware search (only shows documents user has access to)
   - Program-based filtering

5. **Compliance Features**
   - Retention rules by program and category
   - Legal holds to prevent deletion
   - Audit events logging (schema ready)
   - SOC 2 and FERPA-aligned access patterns

### 🔄 Schema Ready (Not Yet Implemented in UI)

- Folder organization
- Document versioning history
- Metadata schemas (custom field definitions)
- Bulk uploads
- Audit event viewing
- Legal hold management UI

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Supabase account (database already configured)

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

The application uses Supabase environment variables:

- `VITE_SUPABASE_URL` - Your Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Your Supabase anonymous key

These are automatically injected by the environment.

### 3. Run Development Server

```bash
npm run dev
```

The application will start at http://localhost:5173

### 4. Build for Production

```bash
npm run build
```

## 📊 Database Schema

The system uses the following Supabase tables:

### Core Tables
- `tenants` - Top-level tenant isolation
- `organization_units` - State agencies and school districts (hierarchical)
- `departments` - Functional departments (HR, Federal Programs, etc.)
- `programs` - Program silos (strict access control)
- `user_profiles` - Extended user data linked to auth.users
- `roles` - Role definitions
- `user_role_assignments` - User-role-scope mappings

### Document Tables
- `documents` - Core document records
- `document_versions` - Version history
- `folders` - Optional folder structure
- `metadata_schemas` - Custom metadata definitions
- `metadata_schema_fields` - Field definitions
- `document_metadata` - Key-value metadata

### Compliance Tables
- `retention_rules` - Retention policies
- `legal_holds` - Legal hold tracking
- `audit_events` - Audit log

## 🔒 Security

### Row Level Security (RLS)

All tables have RLS policies that enforce:
- Tenant isolation - users can only access data in their tenant
- Program siloing - documents are strictly isolated by program
- Role-based permissions - actions are restricted based on user roles

### Authentication

- Passwords are hashed by Supabase Auth
- JWT tokens with automatic refresh
- Session persistence in browser
- Secure logout

### Data Protection

- All data stored in Supabase with encryption at rest
- HTTPS for all API calls
- No sensitive data in browser storage except auth tokens
- Storage files are access-controlled via Supabase Storage policies

## 📱 Application Pages

### Login (`/login`)
- Email/password authentication
- Redirects to dashboard after successful login

### Dashboard (`/`)
- Statistics overview
- Recent documents
- Quick actions (Upload, Search, View All)

### Documents (`/documents`)
- Paginated document list
- Filter by program (automatically scoped to user's access)
- View and download actions

### Upload (`/upload`)
- Single file upload
- Program selection (from user's assigned programs)
- Metadata fields: employee ID, student ID, school year, campus, category
- Direct upload to Supabase Storage

### Document Detail (`/documents/:id`)
- Document information display
- Download button
- Metadata view
- (Future: Edit metadata, view audit history)

### Search (`/search`)
- Full-text search
- Search by filename, employee ID, student ID
- Results filtered by user's program access

## 🎨 UI Components

Built with PrimeVue components:
- DataTable - for document lists with pagination
- Card - for content containers
- Button - for actions
- InputText, Password, Dropdown - for forms
- FileUpload - for document uploads
- Toast - for notifications
- Message - for inline messages
- Tag - for labels and badges

## 👥 Demo Data

The database includes demo seed data:

### Tenant
- State Education Agency (SEA-DEMO)

### Organization Units
- State Education Agency (STATE)
- Central School District (DISTRICT)
- Riverside School District (DISTRICT)
- Mountain View School District (DISTRICT)

### Departments
- Human Resources (HR)
- Federal Programs (FED-PROG)
- Special Education (SPED)
- Finance (FINANCE)

### Programs
- Human Resources Documents (HR-DOCS)
- Title I Program (TITLE-I)
- Special Education Services (SPED-SERVICES)
- Financial Records (FIN-RECORDS)

### Roles
- SYSTEM_ADMIN - Full system access
- DEPARTMENT_HEAD - Manage users and schemas within department
- POWER_USER - Same as Department Head but cannot manage users
- VIEWER - Search, view, and download documents

## 🔧 Development

### Project Structure

```
src/
├── lib/
│   └── supabase.ts          # Supabase client configuration
├── stores/
│   └── auth.store.ts        # Authentication state management
├── router/
│   └── index.ts             # Vue Router configuration
├── views/
│   ├── LoginView.vue        # Login page
│   ├── DashboardView.vue    # Dashboard
│   ├── DocumentsView.vue    # Document list
│   ├── DocumentDetailView.vue # Document details
│   ├── UploadView.vue       # Document upload
│   └── SearchView.vue       # Search page
├── App.vue                  # Root component
├── main.ts                  # Application entry point
└── index.css                # Global styles
```

### Adding a New Page

1. Create a new component in `src/views/`
2. Add route in `src/router/index.ts`
3. Add navigation link if needed
4. Add any required Pinia stores

### Database Changes

Use Supabase migrations to update the schema:

```typescript
// Access via mcp__supabase__apply_migration
```

### Storage Buckets

Documents are stored in the `documents` bucket with path structure:
```
{tenant_id}/{program_id}/{timestamp}.{extension}
```

## 📈 Future Enhancements

### Phase 2 Features
- Saved searches
- Email notifications
- File-level permission overrides
- Folder templates
- Automated purge approvals
- Bulk upload UI
- Advanced audit viewer
- Metadata schema builder UI
- Legal hold management UI
- Document preview in browser
- Text extraction and OCR integration
- Full-text search with OpenSearch/Elasticsearch

### Scalability
- Implement caching layer (Redis)
- Add CDN for static assets
- Optimize database queries with materialized views
- Implement background job processing
- Add document processing queue

## 🐛 Troubleshooting

### Build Issues

If you encounter build errors:
1. Delete `node_modules` and reinstall: `rm -rf node_modules && npm install`
2. Clear Vite cache: `rm -rf node_modules/.vite`
3. Rebuild: `npm run build`

### Authentication Issues

If login doesn't work:
1. Check Supabase environment variables are set
2. Verify Supabase project is active
3. Check browser console for errors
4. Verify user exists in database

### Permission Issues

If documents don't appear:
1. Verify user has role assignments in `user_role_assignments` table
2. Check that role has program_id assigned
3. Verify documents exist in the assigned programs
4. Check RLS policies are properly configured

## 📄 License

Proprietary - K-12 Education Agency Use Only

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Supabase documentation: https://supabase.com/docs
3. Review PrimeVue documentation: https://primevue.org/
4. Check browser console for error messages

---

**Built with ❤️ for K-12 Education**
