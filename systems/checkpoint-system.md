# Checkpoint & Visual Indicator System

## Stage Progression Visual Template
```
┌─────────────────────────────────────────────────────────────┐
│  ENTERPRISE UI BUILDER - PROJECT PROGRESS                  │
├─────────────────────────────────────────────────────────────┤
│  [●●●○○] Stage 2A: Feature Discovery                       │
│                                                             │
│  ✅ Stage 1: Technical Requirements (APPROVED)             │
│  🔄 Stage 2A: Feature Discovery (IN PROGRESS - 67%)        │
│  ⏳ Stage 2B: Research & Refinement (PENDING)              │
│  ⏳ Stage 3A: Design Discovery (PENDING)                   │
│  ⏳ Stage 3B: Style Guide Creation (PENDING)               │
│                                                             │
│  Next Checkpoint: Feature List Approval Required           │
└─────────────────────────────────────────────────────────────┘
```

## Mandatory Approval Gate Template
```
┌─────────────────────────────────────────────┐
│  🚨 CHECKPOINT: Stage 2A → 2B               │
├─────────────────────────────────────────────┤
│  Deliverables Complete:                     │
│  ✅ Product Requirements Document           │
│  ✅ Feature Specifications                  │
│  ✅ User Flow Mapping                       │
│                                             │
│  📋 Feature Summary:                        │
│  • [Feature 1]: [Brief description]        │
│  • [Feature 2]: [Brief description]        │
│  • [Feature 3]: [Brief description]        │
│                                             │
│  Ready to proceed to Industry Research?    │
│                                             │
│  ⚡ Type: APPROVED / ADD MORE FEATURES      │
└─────────────────────────────────────────────┘
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

## Status Command Implementation
```
/status - Show complete project progress dashboard
/stage - Show current stage details and next steps  
/deliverables - Show current stage deliverable checklist
/checkpoint - Force approval gate display for current stage
```