# Architecture Overview - TWP Coaching Website

## High-Level System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cloudflare    │    │   Vercel Edge   │    │    Supabase     │
│   CDN & WAF     │◄──►│   Next.js App   │◄──►│   PostgreSQL    │
│   (Performance) │    │   (Frontend)    │    │   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         │                        │                        │
    ┌────▼────┐              ┌────▼────┐              ┌────▼────┐
    │ Global  │              │ Sanity  │              │ Notion  │
    │ Users   │              │  CMS    │              │  CRM    │
    │(UK/US)  │              │(Content)│              │(Leads)  │
    └─────────┘              └─────────┘              └─────────┘
```

## Component Architecture

### **Frontend Layer (Next.js)**
```
src/
├── app/                    # App Router (Next.js 14)
│   ├── (marketing)/        # Marketing pages group
│   │   ├── page.tsx        # Landing page
│   │   ├── about/          # About page
│   │   ├── podcast/        # Podcast listing
│   │   └── blog/           # Blog posts
│   ├── api/                # API routes
│   │   ├── leads/          # Lead capture endpoints
│   │   ├── notion/         # Notion CRM integration
│   │   └── analytics/      # Custom analytics
│   └── studio/             # Sanity CMS Studio
├── components/             # Reusable components
│   ├── ui/                 # Shadcn/ui components
│   ├── forms/              # Lead capture forms
│   ├── cms/                # CMS-driven components
│   └── analytics/          # Tracking components
├── lib/                    # Utilities and integrations
│   ├── sanity.ts           # CMS client
│   ├── supabase.ts         # Database client
│   ├── notion.ts           # CRM integration
│   └── analytics.ts        # Custom analytics
└── types/                  # TypeScript definitions
```

### **Content Management System (Sanity)**
- **Studio Interface**: Drag-and-drop content editing at `/studio`
- **Schema Definition**: Content types for pages, posts, testimonials, podcasts
- **Media Management**: Image/video uploads with CDN integration
- **Preview Mode**: Live preview of content changes
- **Version Control**: Content versioning and rollback capabilities

### **Database Schema (Supabase)**
```sql
-- Lead Management
leads (
  id uuid PRIMARY KEY,
  email text NOT NULL,
  name text,
  message text,
  source text,
  created_at timestamp,
  notion_synced boolean DEFAULT false
);

-- Analytics (Custom Dashboard)
page_views (
  id uuid PRIMARY KEY,
  page_path text,
  user_id text,
  session_id text,
  timestamp timestamp,
  user_agent text,
  country text
);

-- Future: User Management (Client Portal)
users (
  id uuid PRIMARY KEY,
  email text UNIQUE,
  full_name text,
  avatar_url text,
  subscription_status text,
  created_at timestamp
);
```

## Data Flow Architecture

### **Lead Capture Flow**
1. **User fills form** → Frontend validation (Zod)
2. **Form submission** → Next.js API route (`/api/leads`)
3. **Data processing** → Store in Supabase + sync to Notion
4. **Notification** → Email alert to coach
5. **Analytics** → Track conversion in custom dashboard

### **Content Management Flow**
1. **Coach edits content** → Sanity Studio drag-and-drop interface
2. **Content save** → Sanity CDN + webhook to Next.js
3. **Site rebuild** → Vercel automatic deployment
4. **Cache update** → Cloudflare edge cache refresh
5. **Live site** → Updated content visible to users

### **Performance Architecture**
- **Static Generation**: Content pages pre-built at deploy time
- **Edge Caching**: Cloudflare serves static assets globally
- **Image Optimization**: Next.js Image component with WebP/AVIF
- **Code Splitting**: Dynamic imports for heavy components
- **Database Connection Pooling**: Supabase handles connection management

## Security Architecture

### **Authentication (Future Client Portal)**
- **Supabase Auth**: Email/password, social logins
- **Row Level Security**: Database-level access control
- **JWT Tokens**: Secure session management
- **Password Requirements**: Strong password enforcement

### **API Security**
- **Rate Limiting**: Prevent form spam and abuse
- **CORS Configuration**: Restrict cross-origin requests
- **Input Validation**: Server-side validation with Zod
- **Environment Variables**: Secure API key management

### **Data Protection**
- **HTTPS Enforcement**: SSL/TLS encryption
- **Database Encryption**: Supabase encryption at rest
- **GDPR Compliance**: Cookie consent and data deletion
- **Backup Strategy**: Automated daily backups

## Scalability Considerations

### **Current Scale (1K users/month)**
- **Vercel Hobby/Pro**: Handles traffic easily
- **Supabase Free/Pro**: Database suitable for lead volume
- **Sanity Free**: Content management sufficient

### **Future Scale (10K+ users/month)**
- **CDN Optimization**: Enhanced Cloudflare caching
- **Database Scaling**: Supabase horizontal scaling
- **Image Optimization**: Advanced compression strategies
- **Monitoring**: Enhanced observability and alerts

## Deployment Architecture

### **CI/CD Pipeline**
```
GitHub Repo → Vercel Build → Automatic Deployment
     ↓              ↓              ↓
Code Push     →  Build Process  →  Live Site
Sanity Webhook →  Incremental   →  Cache Refresh
     ↓           Static Regen    →  Global CDN
Database Migrations              →  Zero Downtime
```

### **Environment Management**
- **Production**: Live site with full analytics
- **Preview**: Branch deployments for testing
- **Development**: Local development with hot reload
- **CMS Studio**: Production CMS accessible at `/studio`

This architecture provides a solid foundation that can scale from 1K to 100K+ users while maintaining excellent performance and user experience.