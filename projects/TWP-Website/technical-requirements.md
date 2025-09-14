# Technical Requirements - TWP Coaching Website

## Project Overview
**Primary Goals**: Discovery call booking + authority positioning
**Target Scale**: 1K users/month initially, scalable architecture
**Performance Target**: <3 seconds load time
**Geographic Focus**: UK/US audience

## Tech Stack Recommendations

### **Frontend Framework**
- **Next.js 14+** with App Router
- **TypeScript** for type safety
- **Tailwind CSS** for styling
- **Shadcn/ui** for component library

### **CMS Solution** 
- **Sanity CMS** or **Strapi** for drag-and-drop content management
- **Rationale**: 
  - Intuitive visual editor with drag-drop functionality
  - Granular content control (pages, posts, testimonials, podcast episodes)
  - Built-in media management for images/videos
  - Page activation/deactivation controls
  - API-first architecture for future expansion

### **Database**
- **PostgreSQL** (via Supabase)
- **Rationale**: 
  - Handles CRM data, user management, analytics
  - Real-time subscriptions for live features
  - Built-in authentication and row-level security
  - Scalable for future client portal

### **Hosting & Infrastructure**
- **Vercel** for frontend deployment
- **Supabase** for database and backend services
- **Cloudflare** for CDN and performance optimization
- **Domain**: Existing Squarespace domain (DNS pointing to Vercel)

### **CRM & Lead Management**
- **Notion API** integration for lead capture
- **Custom lead capture forms** with form validation
- **Email notifications** for new leads
- **Future-ready**: Authentication system for client portal expansion

### **Analytics & Tracking**
- **Google Analytics 4** implementation
- **Custom CMS dashboard** with key metrics
- **Heat tracking preparation** (Hotjar/Microsoft Clarity)
- **Conversion tracking** for discovery call bookings

### **Payment Integration (Future-Ready)**
- **Stripe** integration prepared but not active
- **Webhook handling** for payment processing
- **Subscription management** foundation

## Development Stack

### **Core Technologies**
```yaml
Frontend: Next.js 14 + TypeScript + Tailwind CSS
CMS: Sanity Studio (drag-drop interface)
Database: PostgreSQL (Supabase)
Authentication: Supabase Auth (future client portal)
Deployment: Vercel (automatic deployments)
CDN: Cloudflare (performance optimization)
Analytics: Google Analytics 4 + custom dashboard
```

### **Key Dependencies**
- `@sanity/client` - CMS integration
- `@supabase/supabase-js` - Database and auth
- `@vercel/analytics` - Performance tracking
- `stripe` - Payment processing (prepared)
- `react-hook-form` - Form management
- `zod` - Form validation
- `framer-motion` - Animations

## Security Requirements
- **HTTPS enforcement** via Vercel/Cloudflare
- **Form validation** and sanitization
- **Rate limiting** on lead capture endpoints
- **Environment variable security** for API keys
- **GDPR compliance** preparation for UK audience

## Performance Optimization
- **Image optimization** with Next.js Image component
- **Code splitting** with dynamic imports
- **Static generation** for content pages
- **Edge functions** for API routes
- **CDN caching strategy** via Cloudflare

## Maintenance Considerations
- **Automated deployments** via Vercel GitHub integration
- **CMS-driven content** (no code changes needed)
- **Monitoring and alerting** via Vercel dashboard
- **Backup strategy** via Supabase automated backups
- **Version control** with Git for all configurations

## Budget Impact
- **Vercel Pro**: ~$20/month (for team features and analytics)
- **Supabase Pro**: ~$25/month (for database and auth)
- **Sanity**: Free tier sufficient initially (~$99/month when scaling)
- **Cloudflare**: Free tier sufficient
- **Domain**: Existing Squarespace domain
- **Total estimated**: ~$45-145/month depending on scale