# Product Requirements Document - TWP Website
**Project**: The Wisdom Practise Coaching Website  
**Primary Goals**: Discovery call bookings + Authority positioning  
**Target Audience**: Males 18-30, mobile-first (70%), "performing presence" seekers

## Executive Summary
Anti-mainstream coaching website with drag-and-drop CMS, AI-powered podcast integration, and lead qualification system. Focuses on "unlearning" approach to personal development with mobile-first, professional aesthetic.

---

## Core Features & Specifications

### **1. Landing Page Architecture**

#### **Hero Section**
- **Animated Text**: "Your best self" (static) + rotating animations:
  - "Your best self **anywhere**" (spins in)
  - "Your best self **with anyone**" (spins in)
- **Subtitle**: "You're grounded when you're alone. What if you could bring that same authentic presence to work, relationships, and any situation?"
- **Primary CTA**: "Book Discovery Call" button
- **Technical Requirements**: CSS/JS animations, mobile-optimized

#### **Pain Point Section (Self-Identification)**
- **Purpose**: Create "That's exactly me" moments using exact customer language
- **Content Structure**: 4-5 bullet points highlighting customer struggles
- **Copywriting Note**: Use customer research language, avoid jargon like "embody"
- **Status**: **[COPYWRITING DEFERRED - REVISIT IN DESIGN STAGE]**

#### **Thought Reversal Section**
- **Core Message**: "The way you've been trying to improve yourself is wrong"
- **Approach**: Challenge intellectual-only improvement methods
- **Purpose**: Aha moment to keep users scrolling
- **Status**: **[COPYWRITING DEFERRED - REVISIT IN DESIGN STAGE]**

#### **About Me Section**
- **Purpose**: Trust building through personal story
- **Content**: Founder's journey discovering "unlearning" approach
- **Style**: Professional, authentic, non-guru positioning
- **Status**: **[COPYWRITING DEFERRED - REVISIT IN DESIGN STAGE]**

#### **How It Works Section**
- **Purpose**: Explain specific methodology
- **Content**: Outline of proprietary coaching method
- **Differentiation**: Emphasize how it's different from traditional approaches
- **Status**: **[METHOD DETAILS DEFERRED - REVISIT IN DESIGN STAGE]**

#### **Lead Capture Section**
- **Placement**: End of landing page
- **Form Type**: Embedded contact form with qualification questions
- **CTA**: "Book Discovery Call" or "Contact Me"

### **2. Podcast Integration & AI Features**

#### **RSS Feed Automation**
- **Trigger**: New podcast episode detection via RSS feed
- **Automated Actions**:
  1. Create new webpage for episode
  2. Generate transcript via AI
  3. Convert transcript to blog post using AI
  4. Add to podcast index (newest episodes at top)
  5. Update sitemap and SEO

#### **AI Blog Post Generation**
- **Input**: Podcast episode transcript
- **AI Processing**: Comprehensive AI prompt for:
  - Maintain founder's voice and tonality
  - Improve readability and flow
  - Add narrative structure
  - Create demand/engagement
  - SEO optimization
  - Best practice blog formatting
- **Output**: Publication-ready blog post
- **Manual Review**: Option to edit before publishing

#### **AI Search Functionality (Phase 1)**
- **Capability**: Semantic search through podcast transcripts
- **User Experience**: Search bar returns relevant episodes
- **Results**: Episode titles, descriptions, direct links
- **Future Enhancement**: Upgrade to timestamped answers and recommendations

### **3. Lead Qualification System**

#### **Contact Form Questions**
1. **Challenge Identification**: "What's your biggest challenge with staying authentic in different situations?"
2. **Previous Attempts**: "What approaches have you tried before?"
3. **Approach Alignment**: "What draws you to this 'unlearning' approach?"

#### **CRM Integration**
- **Primary**: Notion API integration for lead management
- **Data Sync**: Automatic lead capture to Notion database
- **Notification**: Email alerts for new qualified leads
- **Lead Scoring**: Based on qualification responses

### **4. Content Management System**

#### **Drag-and-Drop Interface Requirements**
- **Page Management**:
  - Create/edit/delete pages
  - Activate/deactivate pages
  - Page templates and layouts
  - SEO meta data management

- **Content Blocks**:
  - Headers and hero sections
  - Text content with rich formatting
  - Image/video uploads and management
  - Call-to-action buttons
  - Contact forms
  - Testimonial sections

- **Blog Management**:
  - Rich text editor
  - Image/media insertion
  - Category/tag management
  - Publishing schedule
  - SEO optimization fields

- **Podcast Management**:
  - Episode descriptions and show notes
  - Category management
  - Episode activation/deactivation
  - Transcript management
  - Audio file linking

- **Media Management**:
  - Image/video upload
  - File organization
  - Compression and optimization
  - CDN integration

#### **Future Architecture (Not Implemented Initially)**
- **Resources/Downloads**: Lead magnets, guides, worksheets
- **Client Portal**: Login system, progress tracking, resources
- **Course Materials**: Video lessons, assignments, progress tracking

### **5. Analytics & Tracking**

#### **Google Analytics 4**
- **Conversion Tracking**: Discovery call bookings, form submissions
- **User Journey**: Landing page → podcast → contact
- **Content Performance**: Blog posts, podcast episodes
- **Mobile vs Desktop**: Usage patterns and performance

#### **Custom CMS Dashboard**
- **Lead Metrics**: Conversion rates, qualification scores
- **Content Performance**: Page views, engagement time
- **Podcast Analytics**: Episode popularity, search queries
- **Technical Performance**: Page load times, uptime

#### **Competitive Advantage Features (Based on Market Research)**
- **Authenticity Assessment Tool**: Custom quiz measuring "performing vs authentic presence" 
- **AI Daily Check-ins**: 24/7 presence coaching support (competitive advantage over human-only)
- **Advanced Podcast Analytics**: User engagement insights for content optimization

### **Future Enhancements**
- **Heat Tracking**: User behavior analysis (Hotjar/Clarity)
- **A/B Testing**: Landing page optimization
- **Advanced Attribution**: Multi-touch conversion tracking

---

## User Flows & Site Structure

### **Primary User Flow (Discovery Call Journey)**
```
Landing Page → Pain Point Recognition → Thought Reversal → About Me → 
How It Works → Contact Form → Qualification → Discovery Call Booking
```

### **Content Consumption Flow**
```
Landing Page → Podcast Section → Episode Selection → Blog Post → 
AI Search → Related Episodes → Contact Form
```

### **Site Structure (First Iteration)**
```
Homepage (/)
├── About (/about)
├── Podcast (/podcast)
│   ├── Episode Pages (/podcast/episode-title)
│   └── Search Functionality
├── Blog (/blog)
│   └── Individual Posts (/blog/post-title)
├── Contact (/contact)
└── CMS Studio (/studio) - Admin only
```

### **Mobile-First Navigation**
- **Primary Menu**: Home, Podcast, About, Contact
- **Mobile Menu**: Hamburger with full-screen overlay
- **Sticky Elements**: Contact CTA, search bar
- **Touch Targets**: 44px minimum for all interactive elements

---

## Technical Specifications

### **Performance Requirements**
- **Load Time**: <3 seconds globally
- **Mobile Performance**: 90+ Lighthouse score
- **SEO Performance**: 95+ Lighthouse score
- **Core Web Vitals**: LCP <2.5s, FID <100ms, CLS <0.1

### **SEO Requirements**
- **Schema Markup**: Podcast episodes, blog posts, organization
- **Meta Management**: Dynamic titles, descriptions, OG tags
- **Sitemap**: Auto-generated with new content
- **Internal Linking**: Related episodes, blog cross-references
- **Mobile-First Indexing**: Responsive design priority

### **Security & Compliance**
- **HTTPS**: SSL/TLS encryption
- **Form Security**: CSRF protection, input validation
- **GDPR Preparation**: Cookie consent, data handling
- **Rate Limiting**: Anti-spam measures

---

## Acceptance Criteria

### **Content Management (Complex Feature)**
**Success Metrics**:
- ✅ Non-technical user can create new pages in <5 minutes
- ✅ Drag-and-drop interface works on mobile devices
- ✅ Content changes reflect live within 30 seconds
- ✅ Media uploads process automatically (compression, optimization)
- ✅ SEO fields auto-populate with suggestions

### **AI Blog Generation (Complex Feature)**
**Success Metrics**:
- ✅ Transcript → blog post conversion in <2 minutes
- ✅ Generated content maintains founder's voice (manual review confirms)
- ✅ SEO optimization included (meta tags, headings, keywords)
- ✅ Blog posts require minimal manual editing (<20% changes)
- ✅ Integration with podcast pages seamless

### **Lead Qualification (Complex Feature)**
**Success Metrics**:
- ✅ Form submission → Notion sync in <30 seconds
- ✅ Qualification scoring algorithm categorizes leads accurately
- ✅ Email notifications trigger immediately
- ✅ Mobile form completion rate >60%
- ✅ Form abandonment rate <30%

### **AI Search (Complex Feature)**
**Success Metrics**:
- ✅ Search results return in <2 seconds
- ✅ Semantic search accuracy >80% relevance
- ✅ Mobile search interface intuitive
- ✅ Search queries logged for improvement
- ✅ Integration with podcast index seamless

---

## Future Feature Architecture

### **Phase 2 Enhancements (6-12 months)**
- **AI Presence Coach (24/7)**: Trained on TWP methodology, $29/month premium tier
- **Authenticity Assessment Integration**: Personalized coaching paths based on assessment results
- **Community Challenge Platform**: Group accountability with individual AI support
- **Advanced AI Search**: Timestamped answers, episode recommendations
- **Client Portal**: Authentication, progress tracking, resource access
- **Resource Downloads**: Lead magnets, worksheets, guides
- **Payment Integration**: Stripe for program/course sales

### **Phase 3 Scalability (12+ months)**
- **Course Platform**: Video lessons, assignments, community
- **Mobile App**: Native iOS/Android with offline content
- **Advanced Automation**: Email sequences, lead nurturing
- **Community Features**: Forums, peer connections, group coaching

---

## Dependencies & Constraints

### **External Dependencies**
- **Podcast RSS Feed**: Must be reliable and consistent
- **Notion API**: For CRM integration functionality
- **AI Services**: OpenAI/Claude for transcript processing
- **Squarespace Domain**: DNS configuration required

### **Content Dependencies**
- **Podcast Episodes**: Regular content creation required
- **Blog Templates**: AI prompt development needed  
- **Qualification Framework**: Lead scoring algorithm development
- **Brand Assets**: Logo, images, brand guidelines

### **Technical Constraints**
- **Mobile-First**: 70% of users on mobile devices
- **Performance Budget**: <3 second load time requirement
- **SEO Priority**: Search visibility crucial for discovery
- **Maintenance**: Single-person management requirement

---

**Status**: **READY FOR STAGE 3A DESIGN DISCOVERY**  
**Confidence Level**: 95% - Core features enhanced with competitive advantage insights  
**Next Steps**: Design requirements discovery and visual direction establishment

## Research-Based Feature Enhancements

### **Market Differentiation Opportunities Identified**
1. **Age Demographic Gap**: TWP targets underserved 18-30 male market (competitors focus 40+)
2. **Technology Leadership**: Modern Next.js stack vs competitors' outdated WordPress
3. **Anti-Performance Positioning**: "Unlearning" approach unique in market
4. **AI Integration**: 24/7 coaching support vs human-only competitor offerings

### **Competitive Advantage Features Added**
- **Authenticity Assessment**: Unique "performing vs authentic presence" measurement tool
- **AI Daily Coach**: $29/month tier undercutting market leader by 70% ($99/month)
- **Podcast-Native Platform**: Content-first approach vs add-on podcast strategy
- **Mobile-First Architecture**: 70% mobile traffic requires superior mobile experience

**COPYWRITING TASKS DEFERRED**:
- [ ] Pain point section customer language implementation
- [ ] Thought reversal messaging development  
- [ ] About me section content creation
- [ ] How it works method explanation
- [ ] CTA and button copy optimization

**TECHNICAL DETAILS DEFERRED**:
- [ ] AI prompt engineering for blog generation
- [ ] Specific method explanation for "How It Works"
- [ ] Advanced search functionality specifications