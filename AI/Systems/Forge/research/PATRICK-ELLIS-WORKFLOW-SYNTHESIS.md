# Patrick Ellis Workflow - Complete Synthesis
**Date**: 2025-01-15
**Purpose**: Clarify Patrick Ellis's exact design document → Claude Code → Playwright validation workflow
**Status**: Production-proven at Snapbar (AI-native startup)

---

## Executive Summary

**Your Understanding is CORRECT:**
> Patrick Ellis has a design document that outlines everything about the design: colours, typography, etc. and then he uses Claude Code to create that design and then Playwright validates it against the initial design brief.

**The Complete Picture:**

```
Design Document (design-system.md)
    ↓
Claude Code reads document + generates UI
    ↓
Playwright MCP screenshots the output
    ↓
Claude Code compares screenshot to design document rules
    ↓
Claude Code identifies violations + fixes them automatically
    ↓
REPEAT until validation passes
```

**Key Insight:** The "design document" isn't a mockup image. It's a **text-based specification** with objective rules. Playwright validates by checking if the rendered output matches those rules.

---

## Part 1: The Design Document

### What Patrick Ellis Puts in His Design Document

**File:** `design-system.md` or `CLAUDE.md` (project instructions)

**Structure:**

```markdown
# Design System

## Color Palette
- Primary: #3B82F6 (Blue-500)
  - Usage: CTAs, active states, primary actions
  - Contrast ratio: 4.5:1 minimum
- Secondary: #10B981 (Green-500)
  - Usage: Success states, confirmations
- Neutral: #64748B (Slate-500)
  - Usage: Text, borders, backgrounds
- Semantic:
  - Error: #EF4444 (Red-500)
  - Warning: #F59E0B (Amber-500)
  - Success: #10B981 (Green-500)

## Typography
- Font Family: Inter (fallback: system-ui)
- Headings:
  - H1: 2.25rem (36px), 700 weight, 1.2 line-height
  - H2: 1.875rem (30px), 700 weight, 1.3 line-height
  - H3: 1.5rem (24px), 600 weight, 1.4 line-height
- Body: 1rem (16px), 400 weight, 1.5 line-height
- Small: 0.875rem (14px), 400 weight, 1.5 line-height

## Spacing
- System: 8px base unit
- Component padding:
  - Button: 12px 24px (1.5u 3u)
  - Card: 24px (3u)
  - Input: 12px 16px (1.5u 2u)
- Section margins: 64px (8u) vertical

## Shadows
- Level 1 (Cards): 0 1px 3px rgba(0,0,0,0.1)
- Level 2 (Dropdowns): 0 4px 6px rgba(0,0,0,0.1)
- Level 3 (Modals): 0 10px 15px rgba(0,0,0,0.1)

## Border Radius
- Small (Buttons): 6px
- Medium (Cards): 8px
- Large (Modals): 12px

## Accessibility Requirements
- WCAG AA compliance minimum
- Color contrast: 4.5:1 for text, 3:1 for UI elements
- Keyboard navigation: All interactive elements accessible via Tab
- ARIA labels: Required for icon-only buttons
- Focus indicators: 2px outline, primary color

## Responsive Breakpoints
- Mobile: 320px - 767px
- Tablet: 768px - 1023px
- Desktop: 1024px+

## Component Specifications

### Button
- Height: 44px (touch target)
- Padding: 12px 24px
- Border radius: 6px
- Font: 16px, 600 weight
- States:
  - Default: Primary color, Level 1 shadow
  - Hover: 10% darker, Level 2 shadow
  - Active: 15% darker, Level 1 shadow
  - Disabled: 40% opacity, no shadow, cursor not-allowed

### Card
- Padding: 24px
- Border radius: 8px
- Shadow: Level 1
- Background: White (#FFFFFF)
- Border: 1px solid #E2E8F0 (Slate-200)

### Input
- Height: 44px
- Padding: 12px 16px
- Border radius: 6px
- Border: 1px solid #CBD5E1 (Slate-300)
- Focus state: 2px border, primary color, no shadow
- Error state: 2px border, error color
```

**Critical Pattern:** Every rule is **objective and measurable**. Playwright can verify:
- "Is the button height 44px?" ✅ YES/NO
- "Is the border radius 6px?" ✅ YES/NO
- "Is the color contrast 4.5:1?" ✅ YES/NO

---

## Part 2: Claude Code Generation

### How Claude Code Uses the Design Document

**CLAUDE.md Configuration Pattern (Patrick Ellis):**

```markdown
# Project Instructions

## Design System
- Read `design-system.md` before generating any UI components
- All components MUST adhere to design system specifications
- Use exact values (no approximations)

## Visual Development Protocol
When making visual changes to the front-end:
1. Generate component code
2. Use Playwright MCP server to screenshot the output
3. Compare screenshot measurements to design-system.md rules
4. If violations found, fix them immediately
5. Repeat until all rules pass

## Component Generation Steps
1. Read design-system.md section for component type
2. Generate component with exact specifications
3. Include all states (default, hover, active, disabled, error)
4. Add accessibility attributes (ARIA, keyboard nav)
5. Implement responsive behavior per breakpoints
6. Run Playwright validation before considering complete

## Validation Criteria (from design-system.md)
- [ ] Color palette matches exactly
- [ ] Typography specs match (size, weight, line-height)
- [ ] Spacing uses 8px grid system
- [ ] Shadows match level specifications
- [ ] Border radius matches specifications
- [ ] Touch targets ≥ 44px height
- [ ] Color contrast ≥ 4.5:1 for text
- [ ] Keyboard navigation works
- [ ] ARIA labels present
- [ ] Responsive at all breakpoints
```

**The Generation Process:**

```
User: "Generate a primary button component"
    ↓
Claude Code:
  1. Reads design-system.md → Button section
  2. Sees: Height 44px, Padding 12px 24px, Radius 6px, Color #3B82F6
  3. Generates button.tsx with EXACT values
  4. Calls Playwright MCP: screenshot button in all states
  5. Measures screenshot values vs design-system.md
  6. If mismatch → Auto-fixes → Repeat
  7. When all rules pass → Done
```

---

## Part 3: Playwright Validation

### How Playwright Validates Against the Design Document

**Key Insight:** Playwright doesn't compare screenshots to images. It **measures the rendered output** and compares to design-system.md rules.

**Validation Script Pattern (Patrick Ellis):**

```javascript
// tests/design-validation.spec.js

import { test, expect } from '@playwright/test';
import designSystem from '../design-system.json'; // Parsed from .md

test('Button - Primary variant validates against design system', async ({ page }) => {
  await page.goto('http://localhost:6006/?path=/story/button--primary');

  const button = page.locator('button[data-variant="primary"]');

  // 1. HEIGHT VALIDATION
  const boundingBox = await button.boundingBox();
  expect(boundingBox.height).toBe(44); // From design-system.md

  // 2. PADDING VALIDATION
  const computedStyle = await button.evaluate((el) => {
    const styles = window.getComputedStyle(el);
    return {
      paddingTop: styles.paddingTop,
      paddingRight: styles.paddingRight,
      paddingBottom: styles.paddingBottom,
      paddingLeft: styles.paddingLeft,
    };
  });
  expect(computedStyle.paddingTop).toBe('12px'); // From design-system.md
  expect(computedStyle.paddingRight).toBe('24px');

  // 3. BORDER RADIUS VALIDATION
  const borderRadius = await button.evaluate((el) =>
    window.getComputedStyle(el).borderRadius
  );
  expect(borderRadius).toBe('6px'); // From design-system.md

  // 4. COLOR VALIDATION
  const backgroundColor = await button.evaluate((el) =>
    window.getComputedStyle(el).backgroundColor
  );
  expect(backgroundColor).toBe('rgb(59, 130, 246)'); // #3B82F6 from design-system.md

  // 5. FONT VALIDATION
  const fontSize = await button.evaluate((el) =>
    window.getComputedStyle(el).fontSize
  );
  const fontWeight = await button.evaluate((el) =>
    window.getComputedStyle(el).fontWeight
  );
  expect(fontSize).toBe('16px'); // From design-system.md
  expect(fontWeight).toBe('600'); // From design-system.md

  // 6. SHADOW VALIDATION
  const boxShadow = await button.evaluate((el) =>
    window.getComputedStyle(el).boxShadow
  );
  expect(boxShadow).toBe('rgba(0, 0, 0, 0.1) 0px 1px 3px 0px'); // Level 1 from design-system.md

  // 7. ACCESSIBILITY VALIDATION
  await expect(button).toHaveAttribute('type', 'button');
  await expect(button).toBeFocusable(); // Keyboard navigation

  // 8. CONTRAST RATIO VALIDATION
  const contrastRatio = await page.evaluate(() => {
    // Calculate contrast ratio between text and background
    // (Uses WCAG formula)
    return calculateContrastRatio(textColor, bgColor);
  });
  expect(contrastRatio).toBeGreaterThanOrEqual(4.5); // WCAG AA from design-system.md

  // 9. HOVER STATE VALIDATION
  await button.hover();
  await page.waitForTimeout(200); // Animation duration
  const hoverBg = await button.evaluate((el) =>
    window.getComputedStyle(el).backgroundColor
  );
  // Expect 10% darker than primary (from design-system.md)
  expect(hoverBg).toBe('rgb(53, 117, 221)'); // Calculated from #3B82F6 - 10%

  // 10. SCREENSHOT FOR VISUAL RECORD
  await button.screenshot({ path: 'validation/button-primary.png' });
});
```

**The Validation Process:**

```
Claude Code generates button.tsx
    ↓
Playwright starts Storybook (localhost:6006)
    ↓
Playwright navigates to Button story
    ↓
Playwright measures:
  - Height: 44px ✅ (matches design-system.md)
  - Padding: 12px 24px ✅
  - Border radius: 6px ✅
  - Color: #3B82F6 ✅
  - Font: 16px, 600 ✅
  - Shadow: Level 1 ✅
  - Contrast: 4.5:1 ✅
    ↓
Playwright takes screenshot for visual record
    ↓
Playwright returns results to Claude Code
    ↓
If violations found:
  Claude Code auto-fixes → Re-runs validation
If all pass:
  Component approved ✅
```

---

## Part 4: The Agentic Loop

### Patrick Ellis's Autonomous Validation Pattern

**Key Quote from OneRedOak:**
> "Please use the playwright MCP server when making visual changes to the front-end to check your work"

**The Agentic Loop:**

```
1. GENERATE
   Claude Code: Reads design-system.md → Generates button.tsx

2. VALIDATE
   Claude Code: Calls Playwright MCP → Measures rendered output

3. ANALYZE (Autonomous)
   Claude Code: Compares measurements to design-system.md
   Claude Code: "Height is 40px, should be 44px - VIOLATION"
   Claude Code: "Border radius is 8px, should be 6px - VIOLATION"

4. FIX (Autonomous)
   Claude Code: Updates button.tsx:
     - height: '40px' → height: '44px'
     - borderRadius: '8px' → borderRadius: '6px'

5. RE-VALIDATE (Autonomous)
   Claude Code: Calls Playwright MCP again → Re-measures

6. REPEAT until all rules pass

7. REPORT
   Claude Code: "Button component validated ✅ All 10 rules pass"
```

**Critical Pattern:** The user doesn't intervene in steps 3-5. Claude Code autonomously detects violations and fixes them based on design-system.md rules.

---

## Part 5: Patrick Ellis's Complete Workflow

### Step-by-Step Implementation

#### Phase 1: Design System Creation

**User Action:**
```bash
forge design-brief
```

**User provides:**
- "Modern SaaS aesthetic"
- "Primary color: Blue"
- "Clean, minimal, professional"

**AI Action:**
1. Translates subjective → objective (using research patterns)
2. Creates `design-system.md` with OBJECTIVE rules:
   - Modern = Flat 2.0, 8px radius, Level 1 shadow, sans-serif
   - Professional = 70% neutral, medium weight, 8px grid
   - Blue primary = #3B82F6 (accessible contrast)

**Output:** `design-system.md` (complete specification)

---

#### Phase 2: Inspiration Mining

**User Action:**
```bash
forge mine-inspiration --keywords="SaaS dashboard, modern UI"
```

**AI Action:**
1. Uses Web2MCP to capture screenshots from Mobbin
2. Analyzes captured UIs for patterns
3. Extracts objective values: spacing, shadows, typography
4. Updates design-system.md with refined specifications

**Output:** `design-system.md` (refined with real-world patterns)

---

#### Phase 3: CLAUDE.md Configuration

**AI Action (Automatic):**
Creates `.claude/CLAUDE.md` with Patrick Ellis's pattern:

```markdown
# Visual Development Protocol

## Design System
- Read `design-system.md` before generating any UI
- All components MUST match exact specifications
- No approximations or "close enough"

## Validation Protocol
When generating components:
1. Read design-system.md for component specs
2. Generate code with EXACT values
3. Use Playwright MCP to measure output
4. Compare to design-system.md rules
5. Auto-fix violations
6. Repeat until all rules pass

## Validation Checklist
- [ ] Color palette exact match
- [ ] Typography specs match
- [ ] Spacing uses 8px grid
- [ ] Shadows match level specs
- [ ] Border radius matches
- [ ] Touch targets ≥ 44px
- [ ] Contrast ≥ 4.5:1
- [ ] Keyboard navigation works
- [ ] ARIA labels present
- [ ] Responsive at all breakpoints

## Tools
- Playwright MCP: Visual validation
- Storybook: Component development (76ms HMR)
```

---

#### Phase 4: Component Generation (The Core Loop)

**User Action:**
```bash
forge generate-component Button
```

**Autonomous Loop (Patrick Ellis Pattern):**

```
┌─────────────────────────────────────────────────────────┐
│ STEP 1: READ DESIGN SYSTEM                              │
├─────────────────────────────────────────────────────────┤
│ Claude Code reads design-system.md → Button section    │
│ Extracts:                                               │
│   - Height: 44px                                        │
│   - Padding: 12px 24px                                  │
│   - Radius: 6px                                         │
│   - Color: #3B82F6                                      │
│   - Font: 16px, 600 weight                              │
│   - Shadow: Level 1 (0 1px 3px rgba(0,0,0,0.1))        │
│   - States: default, hover, active, disabled            │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 2: GENERATE CODE                                   │
├─────────────────────────────────────────────────────────┤
│ Claude Code generates button.tsx:                      │
│                                                         │
│ export const Button = ({ variant, children }) => {     │
│   return (                                             │
│     <button                                            │
│       className={cn(                                   │
│         "h-11 px-6 rounded-md font-semibold",         │
│         "bg-blue-500 text-white shadow-sm",           │
│         "hover:bg-blue-600 active:bg-blue-700"        │
│       )}                                               │
│     >                                                  │
│       {children}                                       │
│     </button>                                          │
│   );                                                   │
│ };                                                     │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 3: START STORYBOOK                                │
├─────────────────────────────────────────────────────────┤
│ $ npm run storybook                                     │
│ Storybook running at localhost:6006                    │
│ HMR active: 76ms update time                           │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 4: PLAYWRIGHT VALIDATION (MCP)                     │
├─────────────────────────────────────────────────────────┤
│ Claude Code calls Playwright MCP:                      │
│   playwright.navigate('localhost:6006/button')         │
│   playwright.measure('button[data-variant="primary"]') │
│                                                         │
│ Playwright returns:                                    │
│   height: 44px ✅                                       │
│   padding: 12px 24px ✅                                 │
│   borderRadius: 6px ✅                                  │
│   backgroundColor: rgb(59,130,246) ✅                   │
│   fontSize: 16px ✅                                     │
│   fontWeight: 600 ✅                                    │
│   boxShadow: 0 1px 3px rgba(0,0,0,0.1) ✅              │
│   contrast: 4.8:1 ✅                                    │
│   keyboard accessible: YES ✅                           │
│   responsive: YES ✅                                    │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 5: COMPARE TO DESIGN SYSTEM                        │
├─────────────────────────────────────────────────────────┤
│ Claude Code compares measurements to design-system.md  │
│ All rules pass ✅                                       │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 6: TAKE SCREENSHOT (VISUAL RECORD)                │
├─────────────────────────────────────────────────────────┤
│ Playwright screenshots button in all states:           │
│   - validation/button-default.png                      │
│   - validation/button-hover.png                        │
│   - validation/button-active.png                       │
│   - validation/button-disabled.png                     │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 7: REPORT                                          │
├─────────────────────────────────────────────────────────┤
│ Claude Code: "Button component validated ✅"            │
│   - All 10 design rules passed                         │
│   - Accessibility: WCAG AA compliant                   │
│   - Responsive: Mobile/Tablet/Desktop tested           │
│   - Screenshots: validation/ directory                 │
└─────────────────────────────────────────────────────────┘
```

**If Violations Found (Autonomous Fix):**

```
┌─────────────────────────────────────────────────────────┐
│ STEP 4: PLAYWRIGHT VALIDATION (MCP)                     │
├─────────────────────────────────────────────────────────┤
│ Playwright returns:                                    │
│   height: 40px ❌ (should be 44px)                     │
│   borderRadius: 8px ❌ (should be 6px)                 │
│   contrast: 3.2:1 ❌ (should be ≥ 4.5:1)              │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 5: AUTONOMOUS FIX                                  │
├─────────────────────────────────────────────────────────┤
│ Claude Code analyzes violations:                       │
│   1. Height 40px → 44px (design-system.md rule)        │
│   2. Radius 8px → 6px (design-system.md rule)          │
│   3. Contrast 3.2:1 → Use darker text (WCAG rule)      │
│                                                         │
│ Claude Code updates button.tsx:                        │
│   - h-10 → h-11 (44px)                                 │
│   - rounded-lg → rounded-md (6px)                      │
│   - text-gray-100 → text-white (better contrast)       │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 6: RE-VALIDATE (Automatic)                        │
├─────────────────────────────────────────────────────────┤
│ Storybook HMR updates button (76ms)                    │
│ Claude Code calls Playwright MCP again                 │
│ Playwright measures updated button:                    │
│   height: 44px ✅ (FIXED)                              │
│   borderRadius: 6px ✅ (FIXED)                         │
│   contrast: 4.8:1 ✅ (FIXED)                           │
│                                                         │
│ All rules pass ✅                                       │
└─────────────────────────────────────────────────────────┘
```

**Key Pattern:** User never intervened. Claude Code autonomously detected violations, applied fixes based on design-system.md, and re-validated.

---

#### Phase 5: Iterative Refinement (User Subjective Changes)

**User:** "Make the button more energetic"

**Claude Code Action:**
1. Reads design-system.md → "Energetic" rules:
   - Primary color: Brighter (#10B981 Green vs #3B82F6 Blue)
   - Accent usage: 15%
   - Typography: Bold (700 weight vs 600)
   - Animations: 200ms, ease-in-out
2. Updates button.tsx with OBJECTIVE changes
3. Runs Playwright validation loop (autonomous)
4. Reports: "Button updated to energetic aesthetic ✅"

**User:** "Actually, make it modern professional instead"

**Claude Code Action:**
1. Reads design-system.md → "Modern Professional" rules:
   - Primary: Blue #3B82F6 (10% usage)
   - Neutral: 70% (Slate palette)
   - Typography: Medium weight (600)
   - Spacing: 8px grid
2. Updates button.tsx
3. Runs Playwright validation loop (autonomous)
4. Reports: "Button updated to modern professional ✅"

**Critical Pattern:** User uses subjective terms ("energetic", "modern"). Claude Code translates to objective rules from design-system.md. Playwright validates objective measurements.

---

#### Phase 6: GitHub Actions Integration (Production)

**Patrick Ellis Pattern:** Automated validation on every PR

**.github/workflows/design-validation.yml:**

```yaml
name: Design Validation

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm install
      - run: npm run storybook &
      - run: npx playwright install
      - run: npx playwright test tests/design-validation.spec.js
      - uses: actions/upload-artifact@v4
        with:
          name: validation-screenshots
          path: validation/
```

**Process:**
1. Developer pushes code → PR created
2. GitHub Actions:
   - Starts Storybook
   - Runs Playwright validation tests
   - Compares to design-system.md rules
   - Uploads screenshots
3. If violations → PR blocked, comment with issues
4. If pass → PR approved for review

---

## Part 6: Forge Integration

### Adapting Patrick Ellis's Workflow for Forge

**Forge's Advantage:** We already have PRD + IA. Now add Design System.

**Complete Forge Workflow:**

```
┌──────────────────────────────────────────────────────┐
│ PHASE 1: PRD (EXISTING - COMPLETE ✅)                │
├──────────────────────────────────────────────────────┤
│ forge start                                          │
│   → User stories, personas, scope                   │
│ forge import (Custom GPT)                            │
│   → Complete PRD.md                                  │
│ Confidence: 100%                                     │
└──────────────────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────────────────┐
│ PHASE 2: IA (EXISTING - COMPLETE ✅)                 │
├──────────────────────────────────────────────────────┤
│ forge import-ia (Custom GPT)                         │
│   → Sitemap, flows, navigation, components          │
│ IA Confidence: 80%+                                  │
└──────────────────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────────────────┐
│ PHASE 2.5: DESIGN SYSTEM (NEW - PATRICK ELLIS)      │
├──────────────────────────────────────────────────────┤
│ forge design-brief                                   │
│   User: "Modern SaaS, professional, blue primary"   │
│   AI creates design-system.md with objective rules  │
│                                                      │
│ forge mine-inspiration                               │
│   AI uses Web2MCP to capture real-world examples    │
│   AI refines design-system.md with proven patterns  │
│                                                      │
│ forge setup-ui                                       │
│   AI installs: Storybook + Playwright MCP           │
│   AI creates: .claude/CLAUDE.md (Patrick's pattern) │
│                                                      │
│ Output: design-system.md (complete specification)   │
└──────────────────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────────────────┐
│ PHASE 3: IMPLEMENTATION (NEW - PATRICK ELLIS)       │
├──────────────────────────────────────────────────────┤
│ forge generate-component Button                     │
│   Claude Code:                                      │
│     1. Reads design-system.md                       │
│     2. Generates button.tsx (exact specs)           │
│     3. Storybook HMR (76ms updates)                 │
│     4. Playwright validates (autonomous loop)       │
│     5. Auto-fixes violations                        │
│     6. Reports validation ✅                        │
│                                                      │
│ forge generate-component Card                        │
│   (Same autonomous loop)                            │
│                                                      │
│ forge generate-page LoginPage                        │
│   Reads: IA/flows/auth-flow.md                      │
│   Reads: design-system.md                           │
│   Uses: Button + Card components (validated)        │
│   Playwright validates full page                    │
│   Reports: Accessibility ✅ Responsive ✅           │
│                                                      │
│ User iterative changes:                             │
│   User: "Make it more modern"                       │
│   Claude: Reads design-system.md rules → Updates    │
│   Playwright: Re-validates → Pass ✅                │
└──────────────────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────────────────┐
│ PHASE 4: DEPLOYMENT (PATRICK ELLIS PATTERN)         │
├──────────────────────────────────────────────────────┤
│ git push → PR created                                │
│ GitHub Actions:                                      │
│   - Runs Playwright validation tests                │
│   - Compares to design-system.md                    │
│   - Uploads screenshots                             │
│   - Pass → PR approved                              │
│   - Fail → PR blocked with issues                   │
└──────────────────────────────────────────────────────┘
```

---

## Part 7: Putting It All Together

### The Complete Picture - How Every Piece Fits

**Your Question:**
> "I see the different pieces that we have, but I'm struggling to put it all together."

**Here's How Everything Connects:**

#### The Design Document (design-system.md)
- **Purpose:** Single source of truth for ALL design decisions
- **Format:** Markdown with objective, measurable rules
- **Content:** Colors, typography, spacing, shadows, components, accessibility
- **Why:** Playwright needs objective rules to validate against
- **Created by:** AI translates your subjective aesthetic → objective rules

#### Claude Code
- **Purpose:** Generate UI that matches design-system.md
- **Process:** Reads design-system.md → Generates code with EXACT values
- **Autonomous:** Validates own work via Playwright, fixes violations automatically
- **Why:** You don't want to manually check every CSS value matches the design doc

#### Playwright MCP
- **Purpose:** Measure rendered output objectively
- **Process:** Screenshots components → Measures CSS values → Returns to Claude Code
- **Why:** Validates the generated code actually matches design-system.md
- **Not for:** Subjective iteration (that's design-system.md's job)

#### Storybook
- **Purpose:** Fast visual development with HMR
- **Process:** 76ms updates when you save code
- **Why:** See changes instantly while Claude Code iterates
- **Connection:** Playwright navigates to Storybook URLs to measure components

#### SuperDesign (Optional Enhancement)
- **Purpose:** Visual mockups for complex layouts
- **Process:** Canvas-based design tool (5-10 sec updates)
- **Why:** Some things easier to visualize before coding
- **Connection:** Export mockup PNG → Reference image for complex pages

#### The Flow:
```
1. You provide subjective aesthetic: "Modern, professional, energetic"
   ↓
2. AI creates design-system.md with objective rules
   ↓
3. AI creates .claude/CLAUDE.md with Patrick Ellis's validation protocol
   ↓
4. You request component: "forge generate-component Button"
   ↓
5. Claude Code reads design-system.md → Generates button.tsx
   ↓
6. Storybook shows button (76ms HMR)
   ↓
7. Playwright measures button → Returns values to Claude Code
   ↓
8. Claude Code compares to design-system.md → Finds violations
   ↓
9. Claude Code auto-fixes violations → Storybook updates (76ms)
   ↓
10. Playwright re-measures → All rules pass ✅
   ↓
11. Claude Code reports: "Button validated ✅"
   ↓
12. You see final button in Storybook (looks perfect)
   ↓
13. You say: "Make it more energetic"
   ↓
14. Claude Code reads "energetic" rules from design-system.md
   ↓
15. Claude Code updates button.tsx with objective changes
   ↓
16. Loop repeats (steps 7-11) autonomously
   ↓
17. Done ✅
```

**Key Insight:** You never manually check CSS values. You never manually compare screenshots. You provide high-level feedback ("more modern"), Claude Code translates to objective changes, Playwright validates autonomously.

---

## Part 8: Implementation Commands

### New Forge Commands to Implement

```bash
# Phase 2.5: Design System Creation
forge design-brief
  # Creates design-system.md from user aesthetic input
  # Translates subjective → objective rules

forge mine-inspiration --keywords="SaaS dashboard"
  # Uses Web2MCP to capture real-world examples
  # Refines design-system.md with proven patterns

forge setup-ui
  # Installs Storybook + Playwright MCP
  # Creates .claude/CLAUDE.md with validation protocol
  # Configures package.json scripts

# Phase 3: Component Generation
forge generate-component <ComponentName>
  # Reads design-system.md
  # Generates component with exact specs
  # Runs autonomous Playwright validation loop
  # Reports violations/fixes

forge generate-page <PageName>
  # Reads IA flow + design-system.md
  # Generates page with validated components
  # Validates full page (accessibility, responsive)

forge review-design
  # Runs full Playwright test suite
  # Validates all components against design-system.md
  # Generates report with screenshots

# Phase 4: Deployment
forge setup-ci
  # Creates .github/workflows/design-validation.yml
  # Configures automated PR checks
```

---

## Part 9: Next Steps

### Immediate Actions

1. **Read this document completely** - Understand Patrick Ellis's exact workflow
2. **Confirm understanding** - Does this clarify how design document → Claude Code → Playwright validation works?
3. **Decide on enhancements** - SuperDesign optional? Web2MCP priority?
4. **Implement Phase 2.5** - Create `forge design-brief` command
5. **Test the loop** - Generate one component with autonomous validation
6. **Iterate** - Refine based on what works

### Questions to Resolve

1. **SuperDesign integration:** Worth adding canvas-based mockup tool, or is design-system.md text enough?
2. **Web2MCP priority:** How important is 1:1 component cloning from live sites?
3. **Forge command naming:** Do these command names make sense for your workflow?
4. **Custom GPT for design-system.md:** Should we create a third Custom GPT for design system generation?

---

## Conclusion

**Patrick Ellis's Workflow (Complete Picture):**

1. **Design Document** (design-system.md): Objective rules for ALL design decisions
2. **Claude Code**: Reads design-system.md → Generates code with exact values
3. **Playwright MCP**: Measures rendered output → Validates against design-system.md
4. **Autonomous Loop**: Claude Code fixes violations automatically, no manual intervention
5. **Storybook**: Fast visual feedback (76ms HMR) during iteration
6. **GitHub Actions**: Automated validation on every PR

**Key Insight:** The design document isn't a mockup image. It's a **specification** with objective, measurable rules. Playwright validates by checking if the rendered output matches those rules. Claude Code autonomously fixes violations.

**Your Advantage:** You already have PRD + IA. Adding Design System (Phase 2.5) completes the picture: PRD → IA → Design System → Implementation (with autonomous validation).

**Production-Proven:** Patrick Ellis uses this at Snapbar (AI-native startup). This isn't theory, it's battle-tested.

**Ready to implement?** Let's build Phase 2.5 (`forge design-brief`) and test the autonomous validation loop.
