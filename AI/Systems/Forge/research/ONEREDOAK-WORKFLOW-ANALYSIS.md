# OneRedOak Claude Code Workflows Analysis

**Date**: 2025-01-15
**Source**: https://github.com/OneRedOak/claude-code-workflows
**Author**: Patrick Ellis (CTO & Co-Founder of Snapbar)
**Context**: "Best workflows and configurations developed, having heavily used Claude Code since the day of its release. Based on applied learnings from an AI-native startup."

---

## EXECUTIVE SUMMARY

**What This Repository Suggests**:

OneRedOak's workflows represent **production-proven patterns** from an AI-native startup that has used Claude Code extensively since launch. The key insight: **Automate routine review tasks (code, security, design) using AI agents, freeing humans for strategic work.**

**Critical for Forge**: The **Design Review Workflow** validates our entire research direction:
- Uses Playwright MCP (we identified as critical)
- Checks UI/UX consistency, accessibility, design standards
- Automated PR checks (catches issues before production)
- Slash commands + GitHub Actions integration

**This confirms our workflow is aligned with real-world production systems.**

---

## THREE CORE WORKFLOWS

### **1. Code Review Workflow**

**Purpose**: Automated code review using AI agents

**Architecture**: Dual-loop system
- **Loop 1**: Routine checks (syntax, style guide, completeness)
- **Loop 2**: Deep analysis (bug detection, edge cases)

**Triggers**:
- Slash commands (manual)
- GitHub Actions (automatic on PR)

**Checks**:
- Syntax validation
- Code completeness
- Style guide adherence
- Bug detection
- Edge case coverage

**Philosophy**:
> "Free your team to focus on strategic thinking"

**Why This Matters for Forge**:
- Validates our sub-agent approach (specialized agents for specific tasks)
- Confirms slash command integration is production-ready
- Shows GitHub Actions integration is standard practice

---

### **2. Security Review Workflow**

**Purpose**: Proactive security scanning based on OWASP Top 10

**Features**:
- Vulnerability identification
- Secret exposure detection (API keys, credentials)
- Attack vector analysis
- Severity classification (critical/high/medium/low)
- Clear remediation guidance

**Triggers**:
- Slash commands (on-demand scanning)
- GitHub Actions (automatic PR security checks)

**Standards**: OWASP Top 10 compliance

**Why This Matters for Forge**:
- Shows security can be automated via AI agents
- Validates using industry standards (OWASP) as reference
- Confirms PR automation is production-ready

---

### **3. Design Review Workflow** (MOST RELEVANT)

**Purpose**: Automated design review for front-end code changes

**Technology**: Microsoft's open-source Playwright MCP browser automation

**Checks**:
- **UI/UX consistency**: Ensures visual coherence across components
- **Accessibility compliance**: WCAG standards (keyboard nav, ARIA, contrast)
- **Design standard adherence**: Follows established design system
- **Visual issue detection**: Catches problems before production

**Specialized Components**:
- Sub-agents (specialized for design review tasks)
- Slash commands (manual trigger)
- CLAUDE.md excerpts (configuration rules)
- Broad criteria coverage (responsive design, accessibility, visual consistency)

**Integration**: GitHub Actions for automated PR checks

**Patrick Ellis Quote**:
> "Please use the playwright MCP server when making visual changes to the front-end to check your work"

**Why This Is Critical for Forge**:
- **Validates our Playwright MCP approach** (production-proven)
- **Confirms UI/UX consistency checks** are automatable
- **Shows accessibility compliance** can be AI-driven
- **Proves design standard adherence** works with CLAUDE.md rules
- **Demonstrates slash commands + GitHub Actions** pattern works

---

## KEY INSIGHTS FOR FORGE

### **1. CLAUDE.md Configuration is Production-Critical**

**Patrick Ellis's Approach**:
```markdown
## CLAUDE.md

When making visual changes to the front-end:
- Use Playwright MCP server to check your work
- Screenshot components in all states
- Compare to design system standards
- Validate accessibility compliance
```

**This Confirms**:
- Our aesthetic rules approach (claude.md) is correct
- Playwright integration should be in claude.md
- Design system standards should be referenced in claude.md

**For Forge**:
```markdown
## Forge CLAUDE.md - Visual Development Protocol

When implementing UI components:

1. **Always use Playwright MCP** for visual validation
2. **Reference design system**: context/design-system.md
3. **Compare to mockups**: design/mockups/*.png
4. **Check accessibility**:
   - Keyboard navigation works
   - ARIA labels present
   - Contrast ratios meet WCAG AA (4.5:1 text, 3:1 UI)
5. **Test responsive breakpoints**: Mobile (375px), Tablet (768px), Desktop (1920px)
6. **Validate states**: Default, hover, focus, disabled, loading, error
```

---

### **2. Dual-Loop Architecture Pattern**

**OneRedOak's Pattern**:
- **Loop 1 (Fast)**: Routine checks (syntax, style guide)
- **Loop 2 (Deep)**: Complex analysis (bugs, edge cases)

**Applied to Forge Design Review**:
```
Loop 1 (Fast - Storybook):
  → Developer saves component
  → Storybook HMR updates (76ms)
  → Visual preview shows component
  → Developer iterates quickly

Loop 2 (Deep - Playwright):
  → Developer approves component
  → Playwright screenshots component
  → Compares to mockup PNG
  → Checks accessibility (WCAG)
  → Checks responsive breakpoints
  → If pass: ✅ Approved
  → If fail: ❌ Shows diff, suggests fix
```

**Why This Works**:
- Fast loop (Storybook): Rapid iteration (76ms)
- Deep loop (Playwright): Thorough validation (objective checks)
- Don't mix: Fast loop for development, deep loop for approval

---

### **3. Slash Commands + GitHub Actions Pattern**

**OneRedOak's Integration**:
- **Slash commands**: Manual trigger during development
- **GitHub Actions**: Automatic trigger on PR

**Applied to Forge**:
```bash
# Development (Manual)
forge generate-component Button
forge review-design  # Slash command → Playwright validation

# CI/CD (Automatic)
git push
  → GitHub Actions triggers
  → Runs: forge validate-ui
  → Playwright compares to baselines
  → If fail: Blocks merge, shows diff screenshots
  → If pass: Approves merge
```

**Why This Is Production-Ready**:
- Manual: Developer controls when to validate (during development)
- Automatic: CI/CD enforces standards (before merge)
- Best of both: Flexibility + safety

---

### **4. Specialized Sub-Agents**

**OneRedOak's Approach**:
> "Specialized sub-agents, slash commands, CLAUDE.md excerpts, covering a broad range of criteria from responsive design to accessibility."

**This Confirms**:
- Our Design Reviewer sub-agent approach (from YouTube research)
- Sub-agents should be specialized (not general-purpose)
- CLAUDE.md provides rules/criteria for sub-agents

**For Forge**:
```
Design Review Sub-Agent:
  Persona: Principal Designer with 10 years experience
  Expertise: UI/UX consistency, accessibility, responsive design
  Tools: Playwright MCP
  Context: design/design-system.md, design/mockups/*.png
  Criteria (from CLAUDE.md):
    - Visual fidelity (vs mockups)
    - Accessibility (WCAG AA)
    - Responsive breakpoints (mobile/tablet/desktop)
    - Design system adherence (colors, spacing, typography)
  Output: Graded report with screenshots + suggested fixes
```

---

### **5. Catch Visual Issues Before Production**

**OneRedOak's Goal**:
> "Catch visual issues before they reach production"

**How They Do It**:
- Automated design review on every PR
- Playwright screenshots capture actual rendered output
- AI agents compare to standards (design system, accessibility)
- Block merge if issues found

**For Forge**:
```
Phase 3: UI Implementation

Developer workflow:
1. forge generate-component Button
2. Develop in Storybook (fast iteration)
3. forge review-design (manual validation)
4. Git commit + push

GitHub Actions (automatic):
1. Checkout code
2. Run: forge validate-ui
3. Playwright screenshots all components
4. Compare to baselines (.playwright/screenshots/)
5. Check accessibility (WCAG AA)
6. If issues found:
   - ❌ Block merge
   - Show diff screenshots
   - Suggest fixes
7. If pass:
   - ✅ Approve merge
   - Deploy to production
```

**Result**: Visual issues caught automatically, never reach production

---

## WHAT ONEREDOAK SUGGESTS FOR FORGE

### **1. Implement Design Review Workflow**

**Components**:
- Playwright MCP integration (automated screenshots)
- Design Reviewer sub-agent (specialized for UI/UX)
- CLAUDE.md configuration (rules + criteria)
- Slash commands (manual trigger)
- GitHub Actions (automatic PR checks)

**Why**: Production-proven pattern from AI-native startup

---

### **2. Use Dual-Loop Architecture**

**Fast Loop** (Development):
- Storybook with HMR (76ms updates)
- Developer iterates rapidly
- Visual feedback instant

**Deep Loop** (Validation):
- Playwright MCP screenshots
- Compare to mockups + baselines
- Check accessibility (WCAG)
- Block if issues found

**Why**: Separates rapid iteration from thorough validation

---

### **3. Configure CLAUDE.md for Visual Development**

**Patrick Ellis's Pattern**:
> "Please use the playwright MCP server when making visual changes to the front-end to check your work"

**For Forge**:
```markdown
## Visual Development Protocol (CLAUDE.md)

When implementing UI:
1. Always use Playwright MCP for visual validation
2. Reference design system (context/design-system.md)
3. Compare to mockups (design/mockups/*.png)
4. Check accessibility (keyboard nav, ARIA, contrast)
5. Test responsive breakpoints (mobile/tablet/desktop)
6. Validate all states (default/hover/disabled/error)

Design Review Criteria:
- Visual fidelity: Match mockup within 2px tolerance
- Accessibility: WCAG AA minimum (4.5:1 text, 3:1 UI)
- Responsive: All breakpoints render correctly
- Design system: Colors, spacing, typography from tokens
- States: All states (hover, focus, disabled) work correctly
```

**Why**: CLAUDE.md makes AI behavior consistent and production-ready

---

### **4. Automate PR Checks**

**OneRedOak's Pattern**:
- Slash commands: Manual during development
- GitHub Actions: Automatic on PR

**For Forge**:
```yaml
# .github/workflows/design-review.yml

name: Design Review
on: [pull_request]

jobs:
  design-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: anthropics/claude-code-action@v1
        with:
          command: "forge validate-ui"
      - name: Upload Screenshots
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-diff-screenshots
          path: .playwright/diff/*.png
```

**Why**: Automated quality gates prevent visual regressions

---

### **5. Specialized Sub-Agents**

**OneRedOak's Approach**:
- Design review sub-agent (UI/UX, accessibility, responsive)
- Code review sub-agent (syntax, style, bugs)
- Security review sub-agent (OWASP, vulnerabilities)

**For Forge**:
```
Design Reviewer Sub-Agent:
  forge review-design
    ↓
  Launches specialized agent:
    - Reads CLAUDE.md (criteria)
    - Reads design-system.md (standards)
    - Reads mockups/*.png (targets)
    - Uses Playwright MCP (screenshots)
    - Checks accessibility (WCAG)
    - Generates graded report
    - Suggests fixes (code patches)
```

**Why**: Specialized agents are more accurate than general-purpose

---

## PRODUCTION-PROVEN PATTERNS

**From AI-Native Startup** (Snapbar - Patrick Ellis):

### **Pattern 1: Playwright MCP is Essential**

**Quote**:
> "The most powerful workflow is Claude Code paired with the Playwright MCP which allows coding agents to navigate a browser, take screenshots, read network/console logs, etc."

**Application**:
- Forge should integrate Playwright MCP as core (not optional)
- All visual changes should trigger Playwright validation
- Screenshots provide objective evidence (not just text descriptions)

---

### **Pattern 2: CLAUDE.md is Configuration**

**Quote**:
> "One simple but helpful use has been adding 'Please use the playwright MCP server when making visual changes to the front-end to check your work' to his CLAUDE.md file."

**Application**:
- CLAUDE.md should contain design review protocol
- Rules should reference design system, mockups, accessibility standards
- AI reads CLAUDE.md before every action (consistent behavior)

---

### **Pattern 3: Broad Criteria Coverage**

**Quote**:
> "Covering a broad range of criteria from responsive design to accessibility"

**Checks**:
- Visual fidelity (vs mockups)
- Responsive design (mobile/tablet/desktop)
- Accessibility (WCAG compliance)
- Design system adherence (colors, spacing, typography)
- State coverage (default/hover/disabled/error)

**Application**:
- Forge design review should check all criteria (not just visual)
- Each criterion should be objective (measurable)
- Use industry standards (WCAG, design tokens)

---

### **Pattern 4: Automate Routine, Human for Strategy**

**Philosophy**:
> "Free your team to focus on strategic thinking"

**What AI Does**:
- Routine checks (syntax, style guide, accessibility)
- Pixel-perfect comparison (mockup match)
- Regression detection (baseline comparison)

**What Humans Do**:
- Strategic decisions (design direction, user experience)
- Edge case judgment (when to bend rules)
- Creative work (new designs, new features)

**Application**:
- Forge automates objective checks (Playwright validation)
- User focuses on subjective decisions (aesthetic direction)
- Best of both: AI for precision, human for creativity

---

## INTEGRATION WITH FORGE WORKFLOW

### **Phase 2.5: Visual Design** (Enhanced)

```bash
# After mockup generation (SuperDesign)
forge validate-design
  ↓
Design Review Sub-Agent:
1. Reads design-system.md (standards)
2. Reads mockups/*.png (targets)
3. Uses Playwright to screenshot mockup
4. Checks:
   - Visual consistency (colors, spacing match tokens)
   - Accessibility (contrast ratios, semantic HTML)
   - Responsive breakpoints (mobile/tablet/desktop)
5. Generates validation report
6. If issues found:
   - Shows diff screenshots
   - Suggests fixes (update design-system.md or mockup)
7. If pass:
   - ✅ Mockup approved
   - Saves baseline screenshot
   - Proceeds to Phase 3
```

---

### **Phase 3: UI Implementation** (Enhanced)

```bash
# During development
forge generate-component Button
  ↓
Storybook (Fast Loop):
  - HMR updates (76ms)
  - Developer iterates rapidly

# Manual validation
forge review-design
  ↓
Design Review Sub-Agent (Deep Loop):
  1. Playwright screenshots component from Storybook
  2. Compares to design/mockups/button.png
  3. Checks accessibility:
     - Keyboard navigation
     - ARIA labels
     - Contrast ratios (WCAG AA)
  4. Checks responsive breakpoints
  5. Generates graded report:
     - Visual fidelity: A (matches mockup)
     - Accessibility: B+ (missing one ARIA label)
     - Responsive: A (all breakpoints correct)
  6. Suggests fix: Add aria-label="Submit form"
  7. Developer applies fix
  8. Re-run: forge review-design
  9. All checks pass: ✅

# Automatic validation (GitHub Actions)
git push
  ↓
GitHub Actions runs:
  forge validate-ui
    ↓
  Playwright screenshots all components
  Compares to baselines
  Checks accessibility
  If issues:
    - ❌ Block merge
    - Upload diff screenshots
    - Comment on PR with findings
  If pass:
    - ✅ Approve merge
    - Deploy to production
```

---

## RECOMMENDED FORGE COMMANDS (Updated)

```bash
# Phase 2.5: Visual Design
forge design-brief                    # Define aesthetic (subjective → objective)
forge mine-inspiration                # Find Mobbin references
forge extract-principles              # Analyze inspiration (objective values)
forge create-design-system            # Generate tokens (objective)
forge generate-mockup --tool=superdesign  # Visual iteration (subjective with rules)
forge validate-design                 # Design review (objective) ← NEW

# Phase 3: UI Implementation
forge setup-ui                        # Install Storybook + Playwright MCP
forge generate-component <name>       # Generate component
forge preview                         # Storybook dev (fast loop)
forge review-design                   # Manual design review (deep loop) ← NEW
forge validate-ui                     # Automated validation (CI/CD) ← NEW
forge snapshot                        # Save baselines

# Continuous
forge update-tokens                   # Re-import design system
```

---

## CRITICAL TAKEAWAYS

### **1. OneRedOak Validates Our Entire Research**

**What We Found** (from research):
- Playwright MCP for visual validation
- Storybook for component development
- SuperDesign for subjective iteration
- CLAUDE.md for aesthetic rules
- Sub-agents for specialized tasks

**What OneRedOak Confirms** (production-proven):
- ✅ Playwright MCP is essential ("most powerful workflow")
- ✅ CLAUDE.md configuration works (Patrick Ellis uses it)
- ✅ Sub-agents are correct pattern (specialized for design/code/security)
- ✅ Automation + slash commands works (manual + CI/CD)
- ✅ Broad criteria coverage (visual, accessibility, responsive)

**Result**: Our workflow is aligned with real-world production systems

---

### **2. Add Design Review Sub-Agent**

**New Component for Forge**:
```
Design Reviewer Sub-Agent
  - Persona: Principal Designer
  - Tools: Playwright MCP
  - Context: design-system.md, mockups/*.png
  - Criteria: Visual fidelity, accessibility, responsive, design system
  - Output: Graded report + screenshots + fixes
```

**Triggered by**:
- `forge review-design` (manual)
- GitHub Actions (automatic on PR)

---

### **3. Dual-Loop is Production-Ready**

**Fast Loop** (Storybook):
- 76ms HMR updates
- Rapid iteration
- Developer-controlled

**Deep Loop** (Playwright):
- Screenshot comparison
- Accessibility checks
- CI/CD enforced

**Don't Mix**: Fast for development, deep for validation

---

### **4. Automate Routine, Human for Strategy**

**AI Automates**:
- Pixel-perfect comparison (mockup match)
- Accessibility checks (WCAG compliance)
- Regression detection (baseline comparison)
- Design system adherence (token validation)

**Human Focuses On**:
- Aesthetic direction ("make it modern")
- Strategic decisions (design system creation)
- Creative work (new features, new designs)
- Edge case judgment (when to bend rules)

**Result**: AI handles precision, human handles creativity

---

## FINAL RECOMMENDATION

**OneRedOak's workflows suggest**:

### **Implement Immediately**:
1. **Design Review Sub-Agent** with Playwright MCP
2. **CLAUDE.md visual development protocol**
3. **Slash commands**: `forge review-design`, `forge validate-ui`
4. **Dual-loop architecture**: Storybook (fast) + Playwright (deep)

### **Integrate with CI/CD**:
1. **GitHub Actions** for automated PR checks
2. **Baseline screenshots** for regression detection
3. **Block merge** if design review fails
4. **Upload diff screenshots** as PR artifacts

### **Follow Production Patterns**:
1. **Specialized sub-agents** (design, not general-purpose)
2. **Broad criteria coverage** (visual, accessibility, responsive)
3. **Objective validation** (mockup PNG, WCAG standards, design tokens)
4. **Automate routine** (free humans for strategy)

---

**OneRedOak confirms**: Our research-based workflow is production-ready and aligned with real-world AI-native startups.
