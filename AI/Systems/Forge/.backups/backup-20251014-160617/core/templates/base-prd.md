# Product Requirements Document
**Project:** {{project_name}}
**Industry:** {{industry_type}}
**Created:** {{timestamp}}
**Confidence:** {{confidence_score}}% {{progress_bar}}

---

## 1. Executive Summary
> **Agent:** Analyst (BMAD-inspired)
> **Confidence Weight:** 10%

### Problem Statement
{{problem_statement}}

**Why This Matters:**
{{problem_importance}}

**Current Solutions & Limitations:**
{{current_solutions}}

### Target Users
{{target_users}}

### Market Opportunity
{{market_opportunity}}

### Success Definition
{{success_criteria}}

---

## 2. User Insights
> **Agent:** PM (BMAD-inspired)
> **Confidence Weight:** 12% (Personas 7% + Stories 5%)

### User Personas
**Minimum:** 2 personas required for 100% completion

#### Persona 1: {{persona_1_name}}
- **Demographics:** {{demographics}}
- **Goals:** {{goals}}
- **Pain Points:** {{pain_points}}
- **Tech Savviness:** {{tech_level}}
- **Key Quote:** "{{quote}}"
- **Motivation:** {{motivation}}
- **Barriers:** {{barriers}}
- **Preferred Features:** {{preferred_features}}

#### Persona 2: {{persona_2_name}}
- **Demographics:** {{demographics}}
- **Goals:** {{goals}}
- **Pain Points:** {{pain_points}}
- **Tech Savviness:** {{tech_level}}
- **Key Quote:** "{{quote}}"
- **Motivation:** {{motivation}}
- **Barriers:** {{barriers}}
- **Preferred Features:** {{preferred_features}}

### User Stories
**Format:** As a [persona], I want [goal], so that [benefit]

#### High Priority (MVP)
1. As a {{persona}}, I want {{goal}}, so that {{benefit}}.
   - **Acceptance Criteria:**
     - [ ] {{criterion_1}}
     - [ ] {{criterion_2}}
     - [ ] {{criterion_3}}

2. As a {{persona}}, I want {{goal}}, so that {{benefit}}.
   - **Acceptance Criteria:**
     - [ ] {{criterion_1}}
     - [ ] {{criterion_2}}

#### Medium Priority (Post-MVP)
1. As a {{persona}}, I want {{goal}}, so that {{benefit}}.
   - **Acceptance Criteria:**
     - [ ] {{criterion_1}}

#### Low Priority (Future)
1. As a {{persona}}, I want {{goal}}, so that {{benefit}}.

---

## 3. Features & Requirements
> **Agent:** Analyst + Validator
> **Confidence Weight:** 25% (highest priority)

### Must-Have (MVP) ✅
**Status:** {{mvp_status}}

#### 1. {{feature_name_1}}
- **Description:** {{feature_description}}
- **User Value:** {{user_value}}
- **Acceptance Criteria:**
  - [ ] {{criterion_1}}
  - [ ] {{criterion_2}}
  - [ ] {{criterion_3}}
- **Dependencies:** {{dependencies}}
- **Confidence:** {{feature_confidence}}%
- **Priority Score:** {{priority_score}} (Value: {{value}}, Essential: {{essential}}, Effort: {{effort}}, Risk: {{risk}})

#### 2. {{feature_name_2}}
- **Description:** {{feature_description}}
- **User Value:** {{user_value}}
- **Acceptance Criteria:**
  - [ ] {{criterion_1}}
  - [ ] {{criterion_2}}
- **Dependencies:** {{dependencies}}
- **Confidence:** {{feature_confidence}}%
- **Priority Score:** {{priority_score}}

### Should-Have (Post-MVP) ⏳
#### 1. {{feature_name_3}}
- **Description:** {{feature_description}}
- **User Value:** {{user_value}}
- **Deferred Reason:** {{deferral_reason}}
- **Target Version:** v2.0

### Could-Have (Future) 💡
#### 1. {{feature_name_4}}
- **Description:** {{feature_description}}
- **Target Version:** v3.0+

### Won't-Have (Out of Scope) 🚫
#### 1. {{excluded_feature}}
- **Reason:** {{exclusion_reason}}

---

## 4. Technical Foundation
> **Agent:** Architect
> **Confidence Weight:** 23% (Tech Stack 20% + Non-Functional 3%)

### Tech Stack
**🚨 BLOCKER:** Must be 100% complete to proceed

#### Frontend
- **Framework:** {{frontend_framework}}
- **Reasoning:** {{frontend_reasoning}}
- **Trade-offs:** {{frontend_tradeoffs}}
- **Alternatives Considered:** {{frontend_alternatives}}

#### Backend
- **Language/Framework:** {{backend_framework}}
- **Reasoning:** {{backend_reasoning}}
- **Trade-offs:** {{backend_tradeoffs}}
- **Alternatives Considered:** {{backend_alternatives}}

#### Database
- **Type:** {{database_type}}
- **Reasoning:** {{database_reasoning}}
- **Trade-offs:** {{database_tradeoffs}}
- **Alternatives Considered:** {{database_alternatives}}

#### Authentication
- **Provider:** {{auth_provider}}
- **Reasoning:** {{auth_reasoning}}
- **Trade-offs:** {{auth_tradeoffs}}
- **Alternatives Considered:** {{auth_alternatives}}

#### Hosting/Deployment
- **Platform:** {{hosting_platform}}
- **Reasoning:** {{hosting_reasoning}}
- **Trade-offs:** {{hosting_tradeoffs}}
- **Alternatives Considered:** {{hosting_alternatives}}
- **Estimated Cost:** {{hosting_cost}}/month

### Third-Party Integrations
#### 1. {{integration_name}}
- **Purpose:** {{integration_purpose}}
- **Provider:** {{integration_provider}}
- **API/SDK:** {{integration_api}}
- **Cost:** {{integration_cost}}

### Non-Functional Requirements
#### Performance
- **Target:** {{performance_target}}
- **Measurement:** {{performance_measurement}}

#### Security
- **Requirements:** {{security_requirements}}
- **Compliance:** {{security_compliance}}

#### Scalability
- **Initial:** {{scalability_initial}}
- **6 Months:** {{scalability_6mo}}
- **1 Year:** {{scalability_1yr}}

#### Accessibility
- **Standards:** {{accessibility_standards}}
- **Target:** {{accessibility_target}}

---

## 5. Success Metrics
> **Agent:** PM + Analyst
> **Confidence Weight:** 15%

### KPIs (Key Performance Indicators)
#### 1. {{kpi_name_1}}
- **Target:** {{kpi_target_1}}
- **Measurement Method:** {{kpi_measurement_1}}
- **Timeline:** {{kpi_timeline_1}}
- **Importance:** {{kpi_importance_1}}

#### 2. {{kpi_name_2}}
- **Target:** {{kpi_target_2}}
- **Measurement Method:** {{kpi_measurement_2}}
- **Timeline:** {{kpi_timeline_2}}
- **Importance:** {{kpi_importance_2}}

#### 3. {{kpi_name_3}}
- **Target:** {{kpi_target_3}}
- **Measurement Method:** {{kpi_measurement_3}}
- **Timeline:** {{kpi_timeline_3}}
- **Importance:** {{kpi_importance_3}}

### Acceptance Criteria (MVP Launch)
- [ ] {{launch_criterion_1}}
- [ ] {{launch_criterion_2}}
- [ ] {{launch_criterion_3}}
- [ ] {{launch_criterion_4}}

### MVP Success Definition
The MVP is successful if:
{{mvp_success_definition}}

---

## 6. MVP Scope
> **Agent:** PM + Validator
> **Confidence Weight:** 15%

### What's In (v1.0) ✅
1. {{in_scope_item_1}}
2. {{in_scope_item_2}}
3. {{in_scope_item_3}}
4. {{in_scope_item_4}}
5. {{in_scope_item_5}}

### What's Deferred (v2.0+) ⏳
1. {{deferred_item_1}}
   - **Reason:** {{deferral_reason_1}}
   - **Target Version:** v2.0

2. {{deferred_item_2}}
   - **Reason:** {{deferral_reason_2}}
   - **Target Version:** v2.0

### Timeline Estimate (Optional)
- **Discovery → PRD:** {{timeline_prd}} weeks (COMPLETED)
- **Architecture:** {{timeline_architecture}} weeks (NOT included in Phase 1)
- **Development:** {{timeline_development}} weeks (NOT included in Phase 1)
- **Testing:** {{timeline_testing}} weeks (NOT included in Phase 1)
- **Launch:** {{timeline_launch}} (estimated)

---

## 7. Research & Context
> **Agent:** Analyst
> **Auto-Generated Based on Industry**

### Industry-Specific Requirements
{{industry_requirements}}

### Compliance Needs
{{compliance_requirements}}

#### {{compliance_type_1}} (if applicable)
- **Requirements:** {{compliance_requirements_1}}
- **Implementation:** {{compliance_implementation_1}}
- **Validation:** {{compliance_validation_1}}

### Competitive Analysis (Optional)
{{competitive_analysis}}

#### Competitor 1: {{competitor_1_name}}
- **Strengths:** {{competitor_1_strengths}}
- **Weaknesses:** {{competitor_1_weaknesses}}
- **Differentiation:** {{differentiation_1}}

---

## Metadata (YAML)
```yaml
confidence: {{confidence_score}}
industry: {{industry_type}}
validated: {{validation_status}}
blockers:
  - {{blocker_1}}
  - {{blocker_2}}
deliverables:
  problem_statement: {{problem_statement_pct}}%
  user_personas: {{user_personas_pct}}%
  user_stories: {{user_stories_pct}}%
  feature_list: {{feature_list_pct}}%
  tech_stack: {{tech_stack_pct}}%
  success_metrics: {{success_metrics_pct}}%
  mvp_scope: {{mvp_scope_pct}}%
  non_functional: {{non_functional_pct}}%
created_at: {{created_timestamp}}
updated_at: {{updated_timestamp}}
version: {{prd_version}}
```

---

## Validation Status

**Last Validated:** {{validation_timestamp}}
**Validated By:** Validator Agent

### Confidence Breakdown
```
{{deliverable_1}} ({{pct_1}}%) × {{weight_1}} = {{contribution_1}}%
{{deliverable_2}} ({{pct_2}}%) × {{weight_2}} = {{contribution_2}}%
{{deliverable_3}} ({{pct_3}}%) × {{weight_3}} = {{contribution_3}}%
{{deliverable_4}} ({{pct_4}}%) × {{weight_4}} = {{contribution_4}}%
{{deliverable_5}} ({{pct_5}}%) × {{weight_5}} = {{contribution_5}}%
{{deliverable_6}} ({{pct_6}}%) × {{weight_6}} = {{contribution_6}}%
{{deliverable_7}} ({{pct_7}}%) × {{weight_7}} = {{contribution_7}}%
{{deliverable_8}} ({{pct_8}}%) × {{weight_8}} = {{contribution_8}}%
────────────────────────────────────────────────────────────
Total Confidence: {{total_confidence}}%

{{status_message}}
```

### Hard Blocks
- [{{tech_stack_status}}] Tech Stack Complete
- [{{conflicts_status}}] No Conflicting Features
- [{{compliance_status}}] Industry Compliance Addressed
- [{{confidence_status}}] Confidence ≥ 95%
- [{{clarity_status}}] Features have acceptance criteria

---

## Change Log

### {{version_number}} - {{change_date}}
- {{change_description_1}}
- {{change_description_2}}
- **Confidence Impact:** {{confidence_change}}

---

**Generated by Forge v1.0**
**System Location:** `/c/Users/User/AI/Systems/Forge/`
**Project Location:** `/c/Users/User/AI/Projects/{{project_name}}/`
**Documentation:** See `docs/` folder for detailed guides
