# Checkpoint & Visual Indicator System

## Stage Progression Visual Template
```
╔═════════════════════════════════════════════════════════════╗
║  🏢 ENTERPRISE SYSTEM - PROJECT PROGRESS DASHBOARD         ║
╠═════════════════════════════════════════════════════════════╣
║                                                             ║
║    ██████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 67% Complete        ║
║    Stage 2A: Feature Discovery                              ║
║                                                             ║
║  ✅ Stage 1: Technical Requirements (APPROVED) ────────────┐║
║  🔄 Stage 2A: Feature Discovery (IN PROGRESS - 67%) ───────┤║
║  ⏳ Stage 2B: Research & Refinement (PENDING) ─────────────┤║
║  ⏳ Stage 3A: Design Discovery & Branching (PENDING) ──────┤║
║  ⏳ Stage 3B: Clone OR Original Design (PENDING) ──────────┤║
║  ⏳ Stage 4: Implementation & Delivery (PENDING) ──────────┘║
║                                                             ║
║  🚨 NEXT ACTION REQUIRED:                                   ║
║  ➤ Feature List Approval Required                           ║
║  ➤ Review PRD and approve features to proceed               ║
║                                                             ║
╚═════════════════════════════════════════════════════════════╝
```

## Mandatory Approval Gate Template
```
╔═══════════════════════════════════════════════════════════════╗
║  🛑 CRITICAL CHECKPOINT: Stage 2A → 2B                       ║
║  ═══════════════════════════════════════════════════════════  ║
║                                                               ║
║  📋 DELIVERABLES STATUS:                                      ║
║  ✅ Product Requirements Document ──────────── COMPLETE       ║
║  ✅ Feature Specifications ─────────────────── COMPLETE       ║
║  ✅ User Flow Mapping ──────────────────────── COMPLETE       ║
║                                                               ║
║  🎯 FEATURE SUMMARY FOR APPROVAL:                            ║
║  ┌─────────────────────────────────────────────────────────┐ ║
║  │ • [Feature 1]: [Brief description]                     │ ║
║  │ • [Feature 2]: [Brief description]                     │ ║
║  │ • [Feature 3]: [Brief description]                     │ ║
║  └─────────────────────────────────────────────────────────┘ ║
║                                                               ║
║  ❓ Ready to proceed to Industry Research Phase?             ║
║                                                               ║
║  ⚡ REQUIRED RESPONSE:                                        ║
║  ┌─────────────────────────────────────────────────────────┐ ║
║  │  Type: "APPROVED" to continue                           │ ║
║  │     or "ADD MORE FEATURES" to expand scope              │ ║
║  └─────────────────────────────────────────────────────────┘ ║
╚═══════════════════════════════════════════════════════════════╝
```

## Meta-Analyst Silent Log Template
```
🔍 Meta-Analyst: [VIOLATION_TYPE] detected → Report: [REPORT_ID]
```

## Usage Instructions

### **For Agents**
1. Display stage indicator at start of each major response
2. Show approval gate when stage completion reached
3. Never proceed without explicit "APPROVED" response
4. Update visual progress in real-time

### **For Users**  
- `/status` command shows current project progress
- Visual indicators show exactly where you are in process
- Approval gates clearly show what needs to be approved
- Can add features at any checkpoint

### **Critical Rules**
- **NEVER** skip approval gates
- **ALWAYS** show deliverables before requesting approval
- **WAIT** for explicit approval before proceeding
- **UPDATE** visuals in real-time during conversations
- **DISPLAY** progress dashboard at start of each major response
- **HIGHLIGHT** current stage and next required action prominently

## Status Command Implementation
```
/status - Show complete project progress dashboard
/stage - Show current stage details and next steps
/deliverables - Show current stage deliverable checklist
/checkpoint - Force approval gate display for current stage

# ONEREADOAK 7-PHASE CLONING SPECIFIC COMMANDS
/clone-progress - Show 7-phase cloning progress with component status
/clone-status - Display triage matrix results and evidence package
/clone-website "url" - Initiate automated 7-phase cloning workflow
```

## OneRedOak 7-Phase Cloning Progress Template
```
╔════════════════════════════════════════════════════════════════╗
║  🌳 ONEREADOAK WEBSITE CLONING PROGRESS                       ║
║  ════════════════════════════════════════════════════════════  ║
║                                                                ║
║  🎯 Target: https://example.com                               ║
║  ████████████████████▓▓▓▓▓▓▓ Phase 5/7 (71% Complete)         ║
║                                                                ║
║  ✅ Phase 1: Preparation - Original Analysis ─────── COMPLETE ║
║  ✅ Phase 2: Component Mapping ──────────────────── COMPLETE ║
║  ✅ Phase 3: Iterative Building ────────────────── COMPLETE ║
║      └─ 12/12 components approved with evidence               ║
║  ✅ Phase 4: Responsiveness Validation ────────── COMPLETE ║
║      └─ 3/3 viewports validated (Desktop/Tablet/Mobile)       ║
║  🔄 Phase 5: Interaction Testing ─────────────── IN PROGRESS ║
║      └─ Hover/Click/Focus states (67% complete)               ║
║  ⏳ Phase 6: Visual Polish Validation ─────────────── PENDING ║
║  ⏳ Phase 7: Final Human Approval ────────────────── PENDING ║
║                                                                ║
║  📊 AUTOMATION STATUS:                                         ║
║  ├─ Evidence Package: 47 screenshots, 12 triage assessments   ║
║  ├─ Clone Preview: http://localhost:3000                      ║
║  └─ Current Task: Validating interactive elements             ║
║                                                                ║
║  🔄 NEXT: Complete hover/click/focus state validation          ║
╚════════════════════════════════════════════════════════════════╝
```

## Component-Level Progress Tracking
```
╔══════════════════════════════════════════════════════════════════╗
║  🧩 COMPONENT VALIDATION DASHBOARD                              ║
║  ═══════════════════════════════════════════════════════════════  ║
║                                                                  ║
║  ████████████████████████▓▓▓▓▓▓▓▓ 9/12 Components (75%)         ║
║                                                                  ║
║  ✅ Header component ─────────────── APPROVED                   ║
║     └─ Evidence: 3 screenshots, 98% similarity                  ║
║  ✅ Navigation component ────────── APPROVED                   ║
║     └─ Evidence: 4 screenshots, 97% similarity                  ║
║  ✅ Hero section ────────────────── APPROVED                   ║
║     └─ Evidence: 6 screenshots, 99% similarity                  ║
║  🔄 Gallery component ───────────── IN_PROGRESS (89%)          ║
║     ├─ [🚨 HIGH-PRIORITY] Color mismatch: #f8f9fa → #ffffff    ║
║     └─ [⚠️  MEDIUM] Padding adjustment: 8px → 12px              ║
║  ⏳ Contact section ─────────────── PENDING                    ║
║  ⏳ Footer component ────────────── PENDING                    ║
║                                                                  ║
║  🎯 CURRENT FOCUS: Gallery component refinement                 ║
║  📋 NEXT ACTIONS:                                               ║
║  ├─ Fix high-priority color inconsistencies                     ║
║  ├─ Apply padding adjustments                                   ║
║  └─ Re-validate with evidence capture                           ║
╚══════════════════════════════════════════════════════════════════╝
```

## Stage-Specific Templates

### Stage 1: Technical Requirements
```
**📋 STAGE 1: TECHNICAL REQUIREMENTS (Confidence: 33%)**
Objective: Build technical foundation & constraints

✅ Project type identified
🔄 Tech stack preferences (IN PROGRESS)
⏳ Performance constraints (PENDING)
⏳ Integration requirements (PENDING)
⏳ Deployment preferences (PENDING)

Current Question: "What performance requirements do you have?"
To Proceed: Reach 85%+ confidence before Stage 2
```

### Stage 2A: Feature Discovery
```
**🚀 STAGE 2A: FEATURE DISCOVERY (Progress: 67%)**
Objective: Define all features & user workflows

✅ Core features defined
✅ User workflows mapped
🔄 Feature specifications (IN PROGRESS)
⏳ Acceptance criteria (PENDING)
⏳ MVP scope boundaries (PENDING)

Deliverables: PRD, Feature Specs, Site Map
Next: Complete feature specs for approval gate
```

### Branching Decision Templates

#### Path A: Website Cloning
```
**🌳 PATH A: ONEREADOAK CLONING SELECTED**
Target: [User Selected Website]
Automation: 95%+ accuracy with minimal intervention

Pipeline Status:
✅ Microsoft Playwright MCP (CONNECTED)
✅ Evidence-based validation (ACTIVE)
✅ Triage matrix system (READY)
✅ Self-contained iteration (ENABLED)

Next: Begin Phase 1 - Preparation & Analysis
```

#### Path B: Original Design
```
**🎨 PATH B: ORIGINAL DESIGN SELECTED**
Approach: Evidence-based original creation
Collaboration: High user involvement required

Pipeline Status:
✅ Style Guide Builder (READY)
✅ Live preview system (ACTIVE)
✅ Component library (LOADED)
✅ Iterative approval (ENABLED)

Next: Create live style guide at localhost:3000/style-guide
```

### Quick Status Commands
```
**📱 STATUS COMMANDS**
/status - Full project dashboard
/where-am-i - Current location & next steps
/progress - Stage progress percentages
/checkpoint - Force approval gate display
/clone-progress - OneRedOak 7-phase status
/clone-status - Triage matrix & evidence
```