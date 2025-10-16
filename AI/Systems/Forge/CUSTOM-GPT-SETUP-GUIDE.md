# Custom GPT Setup Guide for Forge

## Overview
This guide shows how to create two Custom GPTs in ChatGPT for the Forge workflow:
1. **Forge PRD Agent** - Creates Product Requirements Documents
2. **Forge IA Agent** - Creates Information Architecture

---

## 1. Forge PRD Agent Setup

### Step 1: Create Custom GPT
1. Go to https://chat.openai.com/gpts/editor
2. Click "Create a GPT"
3. Name: **Forge PRD Agent**
4. Description: **Transform vague product ideas into 95%+ confidence PRDs through structured discovery interviews**

### Step 2: Add Instructions
Copy the entire contents of `CUSTOM-GPT-PRD-INSTRUCTIONS.md` into the Instructions field.

**Character count**: 6,475 chars (fits within 8000 limit)

### Step 3: Configure Settings
- **Conversation starters**:
  - "Help me create a PRD for a new SaaS product"
  - "I have an app idea but it's not fully formed yet"
  - "Start PRD discovery interview"
  - "Create PRD from scratch"

- **Knowledge**: None required (all logic in instructions)
- **Capabilities**:
  - ✅ Web Browsing (for tech stack research)
  - ✅ Code Interpreter (not needed but doesn't hurt)
  - ❌ DALL-E (not needed)

- **Actions**: None required

### Step 4: Test
Test with: "Help me create a PRD for a fitness tracking app"

Expected behavior:
- Asks Q1: "What problem does this solve?"
- Waits for answer before moving to Q2
- Shows inferred features in batches for approval
- Outputs complete PRD in correct markdown format

### Step 5: Publish
- Set to "Only me" (private)
- Or "Anyone with link" if sharing with team
- Save Custom GPT

---

## 2. Forge IA Agent Setup

### Step 1: Create Custom GPT
1. Go to https://chat.openai.com/gpts/editor
2. Click "Create a GPT"
3. Name: **Forge IA Agent**
4. Description: **Transform PRDs into Information Architecture (sitemap, flows, navigation) for implementation**

### Step 2: Add Instructions
Copy the entire contents of `CUSTOM-GPT-IA-INSTRUCTIONS.md` into the Instructions field.

**Character count**: ~5,847 chars (fits within 8000 limit)

*(Note: We created this earlier in the conversation - it's the condensed version)*

### Step 3: Configure Settings
- **Conversation starters**:
  - "Create IA from my PRD"
  - "Start IA design interview"
  - "Transform PRD into sitemap and flows"
  - "Begin information architecture phase"

- **Knowledge**: None required
- **Capabilities**:
  - ✅ Web Browsing (for competitive research)
  - ❌ Code Interpreter
  - ❌ DALL-E

- **Actions**: None required

### Step 4: Test
Test by pasting a sample PRD and verifying:
- Asks about application type
- Conducts sitemap interview
- Maps PRD features to pages
- Outputs `[FORGE_IA_START]...[FORGE_IA_END]` block

### Step 5: Publish
- Set to "Only me" (private)
- Save Custom GPT

---

## 3. Complete Workflow

### Phase 1: PRD Creation
1. Open **Forge PRD Agent** Custom GPT
2. Say: "Help me create a PRD for [your idea]"
3. Answer discovery questions
4. Review and approve implied features
5. Complete tech stack selection
6. **Copy final PRD markdown**
7. Save to `prd.md` in your project directory
8. Run `forge status` to validate (target: 95%+ confidence)

### Phase 2: IA Creation
1. Open **Forge IA Agent** Custom GPT
2. Paste your completed PRD
3. Answer sitemap interview questions
4. Review page structure
5. **Copy output block** `[FORGE_IA_START]...[FORGE_IA_END]`
6. Run `forge import-ia` in project directory
7. Paste IA block when prompted
8. Review generated files in `ia/` directory

### Phase 3: Implementation
1. (Optional) Paste IA block into Claude Project for Mermaid visualization
2. Open project in Cursor
3. Reference `prd.md` and `ia/*.md` files
4. Begin implementation with AI assistance

---

## Tips & Best Practices

### For PRD Creation:
- **Be specific** - Vague answers get pushed back on
- **Approve features in batches** - Saves time vs one-by-one
- **Justify tech choices** - Agent will explain trade-offs
- **Target 95%+ confidence** - Don't settle for less
- **Save frequently** - Copy PRD sections as you go

### For IA Creation:
- **Complete PRD first** - IA Agent validates against PRD features
- **Think about user journeys** - Not just page lists
- **Consider auth boundaries** - Public vs authenticated pages
- **Map features to pages** - Ensure nothing is missed
- **Target 75-80% confidence** - IA will evolve during implementation

### For Both:
- **Use ChatGPT free tier** - Saves premium tokens for coding
- **Iterate as needed** - Can revisit and refine anytime
- **Keep sessions focused** - One PRD or IA per session
- **Export markdown** - Always save local copies

---

## Troubleshooting

### PRD Agent Issues:
**Problem**: Output format is wrong
- **Fix**: Say "Output in exact markdown format from instructions"

**Problem**: Not asking questions sequentially
- **Fix**: Say "Ask questions one at a time, wait for my answer"

**Problem**: Not showing implied features
- **Fix**: Say "Show inferred features in batch format for approval"

### IA Agent Issues:
**Problem**: Missing `[FORGE_IA_START]` markers
- **Fix**: Say "Output with FORGE_IA_START and FORGE_IA_END markers"

**Problem**: Not all PRD features mapped
- **Fix**: Say "Validate all PRD features are mapped to pages"

**Problem**: Sections incomplete
- **Fix**: Say "Include all required sections: SITEMAP, USER_FLOWS, NAVIGATION"

### Terminal Issues:
**Problem**: `forge import-ia` rejects format
- **Fix**: Ensure you copied complete block including markers

**Problem**: PRD validation shows <90% confidence
- **Fix**: Add missing sections to `prd.md` and re-run `forge status`

---

## Next Steps

After setup:
1. Test both Custom GPTs with a sample project
2. Verify `forge import-ia` accepts IA output
3. Refine Custom GPT instructions if needed
4. Document any team-specific customizations
5. Begin using for real projects

---

**Generated by Forge v1.0**
