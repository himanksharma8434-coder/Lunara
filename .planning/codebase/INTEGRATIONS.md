# External Integrations

**Analysis Date:** 2026-03-25

## APIs & External Services

**Backend as a Service:**
- Supabase - Authentication, Database, and Realtime sync
  - SDK/Client: `supabase_flutter` v2.8+
  - Auth: Supabase Anon Key / Service Role Key
  - Endpoints used: Auth, PostgREST, Realtime

**AI & ML:**
- Google Gemini AI - Generative AI features
  - SDK/Client: `google_generative_ai` v0.4+
  - Auth: API key (likely in `.env` or app config)
  - Models: Gemini Pro / Flash

**Health Data:**
- Apple Health / Google Fit - Wearable and health data integration
  - SDK/Client: `health` package v11.0+
  - Auth: Platform-specific permissions
  - Data: Steps, cycles, activity (implied)

## Data Storage

**Databases:**
- PostgreSQL on Supabase - Primary cloud data store
  - Connection: via Supabase client and `pg` (backend)
  - Client: Sequelize ORM (backend)
  - Migrations: `sequelize-cli` Managed

**Local Storage:**
- Hive - NoSQL local storage for Flutter
  - Purpose: Persistence of local state and caching
  - Client: `hive` and `hive_flutter`

**File Storage:**
- Supabase Storage (Implied) - User uploads/avatars
  - SDK/Client: `supabase_flutter`

## Authentication & Identity

**Auth Provider:**
- Supabase Auth - OAuth and Email/Password
  - Implementation: `supabase_flutter` on frontend
  - Token storage: Secure local storage (Flutter)
  - Session management: JWT based

## Monitoring & Observability

**Logs:**
- Standard output - Node.js/Flutter logs
- Supabase dashboard - Database and Auth logs

## CI/CD & Deployment

**Hosting:**
- Likely standard cloud providers (Supabase for backend services)
- Version Control: GitHub (`himanksharma8434-coder/Lunara`)

## Environment Configuration

**Development:**
- Required env vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GEMINI_API_KEY`
- Backend specific: `DATABASE_URL`, `JWT_SECRET`

**Production:**
- Secrets management: Managed by hosting platform or `.env` in production environments
