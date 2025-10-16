# Comprehensive YouTube Software & Workflow Analysis

**Date**: 2025-01-15
**Purpose**: Complete analysis of all YouTube transcripts to identify software, workflows, and proven methodologies
**Videos Analyzed**: 7 total (all recent 2024-2025)

---

## EXECUTIVE SUMMARY

### **Critical Software Identified**

| Software | Native Code Link | Visual Display | Purpose | Priority |
|----------|-----------------|----------------|---------|----------|
| **Playwright MCP** | ✅ YES | ✅ Screenshot | Agentic visual validation loop | **HIGH** |
| **Web2MCP** | ✅ YES | ✅ Capture live sites | 1:1 component cloning from web | **HIGH** |
| **SuperDesign.dev** | ✅ YES | ✅ Canvas preview | Design iteration with rules | **HIGH** |
| **Storybook** | ✅ YES | ✅ Component explorer | Development with HMR | **HIGH** |
| **v0.dev** | ✅ YES | ✅ Split pane | Rapid prototyping | MEDIUM |
| **Mobbin** | ❌ NO | ✅ Inspiration | UI pattern research | MEDIUM |
| **.agent folder** | ✅ YES | ❌ Text files | Documentation system | **HIGH** |
| **TweakCN** | ✅ YES | ✅ Preview | Theme variants | MEDIUM |
| **Aceternity UI** | ✅ YES | ✅ Registry | Animated components | MEDIUM |

---

## NEW CRITICAL DISCOVERY: PLAYWRIGHT MCP

### **What It Is** (Video: Patrick Ellis - "Turn Claude Code into Your Own INCREDIBLE UI Designer")

> "Give Claude 'eyes' with Playwright MCP to run an agentic visual loop—implement, screenshot, compare to spec, fix, repeat."

**Why This Changes Everything**:
- **Agentic Visual Validation Loop**: Claude can **see** what it builds
- **Automated QA**: Screenshot → Compare to spec → Generate fix → Repeat
- **Pixel Accuracy**: Visual intelligence (not just code heuristics)

---

### **Playwright MCP Capabilities**

**From Transcript**:
```
- Automated screenshots (full page, element-level)
- Console/network log access (catch errors)
- Device/viewport emulation (mobile, tablet, desktop)
- DOM interactions (click, type, navigate)
- Coordinate-based "vision mode" (visual grounding)
- Headless/headed modes
```

**Native Code Link**: ✅ YES
- Playwright runs **in your project** (not external tool)
- Screenshots are **of your actual code** (not mockups)
- Logs reference **your actual files** (line numbers, errors)

**Visual Display**: ✅ YES (Screenshots)
- Captures what user sees (rendered output)
- Shows all viewports (mobile, tablet, desktop)
- Console logs, network errors visible

---

### **Agentic Visual Loop Workflow**

**From Transcript** (Patrick Ellis):
```
Step 1: Implement
  → Claude generates component code

Step 2: Screenshot
  → Playwright captures rendered output
  → Multiple viewports (mobile/desktop)

Step 3: Compare to Spec
  → Claude "sees" screenshot (multimodal vision)
  → Compares to:
    - Design mockup
    - Style guide
    - Acceptance criteria
    - Design principles

Step 4: Identify Issues
  → Visual: "Button is 2px too small"
  → Functional: "Console error: image preload failed"
  → Accessibility: "Missing alt text"
  → Performance: "Network request blocking render"

Step 5: Generate Fix
  → Claude writes patch based on visual analysis

Step 6: Repeat
  → Loop until spec match achieved
```

**Why This is Revolutionary**:
- **Autonomous refinement**: Claude doesn't need you to say "make it bigger"
- **Pixel-perfect**: Visual comparison catches what code review misses
- **Multi-modal**: Text (code) + Vision (screenshots) = better results

---

### **Playwright MCP Implementation in Forge**

**Recommended Integration**:

```bash
# Phase 3: UI Implementation with Visual Validation

forge setup-ui
  → Installs Storybook
  → Installs Playwright MCP
  → Configures claude.md with visual development rules

forge generate-component Button --validate
  ↓
1. Claude generates button.tsx
2. Storybook renders component (localhost:6006)
3. Playwright screenshots component
4. Claude compares to design mockup
5. If mismatch:
   → Claude identifies issue: "Border radius is 4px, spec says 8px"
   → Claude patches code
   → Repeat steps 2-5
6. If match:
   → Component approved ✅
   → Move to next component

forge validate-all
  → Runs Playwright on all components
  → Screenshots each state (default/hover/disabled/error)
  → Compares to approved baselines
  → Generates issue report with screenshots
```

**claude.md Configuration** (from transcript):
```markdown
## Visual Development Protocol

When implementing UI components:

1. **Always launch Playwright** for visual validation
2. **Routes to test**: /storybook/button, /storybook/card, /storybook/form
3. **Viewports**: Mobile (375px), Tablet (768px), Desktop (1920px)
4. **Acceptance Criteria**:
   - Match design mockup (pixel-perfect within 2px tolerance)
   - No console errors
   - Images preload correctly
   - Accessibility: keyboard navigation, screen reader labels
   - Responsive: all breakpoints render correctly
5. **Context References**:
   - context/style-guide.md
   - context/design-principles.md
   - design/mockups/*.png
```

---

### **"Design Reviewer" Sub-Agent** (from transcript)

**Persona**: Principal Designer with 10 years experience

**Workflow**:
```
forge review-design --pr=<PR_NUMBER>
  ↓
1. Navigate to Storybook (localhost:6006)
2. Screenshot all components
3. Check:
   - Visual fidelity (vs mockups)
   - Code health (console errors, network issues)
   - Accessibility (keyboard nav, ARIA labels, contrast)
   - Responsiveness (mobile/tablet/desktop)
4. Generate graded report:
   - Issues found (with screenshots)
   - Severity (critical/high/medium/low)
   - Suggested fixes (code patches)
5. Optionally auto-apply fixes and re-validate
```

**Output Example** (from transcript):
```markdown
## Design Review Report

**Component**: Button
**Grade**: B+ (85/100)

### Issues Found

1. **Image Preload Warning** (Medium)
   - Screenshot: button-desktop.png
   - Issue: Missing preload for icon
   - Fix: Add `<link rel="preload" as="image" href="/icon.svg">`

2. **Border Radius Mismatch** (High)
   - Screenshot: button-comparison.png
   - Issue: Current 4px, spec requires 8px
   - Fix: Change `rounded-sm` to `rounded-md`

3. **Missing Alt Text** (Critical)
   - Screenshot: button-accessibility.png
   - Issue: Icon has no accessible label
   - Fix: Add `aria-label="Submit form"`

### Recommendations
- Apply fixes and re-run validation
- Consider adding hover state screenshot to baseline
```

**Why This is Crucial**:
- **Autonomous QA**: No manual checking needed
- **Screenshots prove issues**: Not just text descriptions
- **Actionable fixes**: Code patches, not vague suggestions

---

## NEW DISCOVERY: WEB2MCP + SUPERDESIGN

### **Web2MCP** (Video: AI LABS - "The PERFECT Design Workflow")

**What It Is**:
> "Web2MCP extension captures any web component and sends assets + reference ID to the agent"

**How It Works**:
```
1. Browse any website (e.g., Stripe.com)
2. Hover over component (button, card, nav)
3. Web2MCP highlights component (overlay)
4. Click "Send to Claude"
5. Claude receives:
   - Screenshot of component
   - HTML structure
   - CSS styles
   - Assets (images, icons)
   - Reference ID for follow-up
6. Claude generates matching component in your project
```

**Native Code Link**: ✅ YES
- Captured component → Claude generates code → Your codebase
- No manual "design to code" translation

**Visual Display**: ✅ YES
- Hover overlay shows capture boundary
- Screenshot shows exact visual to replicate
- SuperDesign.dev shows generated result

**Pricing**: Paid with generous free tier (better fidelity than OSS MCP Pointer)

---

### **SuperDesign.dev** (Design Canvas for Claude Code)

**What It Is**:
> "SuperDesign.dev initializes rules (claude.md/Cursor/Windsurf); tune rules for exact cloning"

**Purpose**:
- **Visual canvas** for Claude-generated components
- **Rule system** to control output (e.g., "clone UI, not app icons")
- **Iteration playground** for design refinement

**Key Rules** (from transcript):
```markdown
## SuperDesign Rules (claude.md)

When cloning components:
- Clone UI structure and styles 1:1
- Do NOT replace app-specific icons with generic icons
- Do NOT use emoji fallbacks for missing icons
- Do use exact colors, spacing, border radius from source
- Do preserve responsive breakpoints

When generating new components:
- Inspired by captured component (not 1:1 copy)
- Use design system tokens (colors, spacing)
- Generate variations (dropdowns, nav, dashboards)
```

**Workflow**:
```
1. Capture component with Web2MCP (Stripe button)
2. Send to Claude Code
3. Claude generates code
4. SuperDesign canvas shows rendered result
5. User: "Make it larger, change color to primary"
6. Claude updates code
7. SuperDesign canvas updates
8. Export to project
```

**Why This is Crucial**:
- **Exact cloning**: 1:1 fidelity from live sites
- **Visual iteration**: See changes in canvas (not just text)
- **Unique inspirations**: Avoid "ShadCN sameness" by cloning diverse sources

---

## ENHANCED WORKFLOW: 3-STEP DESIGN SYSTEM

### **Video: Sean Kochel - "3-Step Claude Code System For Pro-Level App Designs"**

**Commands** (custom Claude Code commands):

#### **Step 1: `/extract it`** (Mine Inspiration)

**Purpose**: Turn inspiration screenshots into structured design principles

**Input**: 10 reference screens from Mobbin (Airbnb, Blackbird, etc.)

**Output**: Competitor analysis markdown per app
```markdown
## Airbnb Analysis

**Palette**: Warm (Rausch pink #FF5A5F, Babu blue #00A699, neutrals)
**Typography**: Circular font family, bold headings, generous spacing
**Components**: Card-based layout, full-bleed images, minimal borders
**UX Psychology**: Trust signals (verified badges), social proof (reviews), scarcity (limited availability)
**Philosophy**: Warmth + clarity; community-driven; wanderlust emotion
```

**Why "Pondering Tags"**: Meta-analysis of **why** UI feels a certain way (not just **what** it looks like)

---

#### **Step 2: `/expand it`** (Deepen Principles)

**Purpose**: Transform analysis into implementation guide

**Input**: Competitor analysis markdown

**Output**: `styles.mmarkdown` (comprehensive philosophy + how-to)
```markdown
# Design System Philosophy

## Color Psychology
- **Warm tones** create approachability (Airbnb pink)
- **Cool tones** imply trust/security (Blackbird blue)
- Use semantic colors for status (green=success, red=error)

## Implementation Tactics
- Shadow depth: 3 levels (subtle/card/modal)
- Border radius: Consistent 8px for cards, 4px for buttons
- Spacing: 8px grid system (8, 16, 24, 32, 48)
- Typography hierarchy: 32px/24px/18px/16px/14px

## Component Patterns
- Cards: white bg, 8px radius, Level 2 shadow, 16px padding
- Buttons: primary (bold bg), secondary (outline), tertiary (text-only)
- Forms: outlined inputs, focus state with primary color ring
```

---

#### **Step 3: `/merge it`** (Fuse to Your App)

**Purpose**: Transform generic principles into your app's tokenized design system

**Input**:
- `styles.mmarkdown` (expanded principles)
- Your PRD (app requirements)
- Your IA (sitemap, flows)
- Your audience (demographics, preferences)

**Output**: App-specific design system + implementation guide
```markdown
# Fitness Tracker Design System

## Brand Personality
- Energetic but not overwhelming (Airbnb warmth + Blackbird clarity)
- Professional yet approachable (trust signals without corporate coldness)
- Motivational without being preachy (subtle encouragement)

## Color Palette (Tokenized)
- Primary: #3B82F6 (Blue - Energy, trust)
- Secondary: #10B981 (Green - Health, growth)
- Accent: #F59E0B (Amber - Achievement, motivation)
- Neutrals: #1F2937, #6B7280, #F3F4F6, #FFFFFF

## Tailwind Config
```js
module.exports = {
  theme: {
    colors: {
      primary: '#3B82F6',
      secondary: '#10B981',
      accent: '#F59E0B',
      gray: { 900: '#1F2937', 600: '#6B7280', 100: '#F3F4F6' }
    }
  }
}
```

**Why This is Crucial**:
- **Tokenized**: Design decisions → Code values (automated sync)
- **Psychology-aware**: Not just colors, but **why** those colors
- **Implementation-ready**: Direct Tailwind config export

---

#### **Step 4: `/design it`** (Generate Variants)

**Purpose**: Create multiple screen variations and states

**Input**: Design system + screen name (e.g., "Dashboard")

**Output**: Multiple design variants + state variations
```
Dashboard Variants:
1. Light theme, card-based, sidebar nav
2. Dark theme, list-based, top nav
3. Light theme, table-based, no nav (focus mode)

State Variations (per variant):
- Default: Fully loaded with data
- Empty: "No workouts logged yet"
- Loading: Skeleton screens
- Error: "Network error, retry"
- Success: "Workout saved!" toast
- Paywall: "Unlock premium for AI coach"
```

**Example from Transcript** (Nano Banana app):
> "Showed several empty/processing/limit-reached screens, discussed tradeoffs (e.g., dark paywall variant didn't fit the product's warm tone)."

**Why Multiple States**:
- **Polish**: Covers edge cases (empty, error) users will actually see
- **Iteration**: Choose best variant before coding
- **Realistic**: Not just "happy path" mockups

---

## VISUAL PRINCIPLES (AI LABS Video)

### **Video: "Claude Code Can Finally Make Beautiful Websites"**

**Three Core Principles** to avoid "LLM gradient spam":

#### **1. Shadows (Depth System)**

**Problem**: LLM-generated UIs are often flat and boring

**Solution**: Layer 3-4 neutral shades to imply elevation

**Technique**:
- **Dual shadows**: Light top, dark bottom (realistic light source)
- **Subtle gradients**: Dark surfaces get more gradient than light
- **3 elevation levels**:
  - Level 1 (subtle): `0 1px 3px rgba(0,0,0,0.1)` (hover states)
  - Level 2 (cards): `0 4px 6px rgba(0,0,0,0.1)` (content cards)
  - Level 3 (modals): `0 10px 25px rgba(0,0,0,0.15)` (popups, dropdowns)

**Why Borders are Often Unnecessary**:
- Shadows provide separation without harsh lines
- Cleaner, more modern aesthetic

**Implementation Prompt** (from video resources):
```
"Apply a layered neutral palette with 3-4 shades of gray.
Add dual shadows (lighter top, darker bottom) to cards.
Use subtle gradients on dark surfaces.
Reduce border usage—shadows provide separation."
```

---

#### **2. Responsiveness (Layout as Nested Boxes)**

**Problem**: LLM shrinks everything on mobile (unreadable)

**Solution**: Treat layout as flexible parent/child boxes; reorder by priority

**Techniques**:
- **Fix structural issues first**: Broken overflow, misaligned grids
- **Carousels preserve proportions**: Cards maintain size, scroll horizontally
- **Mobile reorders by priority**: Important content first, decorative elements hidden
- **Don't shrink, rearrange**: 48px button stays 48px, just stacks vertically

**Example** (Airbnb clone from video):
```
Desktop:
┌──────────────────────────────────────┐
│  Logo   Search   Nav   Profile       │  ← All horizontal
├──────────────────────────────────────┤
│  [Card] [Card] [Card] [Card]         │  ← 4 columns
└──────────────────────────────────────┘

Mobile:
┌──────────┐
│  Logo    │  ← Priority 1
│  Search  │  ← Priority 2 (most important action)
│  Nav     │  ← Priority 3 (hamburger menu)
│  Profile │  ← Priority 4 (icon only)
├──────────┤
│  [Card]  │  ← Carousel (horizontal scroll)
│  [Card]  │  ← Cards maintain proportions
└──────────┘
```

**Implementation Prompt**:
```
"On mobile, reorder elements by user priority (search first, decorative images last).
Use carousels to preserve card proportions.
Don't shrink buttons—stack them vertically instead.
Fix overflow and broken grid structure before resizing."
```

---

#### **3. Color Systems (Intentional Usage)**

**Problem**: LLM overuses saturated colors everywhere

**Solution**: Primary (attention), Secondary (support), Neutral (majority), Semantic (status)

**Color Roles**:
- **Primary** (10% usage): CTAs, attention (e.g., "Sign Up" button)
- **Secondary** (15% usage): Supporting actions (e.g., "Learn More" link)
- **Neutral** (70% usage): Black, white, gray (backgrounds, text, borders)
- **Semantic** (5% usage): Status colors (green=success, yellow=warning, blue=info, red=error)

**Palette Resource** (from video):
- Site: "Colors" (palette browser)
- Choose: 1 primary, 1 secondary, 4-5 neutrals, 4 semantic

**Implementation Prompt**:
```
"Use primary color (#3B82F6) only for CTAs and important actions.
Secondary color (#8B5CF6) for supportive elements.
Neutrals (#1F2937, #6B7280, #F3F4F6, #FFF) for 70% of surface.
Semantic colors only for status (green=success, red=error)."
```

---

## STYLE GUIDE FIRST WORKFLOW

### **Video: Developers Digest - "Create Beautiful UI with Claude Code"**

**Core Insight**:
> "Codify a style guide as the single source of truth; build reusable components; reference guide in every prompt."

**Why This Works**:
- **Consistency**: All components use same colors, spacing, typography
- **Readability**: Test dark/light contexts early (catch contrast issues)
- **Reusability**: Build once (Button, Input, Card), use everywhere
- **Token-efficient**: Style guide is ~4.5k tokens (small enough to @mention)

---

### **Workflow**

#### **Step 1: Generate Style Guide**

**Initial Spec**:
```
"Create a dark theme with light accents.
Primary: Blue/purple gradient.
No linear gradients (only subtle radial on hero).
Thin fonts (readable weight/contrast).
Both light and dark variants."
```

**Output**: `style-guide.md` or `/style-guide` page
```markdown
# Style Guide

## Colors
- **Dark Mode**:
  - Background: #0A0A0A
  - Surface: #1A1A1A
  - Text: #FFFFFF (primary), #A0A0A0 (secondary)
  - Primary: #3B82F6
  - Accent: #8B5CF6

- **Light Mode**:
  - Background: #FFFFFF
  - Surface: #F3F4F6
  - Text: #1F2937 (primary), #6B7280 (secondary)
  - Primary: #3B82F6
  - Accent: #8B5CF6

## Typography
- Headings: 32px/24px/18px, font-weight: 600
- Body: 16px, font-weight: 400, line-height: 1.6
- Captions: 14px, font-weight: 500

## Spacing
- xs: 4px, sm: 8px, md: 16px, lg: 24px, xl: 32px, 2xl: 48px

## Components
- Buttons: Primary (filled), Secondary (outline), Tertiary (text-only)
- Inputs: Outlined, focus ring in primary color
- Cards: 8px radius, Level 2 shadow, 16px padding
```

---

#### **Step 2: Build Reusable Components**

**Examples**: Primary/secondary buttons, inputs, dropdowns, tables, tiles

**Iteration Focus**:
- **Contrast**: Thin fonts need higher contrast (test both dark/light)
- **Readability**: Ensure text is legible in all contexts
- **Consistency**: All buttons use same padding, radius, shadow

**Output**: `components/ui/` directory
```
components/ui/
├── button.tsx (primary, secondary, tertiary variants)
├── input.tsx (outlined, focus state)
├── card.tsx (white/dark bg, shadow, padding)
├── dropdown.tsx (menu, select)
└── table.tsx (rows, headers, sorting)
```

---

#### **Step 3: Create Dedicated Style Guide Page**

**Purpose**: Reference in prompts without using full context

**Location**: `/style-guide` route

**Why Separate Page**:
- **Token efficiency**: ~4.5k tokens (small)
- **Easy to @mention**: "Use @/style-guide for colors and spacing"
- **Visual reference**: Developers see all components in one view

---

#### **Step 4: Enforce Rules in claude.md**

**Example Rules**:
```markdown
## UI Generation Rules

1. **Always reference /style-guide** for colors, typography, spacing
2. **No emojis in UI** (unless explicitly requested)
3. **No gradients** except subtle radial on hero
4. **Test both light and dark modes** for every component
5. **Maintain contrast ratios**: WCAG AA minimum (4.5:1 text, 3:1 UI)
```

**Result**: Claude auto-applies rules without prompting

---

#### **Step 5: Generate Pages Referencing Guide**

**Prompt**:
```
"Create a landing page using components from /style-guide.
Use primary button for CTA, secondary for 'Learn More'.
Hero section with subtle radial gradient.
3 feature cards with Level 2 shadow.
Dark mode by default."
```

**Output**: Consistent page using guide components

---

### **Animations (Intentional Use)**

**Library**: Framer Motion

**Example** (fade-in hero):
```tsx
import { motion } from 'framer-motion';

<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.6 }}
>
  <h1>Welcome to Fitness Tracker</h1>
</motion.div>
```

**Why Intentional**:
- Add motion to hero (draws attention)
- Subtle transitions on cards (hover states)
- Don't overdo: Animation should enhance, not distract

---

## .AGENT FOLDER SYSTEM (CRITICAL FOR SCALE)

### **Video: AI Jason - ".agent folder is making claude code 10x better…"**

**Core Insight**:
> "Context engineering + lightweight documentation system to boost reliability and reduce token waste."

**Why It Matters**:
- **Token management**: /context shows usage; remove unused MCPs; keep claude.md lean
- **Offload research**: Subagents summarize, run /compact after tasks
- **Predictability**: Docs increase stability as codebase grows

---

### **Folder Structure**

```
.agent/
├── README.md                     # Index ("read this first")
├── tasks/                        # PRDs + approved implementation plans
│   ├── text-to-image-integration.md
│   ├── text-to-video-integration.md
│   └── user-authentication.md
├── system/                       # Project structure, DB schema, APIs
│   ├── project-architecture.md
│   ├── database-schema.md
│   ├── api-endpoints.md
│   └── complex-modules/
│       ├── ai-coach.md
│       └── workout-tracking.md
└── sops/                         # Standard Operating Procedures
    ├── replicate-integration.md  # How to integrate Replicate API
    ├── firebase-setup.md
    └── common-mistakes.md
```

---

### **Workflow**

#### **Initialize**
```bash
/update-doc initialize
  ↓
Generates:
- .agent/README.md (project overview)
- .agent/system/project-architecture.md
```

---

#### **Plan Feature**
```bash
User: "Add AI workout suggestions using Replicate"

Claude (plan mode):
1. Research Replicate API
2. Design integration (async jobs, streaming)
3. Save plan to .agent/tasks/ai-workout-suggestions.md
4. User approves plan
5. Implement
```

---

#### **Generate SOP After Tricky Integration**

**Example** (Replicate integration from transcript):
```bash
User: "This Replicate integration was complex, save it as SOP"

Claude:
  → Creates .agent/sops/replicate-integration.md

Content:
- API setup (key management, endpoints)
- Async job polling (check status every 2s)
- Error handling (timeout, rate limits)
- Common mistakes (forgetting to poll, wrong model ID)
```

---

#### **Reuse SOP for Similar Feature**

**Example** (text-to-video from transcript):
```bash
User: "Add text-to-video using Replicate"

Claude:
1. Reads .agent/sops/replicate-integration.md
2. Reuses pattern (async jobs, polling, error handling)
3. Adapts for video model (different endpoints)
4. Implements in 50% less time (no re-learning)
```

---

### **Rules in claude.md**

```markdown
## Documentation Protocol

Before implementing any feature:
1. **Read .agent/README.md** for project overview
2. **Check .agent/system/** for relevant architecture docs
3. **Check .agent/sops/** for similar patterns
4. **Update docs** after implementation

After solving complex issues:
1. **Create SOP** in .agent/sops/
2. **Link related docs** in SOP
3. **Update .agent/README.md** with SOP reference
```

**Result**: Claude learns from past work, doesn't repeat mistakes

---

### **Example: Replicate SOP** (from transcript)

```markdown
# Replicate API Integration SOP

## Setup
1. Get API key from Replicate dashboard
2. Add to .env.local: `REPLICATE_API_KEY=r8_...`
3. Install SDK: `npm install replicate`

## Pattern
```tsx
import Replicate from 'replicate';

const replicate = new Replicate({ auth: process.env.REPLICATE_API_KEY });

// Start prediction
const prediction = await replicate.predictions.create({
  version: "model-version-id",
  input: { prompt: "user prompt" }
});

// Poll for completion
while (prediction.status !== 'succeeded') {
  await new Promise(resolve => setTimeout(resolve, 2000));
  prediction = await replicate.predictions.get(prediction.id);

  if (prediction.status === 'failed') {
    throw new Error(prediction.error);
  }
}

// Get result
const output = prediction.output;
```

## Common Mistakes
- Forgetting to poll (prediction doesn't auto-update)
- Wrong model version ID (check Replicate docs)
- Not handling timeouts (add max poll count)
- Exposing API key in client code (use server-side only)

## Related Docs
- .agent/system/api-endpoints.md (RESTful patterns)
- .agent/tasks/text-to-image-integration.md (first Replicate integration)
```

---

## COMPLETE END-TO-END WORKFLOW

### **Video: Riley Brown - "The Complete Claude Code Workflow (to Build Anything)"**

**Purpose**: Install → Research → Build → Deploy full-stack app

**Tech Stack**:
- **Claude Code**: Everything agent (terminal-based)
- **Whisper Flow**: Voice-to-text (faster interaction)
- **Obsidian**: Visual note store (synced with Claude file ops)
- **GitHub**: Source of truth
- **Vercel**: Deployment
- **Next.js**: App framework
- **Firebase**: Auth (Google) + Firestore (database)
- **OpenAI API**: AI chat (gated behind sign-in)

---

### **Phase 1: Content System**

**Workflow**:
```
1. Create folders: ideas/ examples/ drafts/
2. Add README with instructions
3. Move into Obsidian (visual notes)
4. Use web clippings (research → save to Obsidian)
5. Generate outlines/scripts from clippings + examples
```

**Output**: Long-form content (blog posts, video scripts)

---

### **Phase 2: Landing Page**

**Workflow**:
```
1. Build minimalist doc-style page
2. Add animated underlines (Framer Motion)
3. Run locally: npm run dev
4. Push to GitHub
5. Deploy to Vercel
6. Tweak content, push again (auto-redeploys)
```

**Output**: Live landing page (public URL)

---

### **Phase 3: App with Auth + DB + AI**

**Workflow**:
```
1. Convert static to Next.js
2. Set up Firebase project:
   - Enable Google provider (Auth)
   - Firestore in test mode (develop phase)
3. Add .env.local:
   - Firebase keys
   - OpenAI API key
4. Implement features:
   - Comments/likes (Firestore CRUD)
   - Google sign-in (Firebase Auth)
   - AI chat page (OpenAI API, gated behind auth)
5. Test locally
6. Push to GitHub
7. Deploy to Vercel
8. Add custom domain (Vercel settings)
```

**Output**: Full-stack app with auth, database, AI features

---

### **Security Notes** (from transcript):

**Do**:
- Use sign-in gating for premium features (AI chat)
- Keep secrets in .env.local (never commit)
- Switch Firestore from test mode to production rules before launch

**Don't**:
- Run `claude -dangerously-skip-permissions` (risky)
- Rely long-term on test mode Firestore (no security rules)

---

## SHADCN REGISTRY ENHANCEMENTS

### **Video: AI LABS - "ShadCN Dropped Something to FINALLY Fix Your UI"**

**New Feature**: Official ShadCN Registry MCP

**What It Enables**:
- Multi-registry component search (ShadCN + Aceternity UI + Origin UI + TweakCN)
- Agent installs correct code + usage patterns
- Curated component selection (not generic)

---

### **Setup**

```bash
# 1. Install ShadCN in React/Next app
npx shadcn-ui@latest init

# 2. Add to components.json
{
  "registries": [
    "https://ui.shadcn.com/r",           # Official ShadCN
    "https://aceternity.com/r",         # Animated components
    "https://originui.com/r",           # Modern components
    "https://tweakcn.com/r"             # Theme variants
  ]
}

# 3. Launch Claude Code (do NOT skip permissions)
claude

# 4. Verify MCP detected
mcp tools
  → Should show: shadcn_search, shadcn_install, etc.
```

---

### **Registries**

**ShadCN (Official)**:
- Core components (button, card, form, table)
- Accessibility-first (Radix UI primitives)
- Production-ready

**Aceternity UI**:
- Animated components (hover effects, transitions)
- Modern, flashy aesthetics
- Good for landing pages, not dashboards

**Origin UI**:
- Modern variants (elevated cards, gradient buttons)
- Clean, minimal
- Good for SaaS apps

**TweakCN**:
- Theme variants (paste theme code, Claude implements)
- Quick aesthetic changes
- Good for rapid prototyping

---

### **4-Subagent Workflow** (from transcript)

**Avoids over-installation and animation bloat**

```
1. Requirements Agent
   → Reads PRD + IA
   → Creates requirements.md
   → Creates design-docs/<task>/

2. Component Research Agent
   → Searches ShadCN registries
   → Creates "component research" file:
     - Button: ShadCN default + Aceternity hover animation
     - Card: Origin UI elevated variant
     - Form: ShadCN with custom focus styles
   → Links to visual examples

3. Implementation Agent
   → Installs researched components only
   → Structured layout (no bloat)

4. Express Agent
   → Small, focused tweaks
   → No full context overhead
```

**Why This Works**:
- **Pre-research**: Know which components before installing
- **Curated**: Only components that fit design system
- **Structured**: Plan prevents agent from "install everything animated"

---

### **TweakCN Themes**

**Usage**:
```
1. Browse themes on tweakcn.com
2. Copy theme code (CSS variables + Tailwind config)
3. Paste into Claude:
   "Apply this TweakCN theme to the project"
4. Claude updates:
   - tailwind.config.js
   - globals.css (CSS variables)
5. Storybook auto-reloads (HMR)
6. All components now use new theme
```

**Why This is Powerful**:
- **Instant aesthetic change**: Swap theme in 30 seconds
- **No manual refactoring**: CSS variables handle everything
- **Proven themes**: Curated by TweakCN (not AI-generated)

---

## ORCHESTRATION LAYER (PLAYWRIGHT + CONTEXT + VALIDATION)

### **Key Insight** (Patrick Ellis video):

> "Orchestration layer: combine tools (Playwright), context (style guide, docs), and validation (acceptance criteria, specs) for predictable outputs."

**Components**:

### **1. Tools (Playwright MCP)**
- Screenshots (visual feedback)
- Console logs (error detection)
- Network logs (performance)
- DOM interactions (functional testing)

### **2. Context (Documentation)**
- `.agent/system/` (project architecture)
- `context/style-guide.md` (design rules)
- `context/design-principles.md` (visual philosophy)
- `design/mockups/*.png` (target visuals)

### **3. Validation (Acceptance Criteria)**
- Pixel accuracy (within 2px tolerance)
- No console errors
- Images preload correctly
- Accessibility (keyboard nav, ARIA labels, contrast)
- Responsiveness (mobile/tablet/desktop)

---

### **Agentic Loop Benefits**

**Traditional**: Developer codes → Manually tests → Finds issue → Codes fix → Repeat

**Agentic**: Claude codes → Playwright screenshots → Claude compares to spec → Claude fixes → Repeat **autonomously**

**Time Saved**:
- Manual QA: 2-4 hours per feature
- Agentic QA: 5-10 minutes per feature (autonomous)
- **Result**: 10-50x faster iteration

**Quality Improvement**:
- Manual: Miss visual inconsistencies (hard to spot 2px differences)
- Agentic: Pixel-perfect comparison (computer vision catches everything)

---

## RECOMMENDED FORGE WORKFLOW (COMPREHENSIVE)

### **Phase 1: PRD Creation** (Existing)
```bash
forge import
  → Custom GPT generates PRD
  → 95% confidence validated
```

---

### **Phase 2: IA Design** (Existing)
```bash
forge import-ia
  → Custom GPT generates sitemap, flows, navigation
  → 80% confidence validated
```

---

### **Phase 2.5: Visual Design** (NEW - Enhanced with YouTube Insights)

```bash
# Step 1: Aesthetic Brief
forge design-brief
  → User provides vague aesthetic ("energetic, clean, bold")
  → Output: design/aesthetic-brief.md

# Step 2: Mine Inspiration (Mobbin)
forge mine-inspiration
  → AI searches Mobbin for 10 reference screens
  → Downloads: Airbnb (warm), Blackbird (simple), Stripe (professional)
  → Output: design/inspiration/*.png

# Step 3: Extract Principles (/extract it)
forge extract-principles
  → AI analyzes inspiration screenshots
  → Extracts: colors, typography, shadows, UX psychology
  → Output: design/competitor-analysis.md (with "pondering tags")

# Step 4: Expand Philosophy (/expand it)
forge expand-philosophy
  → AI deepens principles into implementation guide
  → Output: design/styles.mmarkdown (philosophy + how-to)

# Step 5: Merge to App (/merge it)
forge create-design-system
  → Merges: styles.mmarkdown + PRD + IA + aesthetic-brief
  → Output: design/design-system.md (tokenized, app-specific)
  → Auto-generates: tailwind.config.js

# Step 6: Generate Mockup Variants (/design it)
forge generate-mockup --variants
  → AI generates 3 visual variants per screen
  → AI generates 6 states per variant (default/empty/loading/error/success/paywall)
  → Output: design/mockups/<screen>/<variant>/<state>.png

# Step 7: Clone Reference Components (Web2MCP)
forge clone-component --url=<live-site-url>
  → Open Web2MCP browser extension
  → Hover over component (e.g., Stripe button)
  → Send to Claude
  → Claude generates matching component
  → Output: components/ui/<component>.tsx

# Step 8: Research ShadCN Components
forge research-components
  → AI searches ShadCN registries (Aceternity, Origin, TweakCN)
  → Maps design system to components
  → Output: design/component-research.md

# Step 9: Apply Theme (TweakCN)
forge apply-theme --source=tweakcn
  → User selects theme from TweakCN
  → AI applies CSS variables + Tailwind config
  → Output: Updated tailwind.config.js, globals.css

# Step 10: Visual Validation (Playwright MCP)
forge validate-design
  → Playwright screenshots mockups
  → AI compares mockups to design system
  → Output: design/validation-report.md (issues + screenshots)
```

**User Approval Checkpoint**: ✅ Design system, mockups, component research finalized

---

### **Phase 3: UI Implementation** (NEW - Enhanced with Agentic Loop)

```bash
# Setup
forge setup-ui
  → Installs: Next.js, Storybook, Playwright MCP
  → Imports design system to Tailwind
  → Installs researched ShadCN components
  → Configures claude.md with visual development rules
  → Initializes .agent/ folder system

# Generate Component with Agentic Validation
forge generate-component Button --validate
  ↓
Agentic Loop:
1. Claude generates button.tsx
2. Storybook renders (localhost:6006)
3. Playwright screenshots (mobile/tablet/desktop)
4. Claude compares to design/mockups/button.png
5. If mismatch:
   → Claude identifies: "Border radius 4px, spec says 8px"
   → Claude patches code
   → Repeat steps 2-5
6. If match:
   → Component approved ✅
   → Capture baseline screenshot
   → Create .agent/sops/button-implementation.md

# Preview All Components
forge preview
  → Terminal 1: npm run dev (Next.js)
  → Terminal 2: npm run storybook (localhost:6006)
  → Shows all components, all states (default/hover/disabled/error)

# Design Review (Playwright MCP + Sub-Agent)
forge review-design
  → "Design Reviewer" sub-agent runs
  → Screenshots all components
  → Checks: visual fidelity, accessibility, responsiveness, console errors
  → Output: design-review-report.md (graded, with screenshots)
  → Optionally: Auto-apply fixes and re-validate

# Visual Regression Tests
forge snapshot
  → Playwright captures baseline screenshots
  → Stores in .playwright/screenshots/

forge validate-ui
  → Playwright compares current UI to baselines
  → Shows diff images if changes detected
  → Blocks if unapproved changes

# Build Pages (Referencing Style Guide)
forge generate-page Login
  → Claude reads:
    - design/design-system.md
    - design/mockups/login/*.png
    - .agent/system/project-architecture.md
  → Generates page using researched components
  → Storybook shows live preview
  → Playwright validates vs mockup
```

---

### **Phase 4: Deployment** (Enhanced from Riley Brown workflow)

```bash
# Local Testing
npm run dev  # Test locally
npm run build  # Verify build succeeds
npm run test  # Run all tests (Playwright visual regression)

# GitHub
git add .
git commit -m "Implement UI with visual validation"
git push

# Vercel (Auto-Deploy)
  → Vercel detects push
  → Runs build
  → Runs visual regression tests (CI)
  → If pass: Deploys ✅
  → If fail: Blocks deployment, shows diff screenshots ❌

# Custom Domain
  → Add in Vercel settings
```

---

## KEY TAKEAWAYS FOR FORGE

### **1. Playwright MCP is Game-Changing**

**Why**:
- **Agentic visual validation**: Claude can **see** and **fix** autonomously
- **Pixel-perfect accuracy**: Computer vision catches what humans miss
- **Autonomous QA**: 10-50x faster than manual testing

**Implementation Priority**: **HIGH**

---

### **2. Web2MCP + SuperDesign for Exact Cloning**

**Why**:
- **1:1 fidelity**: Clone any live site component
- **Unique inspirations**: Avoid "ShadCN sameness"
- **Visual iteration**: SuperDesign canvas shows changes

**Implementation Priority**: **HIGH** (if budget allows - paid tool)

---

### **3. 3-Step Design System is Proven**

**Why**:
- **Psychology-aware**: Not just colors, but **why** those colors
- **Tokenized**: Automated sync (design decisions → code values)
- **Multiple states**: Covers edge cases (empty, error, loading)

**Commands**: `/extract it`, `/expand it`, `/merge it`, `/design it`

**Implementation Priority**: **HIGH**

---

### **4. .agent Folder System is Critical for Scale**

**Why**:
- **Context management**: Token-efficient, organized docs
- **Learning from past**: SOPs prevent repeating mistakes
- **Predictability**: Increases reliability as codebase grows

**Structure**: `tasks/`, `system/`, `sops/`, `README.md`

**Implementation Priority**: **HIGH**

---

### **5. Visual Principles Elevate Quality**

**Why**:
- **Depth system**: 3 shadow levels (subtle/card/modal)
- **Responsive**: Reorder by priority, don't shrink
- **Color systems**: Primary (10%), Secondary (15%), Neutral (70%), Semantic (5%)

**Implementation Priority**: MEDIUM (codify in design system generation)

---

### **6. Style Guide First Prevents Chaos**

**Why**:
- **Single source of truth**: Consistency across all components
- **Token-efficient**: ~4.5k tokens (small enough to @mention)
- **Enforced via claude.md**: Rules prevent drift

**Implementation Priority**: **HIGH**

---

## FINAL FORGE WORKFLOW (COMPLETE)

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: PRD (Custom GPT)                                   │
│ forge import → prd.md (95% confidence)                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: IA (Custom GPT)                                    │
│ forge import-ia → ia/*.md (80% confidence)                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2.5: Visual Design (NEW - 3-Step + Web2MCP)          │
│                                                             │
│ 1. forge design-brief (vague aesthetic input)              │
│ 2. forge mine-inspiration (Mobbin - 10 screens)            │
│ 3. forge extract-principles (/extract it)                  │
│ 4. forge expand-philosophy (/expand it)                    │
│ 5. forge create-design-system (/merge it)                  │
│ 6. forge generate-mockup --variants (/design it)           │
│ 7. forge clone-component (Web2MCP - live site)             │
│ 8. forge research-components (ShadCN registries)           │
│ 9. forge apply-theme (TweakCN)                             │
│ 10. forge validate-design (Playwright screenshots)         │
│                                                             │
│ Output: design-system.md, mockups/*.png, tokens config     │
│ User Approval: ✅                                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: UI Implementation (Agentic Loop)                   │
│                                                             │
│ 1. forge setup-ui (Storybook + Playwright MCP + .agent/)   │
│ 2. forge generate-component --validate (agentic loop)      │
│    - Generate code                                          │
│    - Playwright screenshot                                  │
│    - Compare to mockup                                      │
│    - Auto-fix if mismatch                                   │
│    - Repeat until pixel-perfect                             │
│ 3. forge preview (Storybook + HMR - 76ms updates)          │
│ 4. forge review-design (Design Reviewer sub-agent)         │
│    - Screenshot all components                              │
│    - Check accessibility, responsiveness, errors            │
│    - Generate graded report                                 │
│    - Optionally auto-fix issues                             │
│ 5. forge snapshot (baseline screenshots)                   │
│ 6. forge validate-ui (visual regression tests)             │
│                                                             │
│ Components: ✅ Pixel-perfect, accessible, tested            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 4: Deployment (Vercel + Visual Tests CI)             │
│                                                             │
│ 1. git push → GitHub                                        │
│ 2. Vercel auto-deploy                                       │
│ 3. CI runs: forge validate-ui (Playwright)                 │
│ 4. If pass → Deploy ✅                                      │
│    If fail → Block, show diff screenshots ❌                │
│ 5. Add custom domain                                        │
│                                                             │
│ Production: ✅ Live app with guaranteed visual fidelity     │
└─────────────────────────────────────────────────────────────┘
```

---

## SOFTWARE SUMMARY TABLE

| Software | Native Link | Visual Display | Purpose | Priority | Cost |
|----------|-------------|----------------|---------|----------|------|
| **Playwright MCP** | ✅ YES | ✅ Screenshots | Agentic visual validation | **CRITICAL** | Free |
| **Web2MCP** | ✅ YES | ✅ Live capture | 1:1 component cloning | **HIGH** | Paid |
| **SuperDesign.dev** | ✅ YES | ✅ Canvas | Design iteration | **HIGH** | Free tier |
| **Storybook** | ✅ YES | ✅ Explorer | Dev with HMR (76ms) | **CRITICAL** | Free |
| **ShadCN MCP** | ✅ YES | ✅ Registry | Component research | **CRITICAL** | Free |
| **Mobbin** | ❌ NO | ✅ Inspiration | UI pattern research | **HIGH** | Paid |
| **.agent folder** | ✅ YES | ❌ Docs | Context management | **CRITICAL** | Free |
| **TweakCN** | ✅ YES | ✅ Themes | Instant aesthetic swap | MEDIUM | Free |
| **Aceternity UI** | ✅ YES | ✅ Registry | Animated components | MEDIUM | Free |
| **Origin UI** | ✅ YES | ✅ Registry | Modern components | MEDIUM | Free |
| **v0.dev** | ✅ YES | ✅ Split pane | Rapid prototyping | MEDIUM | Freemium |
| **Framer Motion** | ✅ YES | ✅ Animations | Declarative animations | MEDIUM | Free |
| **Firebase** | ✅ YES | ❌ Backend | Auth + Database | MEDIUM | Freemium |
| **Vercel** | ✅ YES | ✅ Deployment | Auto-deploy + CI | **HIGH** | Free tier |
| **Obsidian** | ⚠️ Partial | ✅ Notes | Visual note-taking | LOW | Free |
| **Whisper Flow** | ❌ NO | ❌ Voice | Voice-to-text input | LOW | Paid |

---

## NEXT STEPS

**Immediate**: Implement Playwright MCP + .agent folder system (foundation for agentic loop)

**Short-term**: Implement 3-step design system commands (`/extract it`, `/expand it`, `/merge it`, `/design it`)

**Medium-term**: Add Web2MCP + SuperDesign integration (if budget allows)

**Long-term**: Full agentic visual validation pipeline (autonomous QA)

---

**All research consolidated in `research/` folder per your request.**
