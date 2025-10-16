# Import-PRD Workflow
**Command**: `forge import <project-name> <prd-file>`
**Purpose**: Import existing PRD, validate, and fill gaps to reach 95% confidence

---

## Overview

This workflow takes an existing PRD document and:
1. Parses it to extract deliverables
2. Maps to Forge structure
3. Calculates confidence score
4. Identifies gaps
5. Asks targeted questions to fill gaps
6. Validates to 95%

**Expected Time**: 30 minutes - 2 hours (depending on PRD completeness)

---

## Steps

### 1. Initialization

**Trigger**: User runs `forge import <project-name> <prd-file>`

**Actions**:
1. Verify PRD file exists
2. Create project directory: `/c/Users/User/AI/Projects/<project-name>/`
3. Copy PRD file to `prd.md`
4. Initialize metadata:
   ```yaml
   project_name: <project-name>
   created_at: <timestamp>
   imported_from: <prd-file>
   confidence: 0
   industry: unknown
   validated: false
   blockers: []
   ```

**Output**:
```
✅ Project created at: /c/Users/User/AI/Projects/<project-name>
✅ PRD imported from: <prd-file>
ℹ️  Validator Agent will now analyze your PRD...
```

---

### 2. Validator Agent - Parsing Phase

**Agent**: `agents/validator.md`

**Purpose**: Parse existing PRD and map to Forge deliverables

**Parsing Strategy**:

#### Look for Section Headers
```markdown
Common variations:
- "Problem Statement" OR "Problem" OR "Overview" OR "Executive Summary"
- "Users" OR "Target Audience" OR "Personas" OR "User Personas"
- "Features" OR "Requirements" OR "Functional Requirements"
- "Tech Stack" OR "Technology" OR "Technical Architecture"
- "Success Metrics" OR "KPIs" OR "Goals"
- "MVP" OR "Scope" OR "Phase 1"
- "User Stories" OR "Stories"
- "Non-Functional Requirements" OR "NFRs" OR "Performance/Security"
```

#### Extract Content
For each section found:
1. Extract text content
2. Assess completion (0-100%)
3. Map to Forge deliverable

**Example Mapping**:
```
Found: "## Problem Statement"
Content: "Personal trainers struggle to track client progress..."
Assessment: 100% (clear, specific, explains why it matters)
Maps to: problem_statement
```

---

### 3. Gap Analysis

**Agent**: `agents/validator.md`

**Calculate Initial Confidence**:

```
Deliverable Analysis:

✅ Problem Statement (100%)
✅ Target Users (100%)
✅ Feature List (100%)
⚠️  Tech Stack (60%) - Missing: Auth, Hosting
❌ Success Metrics (0%) - Not found
⚠️  MVP Scope (50%) - Features listed but no v2+ deferrals
⚠️  User Personas (50%) - Users mentioned but no detailed personas
❌ User Stories (0%) - Not found
⚠️  Non-Functional (25%) - Security mentioned, but performance/scalability missing

Initial Confidence: 67%
Target: 95%
Gap: -28%
```

**Output**:
```
╔═══════════════════════════════════════════════════════════╗
║         IMPORTED PRD ANALYSIS - Fitness Tracker           ║
╚═══════════════════════════════════════════════════════════╝

Initial Confidence: 67% ▓▓▓▓▓▓▓░░░

✅ COMPLETE (4):
├─ Problem Statement (100%)
├─ Target Users (100%)
├─ Feature List (100%)
└─ (some fields populated)

⚠️  INCOMPLETE (4):
├─ Tech Stack (60%) - Missing: Auth, Hosting
├─ MVP Scope (50%) - No v2+ deferrals
├─ User Personas (50%) - Lacks detail
└─ Non-Functional (25%) - Missing: Performance, Scalability

❌ MISSING (2):
├─ Success Metrics (0%)
└─ User Stories (0%)

Gap to 95%: -28%
Estimated time to fill: 1-2 hours
```

---

### 4. Targeted Questioning

**Agent**: Analyst, PM, Architect (depending on gap)

**Strategy**: Ask ONLY about missing/incomplete items

#### Example: Missing Success Metrics

**PM Agent asks**:
```
Your PRD is missing success metrics (KPIs).

How will you know this is successful? What metrics matter?

Examples:
• "50 active trainers within 3 months"
• "80% client retention rate"
• "Trainers save 5+ hours/week"

Please provide 3-5 KPIs with target values:

KPI 1: _______________________________________________
Target: _______________________________________________
Timeline: _______________________________________________

KPI 2: _______________________________________________
Target: _______________________________________________
Timeline: _______________________________________________
```

**Impact**: Success Metrics (+15%)

#### Example: Incomplete Tech Stack

**Architect Agent asks**:
```
Your PRD has partial tech stack (frontend, backend, database defined).

Missing components:
❌ Authentication Provider
❌ Hosting Platform

Let me recommend based on your stack (React + Node.js + PostgreSQL):

Auth: Clerk
• Beautiful UI, easy React integration, generous free tier
• Alternative: Auth0 (more features), Supabase Auth (open-source)

Hosting: Render
• Easy Node.js deployment, PostgreSQL included, $20/mo
• Alternative: Railway (simpler), Vercel (for Next.js)

Do you approve? [Y/n/modify]
```

**Impact**: Tech Stack (+8% to reach 100%)

#### Example: Missing User Stories

**PM Agent asks**:
```
Your PRD lists features but no user stories.

Let me convert your features into Agile user stories:

Feature: "Workout logging"
Story: "As a gym-goer, I want to log my workouts with exercises,
        sets, reps, and weight, so that I can track my progress
        over time."

Feature: "Trainer dashboard"
Story: "As a trainer, I want to see all my clients in one dashboard,
        so that I can quickly check who needs attention."

[Continue for all features...]

Approve these stories? [Y/n/modify]
```

**Impact**: User Stories (+5%)

---

### 5. Industry Detection & Compliance

**Agent**: `agents/analyst.md`

**Auto-detect from existing PRD content**:

```
Detected keywords: "personal trainers", "clients", "workout", "progress"
Industry: SaaS (Fitness)

No additional compliance requirements.
```

**If Healthcare/Fintech/E-commerce detected**:
```
🏥 Healthcare Keywords Detected: "patients", "medical records"

Additional compliance requirements needed:
❌ HIPAA Compliance Plan (not found)
❌ PHI Handling Protocol (not found)
❌ Data Encryption Spec (not found)

Critical questions:
1. Will you store Protected Health Information (PHI)? [Y/n]
2. Do you need HIPAA compliance? [Y/n]
3. What EHR systems need integration? _______________
```

---

### 6. Iterative Refinement

**Loop until confidence ≥ 95%**:

1. Ask targeted question for highest-impact gap
2. User answers
3. Update PRD with answer
4. Recalculate confidence
5. Show updated confidence
6. Repeat

**Progress Display**:
```
Round 1: 67% → 82% (+15% from Success Metrics)
Round 2: 82% → 90% (+8% from Tech Stack completion)
Round 3: 90% → 95% (+5% from User Stories)

✅ Target reached: 95%
```

---

### 7. Validator Agent - Final Validation

**Agent**: `agents/validator.md`

**Run full validation** (same as from-scratch workflow):

1. Tech Stack Completeness (100% required)
2. Feature Conflicts (none allowed)
3. Industry Compliance (if applicable)
4. Feature Clarity (acceptance criteria exist)
5. Overall Confidence (≥ 95%)
6. MVP Scope (warning if < 75%)
7. Success Metrics (warning if < 75%)

**Output**:
```
╔═══════════════════════════════════════════════════════════╗
║            🔍 PRD VALIDATION REPORT                       ║
╚═══════════════════════════════════════════════════════════╝

Running validation sequence...

[1/7] ✅ Tech Stack Complete (100%)
[2/7] ✅ No Feature Conflicts Detected
[3/7] ✅ Compliance Check: SaaS (No specific requirements)
[4/7] ✅ Feature Clarity Verified
[5/7] ✅ Overall Confidence: 96% (Target: 95%)
[6/7] ✅ MVP Scope Clear (100%)
[7/7] ✅ Success Metrics Complete (100%)

╔═══════════════════════════════════════════════════════════╗
║                          SUMMARY                          ║
╚═══════════════════════════════════════════════════════════╝

Status: ✅ READY FOR GITHUB SETUP

Confidence: 96%
Critical Blockers: 0
Warnings: 0

Your imported PRD has been validated and enhanced to meet
Forge standards.
```

---

### 8. GitHub Setup Offer

**Once confidence ≥ 95% AND no blockers**:

```
╔═══════════════════════════════════════════════════════════╗
║            ✅ IMPORTED PRD VALIDATED (96%)                ║
╚═══════════════════════════════════════════════════════════╝

Your PRD has been successfully imported and validated!

Changes made:
• Added Success Metrics (5 KPIs with targets)
• Completed Tech Stack (Auth: Clerk, Hosting: Render)
• Added User Stories (8 stories in Agile format)
• Enhanced User Personas (2 detailed personas)
• Defined MVP Scope (Must/Should/Could/Won't)

Next step: Setup GitHub repository with CI/CD foundation

Run: forge setup-repo <project-name>
```

---

## Edge Cases

### PRD in Different Format

**If not markdown**:

```
⚠️  PRD file is not markdown (.md)

Detected format: {{format}} (.docx, .pdf, .txt, etc.)

Please convert to markdown first:
1. Copy content from {{format}}
2. Save as .md file
3. Run: forge import <project-name> <new-file>.md

Or: Paste content directly when prompted [Y/n]
```

**If user chooses to paste**:
1. Prompt for pasted content
2. Parse as plain text
3. Extract sections manually
4. Continue with gap analysis

### PRD with Custom Structure

**If section headers don't match**:

```
ℹ️  Custom PRD structure detected

Could not auto-map these sections:
• "Our Vision" (unknown mapping)
• "Market Analysis" (unknown mapping)

Please map manually:
"Our Vision" maps to:
[1] Problem Statement
[2] Market Opportunity
[3] Skip this section

Your choice: _______________
```

### PRD with Conflicts

**If imported PRD has conflicting features**:

```
🚨 CRITICAL: Conflicting Features Detected in Imported PRD

Conflict:
Feature: "Real-time collaboration"
Tech Stack: "Static site hosting (Netlify)"

Reason: Static sites cannot maintain WebSocket connections

This conflict existed in your original PRD.

Resolution (choose one):
A) Remove real-time features
B) Change hosting to dynamic (Render, Railway)
C) Use third-party service (Pusher, Ably)

Your choice: _______________
```

---

## Success Criteria

Import-PRD workflow is successful when:
- ✅ Existing PRD parsed and mapped
- ✅ Initial confidence calculated
- ✅ Gaps identified and filled
- ✅ Final confidence ≥ 95%
- ✅ Zero critical blockers
- ✅ User ready to proceed to GitHub setup

---

## Comparison: Import vs From-Scratch

| Aspect | From-Scratch | Import-PRD |
|--------|--------------|------------|
| **Starting Point** | Vague idea | Existing PRD document |
| **Questions Asked** | All discovery questions | Only gap-filling questions |
| **Time Required** | 2-4 hours | 30 min - 2 hours |
| **Confidence Start** | 0% | 40-80% (varies) |
| **Agents Involved** | All 4 agents | Mostly Validator, some gaps filled by others |
| **Use Case** | New project | PRD already exists, needs validation/enhancement |

---

**Generated by Forge v1.0**
