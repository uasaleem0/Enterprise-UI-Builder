# Final Workflow Recommendation: Visual-First with Objective Validation

**Date**: 2025-01-15
**Based on**: Complete research analysis (UI workflows, YouTube transcripts, proven methodologies)

---

## EXECUTIVE SUMMARY

**Your Critical Insight**:
> "Playwright is helpful for objective comparables (component, inspiration image). But for subjective changes ('make it more modern'), you still need to interpret what I mean."

**The Solution**: **SuperDesign + Storybook + Playwright** working together
- **SuperDesign**: Visual iteration with subjective input ("make it modern")
- **Storybook**: Component development with instant feedback
- **Playwright**: Objective validation (mockup match, accessibility, no regressions)

---

## THE PROBLEM WITH SUBJECTIVE ITERATION

### **Scenario 1: Subjective Prompt (Doesn't Work Well)**

```
User: "Make the button more modern"

Claude's Challenge:
  - What does "modern" mean?
  - Flat design? Glassmorphism? Neumorphism?
  - Rounded or sharp corners?
  - Bold or subtle shadows?
  - Gradient or solid color?

Without objective reference:
  ❌ Claude guesses
  ❌ 50% chance it matches your vision
  ❌ Multiple iterations wasted
```

### **Scenario 2: Objective Reference (Works Perfectly)**

```
User: "Make the button match this Stripe button"
[Provides screenshot or Web2MCP capture]

Claude's Task:
  ✅ Extract exact values:
     - Border radius: 6px
     - Padding: 12px 24px
     - Font size: 14px
     - Shadow: 0 2px 4px rgba(0,0,0,0.1)
     - Color: #635BFF (Stripe purple)
  ✅ Implement exactly
  ✅ Playwright validates pixel-perfect match
```

**The Difference**: Objective reference eliminates guesswork

---

## STORYBOOK: WHAT IT IS & WHY IT'S CRITICAL

### **What Storybook Is**

**Simple Definition**: Component explorer with live preview

**Technical Definition**:
> "Storybook is a frontend workshop for building UI components in isolation. It runs alongside your app in development, showing all components in all states."

**Visual Representation**:
```
Browser: localhost:6006 (Storybook)

┌────────────────────────────────────────────────┐
│  Sidebar              │  Preview Panel         │
├───────────────────────┼────────────────────────┤
│  📁 Components        │                        │
│    ├─ Button          │  ┌──────────┐          │
│    │  ├─ Default      │  │ Click Me │ ← Live  │
│    │  ├─ Hover        │  └──────────┘          │
│    │  ├─ Disabled     │                        │
│    │  └─ Loading      │  Size: sm | md | lg    │
│    ├─ Card            │  Variant: primary |    │
│    ├─ Form            │           secondary    │
│    └─ Modal           │                        │
└────────────────────────────────────────────────┘

Code: components/ui/button.tsx
  ↕ (file watching - HMR)
Storybook Preview (76ms updates)
```

---

### **Why Storybook is Critical**

#### **1. Native Code Link** (Your Requirement)

**How It Works**:
```
VSCode/Cursor: Edit button.tsx
  - Change: bg-blue-500 → bg-purple-600
  - Save: Ctrl+S

File System: Detects change
  ↓ (76ms via Hot Module Replacement)

Storybook: localhost:6006
  - Button preview updates automatically
  - New purple color visible
  - No manual refresh needed
```

**Why This Matters**:
- Code and visual are **same source** (button.tsx)
- Change code → See visual instantly (<100ms)
- No "design to code" translation
- No export/import workflow

**Citation**:
> "Turbopack provides interactive hot-reloading in tens of milliseconds. 96.3% faster code updates with Fast Refresh on large apps."
> **Source**: Next.js Turbopack (2024)

---

#### **2. Display Everything** (Your Requirement)

**Component States in One View**:
```
Storybook: Button Component

States (all visible simultaneously):
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Default  │  │  Hover   │  │ Disabled │  │ Loading  │
└──────────┘  └──────────┘  └──────────┘  └──────────┘

Props (interactive controls):
- Size: [sm] [md] [lg]
- Variant: [primary] [secondary] [tertiary]
- Disabled: [ ] checkbox
- Loading: [ ] checkbox

Documentation (auto-generated from code):
- Usage: <Button variant="primary">Click Me</Button>
- Props: variant, size, disabled, loading, onClick
```

**Why This Matters**:
- See **all** component states without clicking around app
- Test **all** prop combinations (size × variant = 9 combinations)
- Catch edge cases (disabled + loading, small + tertiary)
- Developers and designers review **same** view

---

#### **3. Isolation** (Development Benefit)

**Without Storybook**:
```
To see Button changes:
1. Navigate to /login page
2. Fill form
3. Click submit
4. See button on success modal
5. Realize button is wrong
6. Edit code
7. Refresh page
8. Repeat steps 1-4
⏱️ 30 seconds per iteration
```

**With Storybook**:
```
To see Button changes:
1. Storybook already open (localhost:6006)
2. Button visible in preview
3. Edit code
4. Button updates (76ms)
⏱️ <1 second per iteration
```

**Result**: 30x faster iteration

---

### **Storybook Use Cases in Forge**

#### **Use Case 1: Component Development**

```bash
forge generate-component Button
  ↓
1. Claude generates:
   - components/ui/button.tsx
   - components/ui/button.stories.tsx (Storybook story)

2. Storybook shows:
   - Button in all sizes (sm, md, lg)
   - Button in all variants (primary, secondary, tertiary)
   - Button in all states (default, hover, disabled, loading)

3. User reviews in Storybook:
   "Primary variant looks good, but secondary needs darker border"

4. Claude updates code:
   - border-gray-300 → border-gray-400

5. Storybook updates (76ms):
   - Secondary button now has darker border

6. User approves: ✅
```

**Why Storybook Here**: Visual confirmation of all component variations without building full app

---

#### **Use Case 2: Design System Preview**

```bash
forge create-design-system
  ↓
1. Generates design/design-system.md:
   - Colors: primary, secondary, accent, neutrals
   - Typography: headings, body, captions
   - Spacing: xs, sm, md, lg, xl
   - Shadows: Level 1, 2, 3

2. forge setup-ui imports to Tailwind config

3. Storybook shows live style guide:
   ┌────────────────────────────────┐
   │ Colors                         │
   │ ■ Primary (#3B82F6)           │
   │ ■ Secondary (#10B981)         │
   │ ■ Accent (#F59E0B)            │
   │                                │
   │ Typography                     │
   │ Heading 1 (32px, bold)        │
   │ Heading 2 (24px, bold)        │
   │ Body (16px, regular)          │
   │                                │
   │ Components                     │
   │ [Button] [Card] [Input] [Form]│
   └────────────────────────────────┘

4. User: "Primary color is too bright, make it calmer"

5. Claude updates design-system.md:
   - Primary: #3B82F6 → #6366F1 (softer indigo)

6. forge update-tokens (re-imports to Tailwind)

7. Storybook auto-reloads (HMR):
   - All buttons now use new primary color
   - All cards with primary borders updated
   - All text in primary color updated

8. User sees entire system with new color: ✅
```

**Why Storybook Here**: See design system changes across **all components** instantly (no manual checking)

---

#### **Use Case 3: Responsive Testing**

```bash
Storybook Toolbar:
[Desktop 1920px] [Tablet 768px] [Mobile 375px]

User clicks Mobile:
  ↓
Preview resizes to 375px width
  ↓
User sees:
- Button stacks vertically (not shrunk)
- Card padding reduces (lg → md)
- Text reflows (no overflow)
- Images maintain aspect ratio

User: "On mobile, the card title is too large"

Claude updates:
  - Mobile breakpoint: text-2xl → text-xl

Storybook (mobile view) updates:
  - Card title is now smaller

User approves: ✅
```

**Why Storybook Here**: Test responsive behavior without deploying or using real devices

---

## SUPERDESIGN: WHAT IT IS & WHY IT'S CRITICAL

### **What SuperDesign Is**

**Simple Definition**: Visual design canvas for Claude-generated components with iteration rules

**Technical Definition**:
> "SuperDesign.dev is a visual canvas that renders Claude Code components with configurable rules (claude.md) for design iteration and component cloning."

**Visual Representation**:
```
SuperDesign Canvas (Browser)

┌────────────────────────────────────────────┐
│  Canvas                                    │
│  ┌──────────────────────────────────────┐ │
│  │                                      │ │
│  │   [Button Visual]                    │ │
│  │                                      │ │
│  │   Live preview of generated code     │ │
│  │                                      │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  Chat Interface:                           │
│  User: "Make it more modern"               │
│  Claude: [Updates code based on rules]     │
│  Canvas: [Shows updated button]            │
└────────────────────────────────────────────┘

Rules (claude.md):
  "Modern" = flat design, subtle shadow, 8px radius, sans-serif
```

---

### **Why SuperDesign Solves Subjective Iteration**

**The Key**: **Rules in claude.md translate subjective terms to objective values**

#### **Example: "Make it Modern"**

**Without Rules** (Ambiguous):
```
User: "Make the button more modern"

Claude guesses:
  Option A: Glassmorphism (blur, transparency)
  Option B: Neumorphism (soft shadows, embossed)
  Option C: Flat 2.0 (minimal shadow, bold color)

User: "Not what I meant"
❌ Iteration wasted
```

**With SuperDesign Rules** (Objective):
```markdown
## claude.md - SuperDesign Rules

### Design Philosophy
"Modern" means:
  - Flat design (no gradients except hero)
  - Subtle shadows (Level 1 or 2 max, no Level 3)
  - Border radius: 8px (cards), 6px (buttons)
  - Typography: Sans-serif, medium weight (500-600)
  - Colors: High contrast, avoid pastels
  - Spacing: Generous (16px+ padding)

"Professional" means:
  - Neutral color dominance (70%)
  - Primary color used sparingly (CTAs only)
  - Consistent spacing (8px grid system)
  - Subtle animations (300ms max, ease-out)

"Energetic" means:
  - Bright primary color (#3B82F6, #10B981)
  - Bold typography (600-700 weight)
  - Generous use of accent color (15%)
  - Faster animations (200ms, ease-in-out)
```

**Now with Rules**:
```
User: "Make the button more modern"

Claude reads rules:
  - Modern = flat, subtle shadow, 8px radius, sans-serif
  ↓
Claude updates:
  - Remove gradient → solid bg-primary
  - Shadow: Level 3 → Level 1
  - Border radius: 4px → 8px
  - Font: serif → sans-serif (Inter)
  ↓
SuperDesign canvas shows updated button
  ↓
User: "Perfect, that's what I meant" ✅
```

**The Difference**: Rules make subjective terms objective

---

### **SuperDesign Rules for Common Subjective Terms**

**From Research** (YouTube + 2024-2025 best practices):

```markdown
## claude.md - Aesthetic Translation Rules

### Visual Adjectives → Concrete Values

"Modern":
  - Design style: Flat 2.0 (minimal shadows, bold colors)
  - Shadows: Level 1 (0 1px 3px rgba(0,0,0,0.1)) or Level 2 max
  - Border radius: 8px (cards), 6px (buttons), 4px (inputs)
  - Typography: Sans-serif (Inter, SF Pro, Helvetica Neue)
  - Gradients: Avoid (except subtle radial on hero)
  - Borders: Minimal (shadows provide separation)

"Professional":
  - Color palette: Neutral-dominant (70% gray shades)
  - Primary usage: CTAs only (10% of surface)
  - Typography: Medium weight (500-600), generous spacing
  - Spacing: Consistent 8px grid system
  - Animations: Subtle (300ms, ease-out)

"Energetic":
  - Primary color: Bright, saturated (#3B82F6, #10B981, #F59E0B)
  - Accent usage: 15% of surface (vs 5% for calm)
  - Typography: Bold headings (700 weight)
  - Animations: Faster (200ms, ease-in-out)
  - Shadows: Level 2 on hover (lift effect)

"Calm":
  - Primary color: Muted, low saturation (#6366F1, #8B5CF6)
  - Accent usage: 5% of surface
  - Typography: Regular weight (400-500)
  - Spacing: Generous (24px+ between sections)
  - Animations: Slow (400ms, ease-out)

"Playful":
  - Border radius: Large (12px+ for cards)
  - Colors: Multiple bright accents (2-3 colors)
  - Typography: Rounded fonts (Poppins, Quicksand)
  - Illustrations: Allowed (icons, decorative elements)
  - Animations: Bouncy (spring physics, overshoot)

"Serious":
  - Colors: Monochrome or single accent
  - Typography: Traditional (Georgia, Times) or neutral (Helvetica)
  - Spacing: Dense (12px padding, tight line-height)
  - Borders: Present (define boundaries clearly)
  - Animations: None or minimal
```

---

### **SuperDesign Workflow in Forge**

#### **Phase 2.5: Visual Design with SuperDesign**

```bash
# Step 1: Define Aesthetic Rules
forge design-brief
  ↓
User provides aesthetic direction:
  "Modern, professional, with energetic accents"
  ↓
AI generates aesthetic brief:
  design/aesthetic-brief.md
  ↓
AI updates claude.md with translation rules:
  - Modern = flat, subtle shadow, 8px radius
  - Professional = neutral-dominant, medium weight
  - Energetic = bright primary (#3B82F6), bold headings

# Step 2: Generate Mockup in SuperDesign
forge generate-mockup --tool=superdesign
  ↓
Opens SuperDesign canvas
  ↓
Pastes design system + aesthetic rules
  ↓
AI generates initial mockup:
  - Login screen with modern button
  - Professional color palette (70% neutral)
  - Energetic CTA (bright blue, bold text)
  ↓
SuperDesign canvas shows rendered result

# Step 3: Subjective Iteration (Now Works!)
User: "Make the button more modern"
  ↓
AI reads claude.md rules:
  - Modern = 8px radius, Level 1 shadow, sans-serif
  ↓
AI updates code
  ↓
SuperDesign canvas updates (5-10 seconds)
  ↓
User: "Perfect!"

User: "Make the card feel more professional"
  ↓
AI reads rules:
  - Professional = neutral bg, medium weight text, consistent spacing
  ↓
AI updates card:
  - Background: white → light gray (#F3F4F6)
  - Font weight: 600 → 500
  - Padding: 12px → 16px (8px grid)
  ↓
SuperDesign canvas updates
  ↓
User: "Exactly what I wanted"

# Step 4: Export to Forge
User: "This is the final design"
  ↓
SuperDesign exports React code
  ↓
forge imports to components/
  ↓
Storybook shows components (localhost:6006)
```

**Why This Works**:
- **Subjective terms** ("modern", "professional") → **Objective rules** (8px radius, neutral bg)
- **Visual iteration** in SuperDesign (see changes in 5-10 sec)
- **Portable code** (export to Storybook for development)

---

## PLAYWRIGHT: OBJECTIVE VALIDATION (NOT SUBJECTIVE ITERATION)

### **What Playwright Does Best**

**Your Insight**:
> "Playwright is helpful for objective comparables (component, inspiration image). But for subjective changes ('make it more modern'), you still need to interpret."

**You're Absolutely Right**. Here's how Playwright fits:

---

### **Playwright Use Cases** (Objective Only)

#### **Use Case 1: Mockup Match Validation**

```bash
forge generate-component Button --validate
  ↓
1. Claude generates button.tsx
2. Storybook renders (localhost:6006)
3. Playwright screenshots button
4. Playwright compares to design/mockups/button.png
5. If pixel-perfect match:
   ✅ Component approved
6. If mismatch:
   Playwright shows diff image:
   - Expected: 8px border radius
   - Actual: 4px border radius
   Claude patches code automatically
   Repeat steps 2-6
```

**Why This Works**:
- **Objective reference**: design/mockups/button.png (exact target)
- **Pixel comparison**: Computer vision catches 2px differences
- **Automated fix**: Claude sees diff, knows exactly what to change

---

#### **Use Case 2: Inspiration Match**

```bash
User: "Make the button match this Stripe button"
[Provides screenshot: stripe-button.png]

forge clone-component --reference=stripe-button.png
  ↓
1. Claude analyzes stripe-button.png:
   - Border radius: 6px
   - Padding: 12px 24px
   - Font size: 14px
   - Shadow: 0 2px 4px rgba(0,0,0,0.1)
   - Color: #635BFF

2. Claude generates button.tsx with extracted values

3. Storybook renders

4. Playwright screenshots

5. Playwright compares to stripe-button.png:
   - Border radius: ✅ 6px match
   - Padding: ✅ 12px 24px match
   - Font size: ✅ 14px match
   - Shadow: ⚠️ Slightly lighter (0.08 vs 0.1)
   - Color: ✅ #635BFF match

6. Claude adjusts shadow opacity

7. Playwright validates: ✅ Pixel-perfect match
```

**Why This Works**:
- **Objective reference**: stripe-button.png (exact target)
- **Measurable values**: px, colors, shadows (not subjective)
- **Automated validation**: No human judgment needed

---

#### **Use Case 3: Regression Prevention**

```bash
forge snapshot
  ↓
Playwright captures baseline screenshots:
  - button-default.png
  - button-hover.png
  - button-disabled.png
  - card-default.png
  - card-empty.png
  ...

[Later: Refactor button.tsx]

forge validate-ui
  ↓
Playwright compares current UI to baselines:
  - button-default.png: ✅ Match
  - button-hover.png: ❌ Mismatch (shadow changed)
  - button-disabled.png: ✅ Match

Playwright shows diff image:
  Expected: 0 1px 3px rgba(0,0,0,0.1)
  Actual: 0 2px 4px rgba(0,0,0,0.15)

User: "Unintentional change, revert shadow"

Claude reverts shadow

forge validate-ui: ✅ All match
```

**Why This Works**:
- **Objective baseline**: Approved screenshots (exact state)
- **Automated detection**: Catches accidental changes
- **Visual proof**: Diff images show exactly what changed

---

### **Where Playwright DOESN'T Help**

#### **Scenario: Subjective Change**

```
User: "Make the button feel more premium"

Playwright's problem:
  - No objective reference (what is "premium"?)
  - No pixel target (how much shadow = premium?)
  - No comparable (premium relative to what?)

Result: Playwright can't validate subjective aesthetics
```

**Solution**: Use SuperDesign with rules

```markdown
## claude.md

"Premium" means:
  - Subtle gradient (linear, 5% opacity difference)
  - Dual shadows (light top + dark bottom)
  - Rounded corners (8-12px)
  - High contrast text (white on dark primary)
  - Smooth animations (400ms, ease-out)
```

Now Claude knows exactly what "premium" means, SuperDesign shows it visually, and **Playwright validates it hasn't regressed** after approval.

---

## FINAL WORKFLOW RECOMMENDATION

### **The Complete System**

```
Phase 2.5: Visual Design (Subjective → Objective)

Step 1: Define Aesthetic Rules
  forge design-brief
    → User: "Modern, professional, energetic"
    → AI translates to objective rules (claude.md)
    → Rules: Modern = 8px radius, flat, sans-serif
    → Output: design/aesthetic-brief.md + claude.md rules

Step 2: Mine Inspiration (Objective References)
  forge mine-inspiration
    → AI finds 10 Mobbin screenshots (Airbnb, Stripe, etc.)
    → Output: design/inspiration/*.png
    → Purpose: Objective references for "modern", "professional"

Step 3: Extract Principles (Subjective → Objective)
  forge extract-principles
    → AI analyzes inspiration screenshots
    → Extracts objective values:
      - Airbnb: border-radius 8px, shadow Level 2, warm colors
      - Stripe: border-radius 6px, shadow subtle, purple primary
    → Output: design/competitor-analysis.md

Step 4: Create Design System (Objective Tokens)
  forge create-design-system
    → Merges: aesthetic rules + competitor analysis + PRD + IA
    → Outputs objective tokens:
      - Primary: #3B82F6 (not "a nice blue")
      - Border radius: 8px (not "rounded")
      - Shadow: 0 4px 6px rgba(0,0,0,0.1) (not "subtle")
    → Output: design/design-system.md (tokenized)
    → Auto-generates: tailwind.config.js

Step 5: Generate Mockups (Visual + Objective)
  forge generate-mockup --tool=superdesign --variants
    ↓
  SuperDesign Workflow:
    1. AI generates initial mockup (using design tokens)
    2. SuperDesign canvas shows visual
    3. User iterates with subjective terms:
       - "Make it more modern"
       - AI reads claude.md rules
       - AI applies: 8px radius, flat design, Level 1 shadow
       - SuperDesign updates (5-10 sec)
    4. User: "Perfect!"
    5. Export mockup as PNG + React code
    ↓
  Output:
    - design/mockups/login-final.png (objective reference)
    - components/ui/login.tsx (initial code)

─────────────────────────────────────────────────
Phase 3: UI Implementation (Objective Validation)

Step 1: Setup
  forge setup-ui
    → Installs: Storybook, Playwright MCP
    → Imports design-system.md to Tailwind config
    → Configures claude.md with rules

Step 2: Component Development (Storybook)
  forge generate-component Button
    ↓
  1. Claude generates:
     - components/ui/button.tsx (using design tokens)
     - components/ui/button.stories.tsx (Storybook story)
  2. Storybook renders (localhost:6006):
     - Button in all sizes (sm, md, lg)
     - Button in all variants (primary, secondary)
     - Button in all states (default, hover, disabled)
  3. User reviews in Storybook:
     - "Primary looks good"
     - "Secondary border too light"
  4. Claude updates (based on feedback)
  5. Storybook updates (76ms HMR)
  6. User approves: ✅

Step 3: Objective Validation (Playwright)
  forge validate-component Button --reference=design/mockups/button.png
    ↓
  1. Playwright screenshots button from Storybook
  2. Playwright compares to design/mockups/button.png
  3. If pixel-perfect match:
     ✅ Component approved
     Baseline screenshot saved
  4. If mismatch:
     Playwright shows diff image
     Claude identifies issue: "Border radius 6px, spec says 8px"
     Claude patches code
     Repeat steps 1-3

Step 4: Build Pages (Using Approved Components)
  forge generate-page Login
    ↓
  1. Claude uses approved Button, Input, Card components
  2. Storybook shows page preview
  3. User: "Login form looks good"
  4. Playwright validates vs design/mockups/login-final.png
  5. If match: ✅ Page approved

Step 5: Regression Testing (Ongoing)
  [Developer refactors button.tsx]
    ↓
  forge validate-ui (runs automatically on file save)
    ↓
  Playwright compares to baselines:
    - If change detected: ⚠️ Show diff, ask for approval
    - If approved: Update baseline
    - If rejected: Revert change

─────────────────────────────────────────────────
Phase 4: Deployment

git push → Vercel → CI runs forge validate-ui → Deploy if pass
```

---

### **Why This Workflow is World-Class**

#### **1. Subjective Iteration Works** (SuperDesign + Rules)

**Problem Solved**: "Make it more modern" is now objective
- **Rules in claude.md** translate subjective → objective
- **SuperDesign canvas** shows visual result
- **User iterates** with natural language
- **AI applies** consistent aesthetic rules

**Citation**: YouTube transcripts (SuperDesign.dev, AI LABS)

---

#### **2. Objective Validation Works** (Playwright)

**Problem Solved**: "Does it match the mockup?" is automated
- **Mockup as reference** (design/mockups/*.png)
- **Pixel-perfect comparison** (computer vision)
- **Automated fix** (Claude sees diff, patches code)
- **Regression prevention** (baseline screenshots)

**Citation**: Patrick Ellis - Playwright MCP agentic loop

---

#### **3. Native Code Link** (Storybook)

**Problem Solved**: Visual and code are same source
- **File watching** (Storybook monitors components/)
- **HMR** (76ms updates)
- **No manual sync** (change code → see visual)
- **Display everything** (all components, all states)

**Citation**: Next.js Turbopack benchmarks (96.3% faster)

---

#### **4. Scales with Complexity** (.agent folder)

**Problem Solved**: Context management as project grows
- **SOPs** prevent repeating mistakes
- **Architecture docs** stay with code
- **Claude reads docs** before implementing

**Citation**: AI Jason - .agent folder system

---

### **Comparison Table**

| Tool | Purpose | Input Type | Output Type | When to Use |
|------|---------|------------|-------------|-------------|
| **SuperDesign** | Visual iteration | Subjective ("modern") | Visual preview + code | Phase 2.5 (design mockups) |
| **Storybook** | Component development | Code edits | Live component preview | Phase 3 (implementation) |
| **Playwright** | Objective validation | Mockup PNG reference | Pass/fail + diff image | Phase 3 (validation) |

---

### **User Experience Example**

#### **Scenario: Create a Modern Login Page**

```
─── Phase 2.5: Design ───

User: "I want a modern login page"

forge design-brief
  User: "Modern, professional, clean"
  ↓
AI updates claude.md:
  Modern = flat, 8px radius, sans-serif
  Professional = neutral-dominant, medium weight
  Clean = minimal borders, generous spacing

forge mine-inspiration
  AI finds: Stripe login, Vercel login, Linear login
  ↓
Output: design/inspiration/*.png

forge extract-principles
  AI analyzes:
    - Stripe: 6px radius, purple primary, subtle shadow
    - Vercel: 8px radius, black primary, no borders
    - Linear: 8px radius, blue primary, Level 1 shadow
  ↓
Output: design/competitor-analysis.md

forge create-design-system
  AI merges:
    - Modern rules (8px radius, flat, sans-serif)
    - Competitor patterns (8px radius common, subtle shadows)
    - User's "professional, clean" (neutral-dominant, minimal borders)
  ↓
Output: design-system.md
  - Primary: #3B82F6 (blue, energetic but professional)
  - Border radius: 8px (modern standard)
  - Shadows: Level 1 only (clean, minimal)
  - Typography: Inter (sans-serif, modern)

forge generate-mockup --tool=superdesign
  ↓
SuperDesign opens:
  AI generates login page (using design tokens)
  Canvas shows visual

User: "Make the form more modern"
  ↓
AI reads claude.md:
  Modern = 8px radius (already applied ✅), flat (remove gradient), Level 1 shadow
  ↓
AI updates form:
  - Removes subtle gradient from inputs
  - Ensures 8px radius
  - Applies Level 1 shadow
  ↓
Canvas updates (5 sec)

User: "Perfect! Export this"
  ↓
SuperDesign exports:
  - design/mockups/login-final.png (objective reference)
  - components/pages/login.tsx (initial code)

─── Phase 3: Implementation ───

forge setup-ui
  Installs Storybook, Playwright
  Imports design-system.md to Tailwind

forge generate-component LoginForm --reference=design/mockups/login-final.png
  ↓
Storybook Workflow:
  1. Claude generates login-form.tsx
  2. Storybook shows form (localhost:6006)
  3. User: "Looks good, but submit button needs more padding"
  4. Claude updates: py-2 → py-3
  5. Storybook updates (76ms)
  6. User: "Perfect!"

Playwright Validation:
  1. Playwright screenshots form from Storybook
  2. Playwright compares to design/mockups/login-final.png
  3. Pixel match check:
     - Border radius: ✅ 8px
     - Shadow: ✅ Level 1
     - Typography: ✅ Inter
     - Spacing: ✅ 16px padding
  4. Result: ✅ Pixel-perfect match
  5. Baseline saved: .playwright/screenshots/login-form.png

─── Result ───

✅ Modern login page (user's subjective goal)
✅ Matches mockup exactly (objective validation)
✅ Fast iteration (76ms HMR in Storybook)
✅ No regressions (Playwright baseline)
```

---

## KEY INSIGHTS

### **1. Two-Phase Approach**

**Phase 2.5 (Design)**: Subjective iteration
- **Tool**: SuperDesign + aesthetic rules
- **Input**: "Make it modern", "more professional"
- **Output**: Objective mockup PNG + design tokens

**Phase 3 (Implementation)**: Objective validation
- **Tool**: Storybook (dev) + Playwright (validation)
- **Input**: Mockup PNG (objective reference)
- **Output**: Pixel-perfect components

**Why Separate**:
- Design phase needs flexibility (subjective iteration)
- Implementation phase needs precision (objective validation)
- Don't mix subjective and objective (confuses workflow)

---

### **2. Rules Bridge Subjective ↔ Objective**

**The Problem**: "Modern" means different things to different people

**The Solution**: claude.md aesthetic rules
```markdown
"Modern" = 8px radius, flat design, sans-serif, Level 1 shadow
```

**Now**:
- User says: "Make it modern" (subjective)
- AI applies: 8px radius, flat, sans-serif (objective)
- Playwright validates: 8px radius ✅ (measurable)

**Result**: Subjective iteration with objective validation

---

### **3. Mockup PNG is the Contract**

**Before Implementation**:
- Mockup PNG = approved visual design
- Design system = approved tokens

**During Implementation**:
- Code must match mockup (Playwright enforces)
- Components must use tokens (Storybook previews)

**After Implementation**:
- Baseline screenshots = approved state
- Any change triggers Playwright validation

**Result**: No drift from approved design

---

## RECOMMENDED FORGE COMMANDS

```bash
# Phase 2.5: Visual Design
forge design-brief                    # Define aesthetic rules (subjective → objective)
forge mine-inspiration                # Find Mobbin references (objective examples)
forge extract-principles              # Analyze inspiration (objective values)
forge create-design-system            # Generate tokens (objective)
forge generate-mockup --tool=superdesign  # Visual iteration (subjective with rules)

# Phase 3: UI Implementation
forge setup-ui                        # Install Storybook + Playwright
forge generate-component <name> --reference=<mockup.png>  # Objective target
forge preview                         # Storybook dev (76ms HMR)
forge validate-component <name>       # Playwright validation (objective)
forge snapshot                        # Save baselines (objective state)
forge validate-ui                     # Regression tests (objective)

# Continuous
forge review-design                   # Design Reviewer sub-agent (objective checks)
forge update-tokens                   # Re-import design system (keep tokens synced)
```

---

## CONCLUSION

**Your Question**: "What is the final workflow and why?"

**Answer**:

### **SuperDesign** (Subjective Iteration)
- **When**: Phase 2.5 (design mockups)
- **Why**: Translates subjective terms ("modern") to objective rules via claude.md
- **Input**: "Make it more modern"
- **Output**: Visual mockup + code (objective reference)

### **Storybook** (Component Development)
- **When**: Phase 3 (implementation)
- **Why**: Native code link (76ms HMR), display everything (all states), isolation
- **Input**: Component code
- **Output**: Live preview (instant feedback)

### **Playwright** (Objective Validation)
- **When**: Phase 3 (validation + regression)
- **Why**: Pixel-perfect comparison to mockup PNG (objective reference)
- **Input**: Mockup PNG (target)
- **Output**: Pass/fail + diff image (measurable)

### **Why This Works**:
1. **Subjective iteration** (SuperDesign + rules) → **Objective mockup** (PNG)
2. **Objective mockup** (PNG) → **Objective validation** (Playwright)
3. **Storybook** provides native code link (instant visual feedback)
4. **No guessing**: Rules make "modern" objective, mockup makes validation objective

**Result**: World-class workflow that handles both subjective aesthetics and objective validation.
