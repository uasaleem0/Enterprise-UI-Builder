# Enterprise UI Builder - Complete Command Reference

## MASTER_WORKFLOW_COMMANDS

### PROJECT_INITIATION
```bash
/start-enterprise-project "project-description"
# Initiates complete enterprise development workflow
# Activates @enterprise-consultant for zero-assumption requirements discovery
# Output: Project understanding with technical foundation and confidence tracking

/validate-understanding
# Confirms current system understanding with user
# Shows confidence levels and remaining validation needs
# Output: Validated requirements or identification of gaps requiring clarification
```

### STAGE_PROGRESSION_COMMANDS
```bash
/progress-to-requirements
# Moves from technical discovery to complete PRD creation
# Requires: 85%+ confidence in technical foundation
# Activates: @enterprise-consultant for comprehensive requirements gathering

/progress-to-design
# Transitions from requirements to UI-first design development
# Requires: Complete validated PRD with MVP boundaries
# Activates: @ui-architect for design system and systematic UI creation

/progress-to-architecture  
# Moves from UI design to complete system architecture
# Requires: All UI designs approved with technical feasibility confirmed
# Activates: Enterprise Intelligence for architecture specification

/progress-to-implementation
# Transitions from architecture to professional development
# Requires: Complete system architecture with all validations passed
# Activates: @implementation-manager for enterprise-grade development

/deploy-production
# Final deployment with monitoring and documentation
# Requires: All quality gates passed, comprehensive testing completed
# Output: Production-ready system with full observability
```

## STAGE 1 & 2: REQUIREMENTS DISCOVERY COMMANDS
*Agent: @enterprise-consultant*

### DISCOVERY_COMMANDS
```bash
@enterprise-consultant
*discover-requirements "project-description"
# Zero-assumption requirements discovery through intelligent conversation
# Uses context-aware questioning based on detected project type
# Output: Progressive confidence building with fact vs assumption tracking

*validate-assumption "specific-assumption"
# Validates specific assumption or interpretation with user
# Prevents hallucination through explicit confirmation requirements
# Output: Confirmed fact or corrected understanding

*clarify-constraint "technical-area"
# Focuses on specific technical constraint or requirement area
# Used when confidence is low in particular domain
# Output: Clear technical constraint documentation

*create-comprehensive-prd
# Generates complete PRD from validated requirements
# Includes functional, non-functional, and technical specifications
# Output: Enterprise-grade PRD with clear acceptance criteria
```

### VALIDATION_COMMANDS
```bash
*confidence-check
# Displays current confidence levels across all requirement areas
# Shows verified facts vs assumptions needing validation
# Output: Confidence dashboard with specific validation needs

*requirement-completeness-audit
# Validates all necessary requirements have been captured
# Checks for common missed areas based on project type
# Output: Completeness report with missing requirement identification

*mvp-boundary-validation
# Confirms MVP scope and feature prioritization with business rationale
# Ensures feasible MVP scope within timeline and resource constraints
# Output: Validated MVP specification with clear boundaries

*finalize-requirements-package
# Completes requirements gathering and prepares handoff documentation
# Validates all exit criteria met before stage progression
# Output: Complete requirements package ready for UI design phase
```

## STAGE 3: ASCII-FIRST UI DESIGN COMMANDS
*Agent: @ui-architect*

### ENHANCED_WORKFLOW_COMMANDS
```bash
@ui-architect
*research-design-patterns "project-type + target-audience"
# Evidence-based competitor analysis using WebFetch
# Extracts proven design patterns, colors, typography from 3-5 leaders
# Output: Design direction with source citations and rationale
# Token cost: ~300 tokens

*wireframe-ascii-systematic "layout-description"
# Generate structured ASCII wireframe with detailed rationale
# Include responsive considerations and information hierarchy
# Output: Approval-ready ASCII layout for user validation
# Token cost: ~200 tokens

*refine-wireframe "adjustment-description"
# Modify ASCII wireframe based on user feedback
# Maintain structural consistency and rationale
# Output: Updated ASCII wireframe ready for implementation
# Token cost: ~100 tokens

*create-style-guide-with-preview "research-foundation"
# Generate complete /style-guide page with live component examples
# Include colors, typography, spacing, buttons, cards, forms, badges
# Output: Localhost preview at /style-guide for immediate validation
# Token cost: ~400 tokens

*implement-component "approved-wireframe + style-guide"
# Generate enterprise Next.js component from approved ASCII + style guide
# Include TypeScript, data-testid attributes, responsive design
# Output: Live component at localhost:3000 with hot reload
# Token cost: ~800 tokens

*refine-component "visual-adjustments"
# Make conversational adjustments to existing component
# Maintain enterprise standards and test compatibility
# Output: Updated component with immediate browser preview
# Token cost: ~300 tokens

*optimize-component-library "tech-stack"
# Maps design vision to available component libraries
# Maximizes reuse of proven components vs custom development
# Output: Component usage strategy with customization requirements

*establish-brand-guidelines
# Creates comprehensive design specification including colors, typography, spacing
# Defines design consistency framework for all UI development
# Output: Complete design system documentation ready for implementation

*validate-design-consistency
# Checks adherence to established design system across all components
# Identifies inconsistencies and provides correction recommendations
# Output: Design consistency report with correction requirements
```

### DATA_DRIVEN_VALIDATION_COMMANDS
```bash
*setup-playwright-validation "component-specifications"
# Generate automated test suite for comprehensive UI validation
# Include: structure verification, responsiveness, accessibility, performance
# Output: Complete test file with data-driven assertions and test IDs
# Token cost: ~400 tokens

*validate-with-playwright "test-target"
# Run Playwright tests and analyze results with actual measurements
# Identify specific issues with pixel-perfect accuracy (NO guessing)
# Output: Test results with actionable fix recommendations and data
# Token cost: ~200 tokens

*fix-validation-issues "playwright-test-results"
# Implement fixes for issues identified by automated testing
# Re-run tests to validate solutions and ensure all tests pass
# Output: Updated component with passing validation and proof of fixes
# Token cost: ~300 tokens

*performance-audit "component-url"
# Lighthouse analysis with Core Web Vitals measurement
# Identify performance bottlenecks with actual metrics
# Output: Performance report with specific optimization recommendations
# Token cost: ~200 tokens

### DESIGN_REPLICATION_COMMANDS
```bash
*analyze-existing-design "website-url"
# Use Firecrawl to extract complete design system from any website
# Extract: colors, typography, layout patterns, component structures
# Output: Comprehensive design specification with implementation details
# Token cost: ~500 tokens

*implement-exact-replica "firecrawl-analysis + tech-stack"
# Generate pixel-perfect recreation using extracted design specifications
# Maintain enterprise Next.js quality while matching original design
# Output: Exact replica with modern tech stack and validation
# Token cost: ~1000 tokens

*extract-component-patterns "analysis-results"
# Identify reusable component patterns from analyzed design
# Map to Shadcn/ui components for maximum code reuse
# Output: Component mapping strategy with implementation plan
# Token cost: ~300 tokens
```

### VISUAL_VALIDATION_COMMANDS
```bash
*visual-quality-audit
# Comprehensive visual quality check against enterprise standards
# Validates component usage, responsive design, accessibility compliance
# Output: Quality audit report with specific improvement requirements

*accessibility-compliance-check
# WCAG AA+ compliance validation using automated and manual testing
# Ensures enterprise accessibility standards met across all designs
# Output: Accessibility compliance report with remediation requirements

*responsive-design-validation
# Validates design across mobile, tablet, desktop breakpoints
# Ensures optimal user experience across all device categories
# Output: Responsive design verification with device-specific optimizations

*performance-impact-analysis
# Assesses UI complexity impact on loading and rendering performance
# Identifies potential performance bottlenecks and optimization opportunities
# Output: Performance assessment with optimization recommendations
```

## STAGE 4 & 5: ARCHITECTURE & PLANNING COMMANDS
*Agents: @ui-architect + Enterprise Intelligence + @implementation-manager*

### ARCHITECTURE_COMMANDS
```bash
*generate-database-schema "ui-requirements"
# Creates optimized database schema based on validated UI data requirements
# Implements enterprise patterns with proper indexing and relationships
# Output: Complete database schema with migration strategy

*design-api-structure "user-interactions"
# Creates API endpoints based on UI interaction patterns and data flows
# Implements RESTful or tRPC patterns with proper error handling
# Output: Complete API specification with endpoint documentation

*optimize-performance-architecture "ui-complexity"
# Designs performance optimization strategy based on UI complexity analysis
# Includes caching, CDN, database optimization, and scaling strategies
# Output: Performance architecture with specific optimization implementations

*validate-security-architecture "data-flows"
# Analyzes security requirements based on UI data handling patterns
# Implements OWASP compliance with authentication and authorization design
# Output: Security architecture specification with implementation requirements
```

### IMPLEMENTATION_PLANNING_COMMANDS
```bash
@implementation-manager
*create-development-roadmap "complete-specifications"
# Generates detailed development plan with phase sequencing and dependencies
# Includes quality gate placement and milestone definition
# Output: Complete implementation roadmap with timeline estimates

*define-quality-gate-strategy
# Establishes comprehensive quality gates for testing, security, performance
# Defines automated validation requirements and manual review processes
# Output: Quality assurance strategy with specific validation criteria

*plan-deployment-pipeline
# Designs production deployment with monitoring, backup, and rollback procedures
# Includes environment configuration and infrastructure requirements
# Output: Complete deployment strategy with operational procedures
```

## STAGE 6: IMPLEMENTATION & DEPLOYMENT COMMANDS
*Agent: @implementation-manager*

### DEVELOPMENT_COMMANDS
```bash
*initialize-enterprise-codebase
# Sets up complete project structure with enterprise patterns and configurations
# Includes TypeScript, ESLint, Prettier, testing framework, and CI/CD setup
# Output: Production-ready codebase foundation with all quality tools

*implement-feature-batch "feature-specifications"
# Develops features using proven patterns with comprehensive testing
# Applies enterprise code standards and security implementations
# Output: Production-ready feature implementation with full validation

*run-comprehensive-validation
# Executes all quality gates including testing, security, performance validation
# Provides detailed reports on compliance with enterprise standards
# Output: Complete validation report with any required remediation

*deploy-with-full-monitoring
# Deploys to production with comprehensive monitoring and alerting setup
# Includes error tracking, performance monitoring, and health checks
# Output: Live production system with full observability and documentation
```

### QUALITY_ASSURANCE_COMMANDS
```bash
*enforce-code-standards
# Applies and validates TypeScript, ESLint, Prettier standards
# Includes pre-commit hooks and automated quality enforcement
# Output: Code quality validation with standards compliance confirmation

*execute-security-audit
# Comprehensive security validation including OWASP compliance checking
# Includes vulnerability scanning and security pattern validation
# Output: Security audit report with any required security implementations

*validate-performance-optimization
# Tests performance against enterprise standards with optimization recommendations
# Includes Lighthouse auditing and Core Web Vitals validation
# Output: Performance validation report with optimization implementation

*confirm-production-readiness
# Final validation before production deployment including all quality gates
# Comprehensive checklist validation with sign-off requirements
# Output: Production readiness confirmation with deployment approval
```

## META-ANALYST_MONITORING_COMMANDS

### SILENT_MONITORING_COMMANDS
```bash
/meta-monitor-session
# Begin silent monitoring of current Enterprise UI Builder conversation
# Tracks protocol adherence, confidence building, and token efficiency
# Output: Silent activation - no interruption to workflow

/meta-report
# Generate comprehensive session analysis report
# Shows protocol compliance, efficiency metrics, quality indicators
# Output: Detailed analysis with optimization recommendations

/meta-silent-log "issue-description"
# Log user-observed issue without triggering Claude response
# Stores issue in session log for later analysis
# Output: Silent logging - no chat interruption
# Example: /meta-silent-log "Agent assumed user preference without asking"

/meta-efficiency
# Display real-time token efficiency and workflow optimization analysis
# Shows stage timing, conversation bloat detection, cost tracking
# Output: Efficiency dashboard with improvement opportunities
```

### ANALYSIS_&_REPORTING_COMMANDS
```bash
/meta-protocol-check
# Check current conversation for Enterprise UI Builder protocol adherence
# Validates stage progression, approval gates, confidence building
# Output: Protocol compliance score with specific violations flagged

/meta-confidence-audit
# Analyze confidence building progression and fact-based decisions
# Tracks 0% → 85% progression with evidence validation
# Output: Confidence analysis with assumption detection report

/meta-quality-scan
# Scan for technical quality issues and protocol violations
# Checks TypeScript compliance, accessibility, test coverage
# Output: Quality assessment with specific issue identification

/meta-token-analysis
# Detailed token usage analysis and efficiency recommendations
# Compares actual vs target costs for each stage
# Output: Token optimization report with cost reduction strategies
```

## UNIVERSAL_UTILITY_COMMANDS

### STATUS_&_PROGRESS_COMMANDS
```bash
/system-status
# Shows current stage, progress, and next required actions
# Displays confidence levels and validation requirements
# Output: Complete system status with actionable next steps

/validation-dashboard
# Comprehensive view of all validation requirements and completion status
# Shows quality gates, approval status, and remaining requirements
# Output: Validation status dashboard with specific action items

/confidence-report
# Detailed confidence tracking across all project understanding areas
# Identifies high-confidence facts vs assumptions requiring validation
# Output: Confidence analysis with specific validation needs

/project-health-check
# Overall project health including technical feasibility and risk assessment
# Validates alignment with enterprise standards and best practices
# Output: Project health report with risk mitigation recommendations
```

### CONTEXT_MANAGEMENT_COMMANDS
```bash
/preserve-context "stage-transition"
# Captures and documents all critical context for agent handoffs
# Ensures no information loss during stage transitions
# Output: Complete context preservation with validation checklist

/validate-handoff "from-agent" "to-agent"
# Validates successful context transfer between agents
# Confirms receiving agent has complete understanding
# Output: Handoff validation with any missing information identification

/update-requirements "new-information"
# Updates project requirements based on new user input or discoveries
# Maintains consistency across all agents and documentation
# Output: Updated requirements with impact analysis on existing work
```

---

## COMMAND_USAGE_PATTERNS

### TYPICAL_PROJECT_FLOW
```bash
# Stage 1-2: Requirements Discovery
/start-enterprise-project "I want to build a fitness tracking app"
@enterprise-consultant *discover-requirements
@enterprise-consultant *validate-assumption "assumption"
@enterprise-consultant *create-comprehensive-prd
/progress-to-design

# Stage 3: UI-First Design  
@ui-architect *create-design-foundation "clean, motivating design"
@ui-architect *generate-complete-page-inventory
@ui-architect *design-page-batch "dashboard, logging, progress"
@ui-architect *validate-architecture-feasibility
/progress-to-architecture

# Stage 4-5: Architecture & Planning
*generate-database-schema
*design-api-structure  
@implementation-manager *create-development-roadmap
/progress-to-implementation

# Stage 6: Implementation & Deployment
@implementation-manager *initialize-enterprise-codebase
@implementation-manager *implement-feature-batch
@implementation-manager *run-comprehensive-validation
@implementation-manager *deploy-with-full-monitoring
```

---

**Complete Command Reference: Enterprise-grade development through conversational intelligence and systematic UI-first methodology.**