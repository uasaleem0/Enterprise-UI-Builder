# From-Scratch Workflow
**Command**: `forge start <project-name>`
**Purpose**: Create new project from vague idea to 95% confidence PRD

---

## Overview

This workflow guides a user from an unstructured idea to a production-ready PRD through iterative questioning, multi-agent analysis, and weighted validation.

**Expected Time**: 2-4 hours (depending on project complexity)

---

## Steps

### 1. Initialization

**Trigger**: User runs `forge start <project-name>`

**Actions**:
1. Create project directory: `/c/Users/User/AI/Projects/<project-name>/`
2. Create empty `prd.md` file from `core/templates/base-prd.md`
3. Initialize metadata:
   ```yaml
   project_name: <project-name>
   created_at: <timestamp>
   confidence: 0
   industry: unknown
   validated: false
   blockers: []
   ```

**Output**:
```
✅ Project created at: /c/Users/User/AI/Projects/<project-name>
ℹ️  Next: Answer discovery questions to build your PRD
```

---

### 2. Analyst Agent - Discovery Phase

**Agent**: `agents/analyst.md`

**Focus**: Problem statement, target users, market opportunity

**Questions** (from `lib/questions/core-discovery.json`):

#### Q1: Problem Statement
```
What problem does this solve?

(Be specific: What's broken? Why does it matter?)

Examples:
• "Personal trainers spend 10+ hours/week on spreadsheets"
• "Users can't visualize their fitness progress over time"

Your answer: _______________________________________________
```

**Impact**: Problem Statement (+10%)

#### Q2: Target Users
```
Who will use this? (Be specific: demographics, goals, pain points)

Examples:
• "Gym-goers aged 25-40 training for strength"
• "Personal trainers managing 10-50 clients"

Your answer: _______________________________________________
```

**Impact**: User Personas (+7%), User Stories (+5%)

#### Q3: Success Criteria
```
How will you know this is successful? What metrics matter?

Examples:
• "50 active trainers within 3 months"
• "80% client retention rate"

Your answer: _______________________________________________
```

**Impact**: Success Metrics (+15%)

#### Q4: Market Opportunity
```
Why now? What makes this the right time to build this?

Your answer: _______________________________________________
```

**Impact**: Problem Statement refinement

---

### 3. Feature Extraction

**Agent**: `agents/analyst.md`

**Purpose**: Identify explicit AND implied features

#### Explicit Features
Features the user **directly mentions**.

**Example**:
User says: "I want workout logging and progress tracking"

Explicit features:
- Workout logging
- Progress tracking

#### Implied Features
Features **required but not mentioned**.

**Example**:
User says: "I want workout logging"

Implied features (batch shown):
```
Based on "workout logging," I'm inferring these features:

✅ Approve All  |  ❌ Reject All  |  ✏️  Review Individually

1. User authentication (login/signup)
   → Reason: Need to know who owns the workout

2. Exercise database with search
   → Reason: Need exercises to log against

3. User roles (trainer vs client permissions)
   → Reason: User mentioned "trainers managing clients"

4. Data storage (workout history)
   → Reason: Need to save and retrieve workouts

5. Progress visualization (charts/graphs)
   → Reason: User mentioned "progress tracking"

Do you approve these implied features?
```

**User Options**:
- **Approve All**: Add all to feature list
- **Reject All**: Remove all
- **Review Individually**: Go through one by one

**Impact**: Feature List (+25%)

---

### 4. Industry Detection

**Agent**: `agents/analyst.md`

**Auto-detection based on keywords**:

| Keywords | Industry | Actions |
|----------|----------|---------|
| patients, PHI, HIPAA, medical | Healthcare | Add HIPAA compliance questions (+10% weight) |
| transactions, payments, banking | Fintech | Add PCI-DSS compliance questions (+10% weight) |
| products, cart, checkout | E-commerce | Add PCI-DSS compliance questions (+5% weight) |
| subscription, dashboard | SaaS | Standard weights, no additional |

**If Healthcare Detected**:
```
🏥 Healthcare Industry Detected

Additional compliance requirements will be added:
• HIPAA Compliance Plan (+5%)
• EHR Integration Spec (+3%)
• Data Privacy Policy (+2%)

Critical questions:
1. Will you store Protected Health Information (PHI)?
2. Do you need HIPAA compliance?
3. What EHR systems need integration?

Continue? [Y/n]
```

---

### 5. PM Agent - User Stories & Scope

**Agent**: `agents/pm.md`

**Focus**: User personas, Agile stories, MVP scope

#### User Personas (Minimum 2)

**Question**:
```
Let's create user personas. For each person who'll use this:
- Demographics (age, occupation, income if relevant)
- Goals (what they want to accomplish)
- Pain points (current frustrations)
- Tech savviness (beginner/intermediate/advanced)

Persona 1: _______________________________________________
```

**Impact**: User Personas (+7%)

#### User Stories

**Question**:
```
For [Persona Name], what are the key things they need to DO?

Format: "As a [persona], I want [goal], so that [benefit]"

Example:
"As a trainer, I want to see all my clients in one dashboard,
 so that I can quickly check who needs attention."

Story 1: _______________________________________________
Story 2: _______________________________________________
Story 3: _______________________________________________
```

**Impact**: User Stories (+5%)

#### MVP Scope

**Question**:
```
What MUST be in v1.0 to launch? What can wait for v2?

Must-Have (v1.0):
1. _______________________________________________
2. _______________________________________________

Should-Have (v2.0):
1. _______________________________________________

Could-Have (v3.0+):
1. _______________________________________________

Won't-Have (Out of Scope):
1. _______________________________________________
```

**Impact**: MVP Scope (+15%)

---

### 6. Architect Agent - Tech Stack

**Agent**: `agents/architect.md`

**Focus**: Technology decisions (100% required)

**Questions**:

#### Team Expertise
```
What frameworks/languages does your team have experience with?

Examples:
• "React + Node.js + PostgreSQL"
• "Rails + PostgreSQL"
• "No preference, open to recommendations"

Your answer: _______________________________________________
```

#### Feature Requirements
```
Based on your features, do you need:
[ ] Real-time updates (WebSockets)
[ ] Offline functionality (PWA, service workers)
[ ] Server-side rendering (SEO)
[ ] Complex data queries (relational DB)
[ ] File uploads (S3, Cloudinary)

Select all that apply.
```

#### Tech Stack Recommendations

**Output** (example for SaaS app):
```
Based on your requirements, I recommend:

Frontend: Next.js
• Reasoning: SSR for SEO, file-based routing, API routes
• Trade-offs: Steeper learning curve than CRA
• Alternatives: Remix (smaller community), Vite+React (no SSR)

Backend: Next.js API Routes
• Reasoning: Same codebase as frontend, fast iteration
• Trade-offs: Limited to JavaScript/TypeScript
• Alternatives: Express (more control), Rails (batteries-included)

Database: PostgreSQL
• Reasoning: Relational data (users, subscriptions), ACID compliance
• Trade-offs: More complex than NoSQL
• Alternatives: MongoDB (flexible schema), Firebase (all-in-one)

Auth: Clerk
• Reasoning: Beautiful UI, easy integration, generous free tier
• Trade-offs: Vendor lock-in
• Alternatives: Auth0 (more features), Supabase Auth (open-source)

Hosting: Vercel
• Reasoning: Seamless Next.js deployment, edge network
• Trade-offs: Cost at scale
• Alternatives: Railway (simpler), Render (cheaper)

Cost: $20-100/mo (Vercel Pro + Clerk + Supabase)

Do you approve this tech stack? [Y/n/modify]
```

**Impact**: Tech Stack (+20%)

**CRITICAL**: System will BLOCK if tech stack < 100%

---

### 7. Validator Agent - Quality Check

**Agent**: `agents/validator.md`

**Checks** (from `core/validation/hard-blocks.json`):

1. **Tech Stack Completeness** (CRITICAL)
   - All 5 components defined? (frontend, backend, database, auth, hosting)

2. **Feature Conflicts** (CRITICAL)
   - Real-time + Static hosting?
   - Offline-first + SSR?
   - Complex queries + NoSQL?

3. **Industry Compliance** (CRITICAL if applicable)
   - Healthcare: HIPAA plan exists?
   - Fintech: PCI-DSS plan exists?

4. **Feature Clarity** (CRITICAL)
   - Features have acceptance criteria?
   - Criteria specific (not vague)?

5. **Overall Confidence** (CRITICAL)
   - Calculate weighted score
   - Must be ≥ 95%

6. **MVP Scope** (WARNING)
   - Must/Should/Could defined?

7. **Success Metrics** (WARNING)
   - KPIs with targets?

**Output** (if 80.50% confidence):
```
╔═══════════════════════════════════════════════════════════╗
║            🔍 PRD VALIDATION REPORT                       ║
╚═══════════════════════════════════════════════════════════╝

Status: ❌ BLOCKED - Confidence below 95%

Current: 80.50%
Target: 95.00%
Gap: -14.50%

🚨 CRITICAL BLOCKERS (0): None
⚠️  WARNINGS (3):
1. User Stories incomplete (0%) - Need +5.00%
2. MVP Scope unclear (50%) - Need +7.50%
3. Success Metrics incomplete (75%) - Need +3.75%

Next Steps to 95%:
1. Complete User Stories → 85.50%
2. Complete MVP Scope → 93.00%
3. Complete Success Metrics → 96.75% ✅

Commands:
/forge-status - View detailed breakdown
/forge-fix low_confidence - Get guidance
```

---

### 8. Iterative Refinement

**If confidence < 95%**:

1. Show gaps in confidence breakdown
2. Ask targeted questions to fill gaps
3. Recalculate confidence
4. Repeat until 95%

**If blockers exist**:

1. Show blocker with resolution steps
2. Guide user through fix
3. Re-validate
4. Repeat until no blockers

---

### 9. GitHub Setup Offer

**Once confidence ≥ 95% AND no blockers**:

```
╔═══════════════════════════════════════════════════════════╗
║                 ✅ PRD COMPLETE (96.75%)                  ║
╚═══════════════════════════════════════════════════════════╝

Your PRD is ready for implementation!

Next step: Setup GitHub repository with CI/CD foundation

Run: forge setup-repo <project-name>

This will:
✅ Create .github/ with CI/CD workflows
✅ Create issue templates (feature, bug, enhancement)
✅ Create PR template
✅ Create scratchpads/ for Claude planning
✅ Generate README.md from PRD
✅ Copy .gitignore (framework-specific)
```

---

## Success Criteria

From-scratch workflow is successful when:
- ✅ PRD confidence ≥ 95%
- ✅ Zero critical blockers
- ✅ All 8 deliverables at target completion
- ✅ User ready to proceed to GitHub setup

---

**Generated by Forge v1.0**
