# Enterprise Commands Reference

## Quick Commands

```bash
/status                    # Project progress dashboard
/start "project-description" # Begin enterprise workflow
/validate                  # Confirm understanding
/progress                  # Move to next stage
/where-am-i               # Current location & next steps
```

## Website Cloning Commands

```bash
/clone-website "url"      # OneRedOak 7-phase cloning
/clone-progress          # Cloning status with phases
/clone-status           # Triage matrix & evidence
```

## Agent Commands

### @enterprise-consultant
```bash
*discover "project-type"     # Requirements gathering
*validate "assumption"       # Confirm understanding
*create-prd                 # Generate PRD
*research "keywords"        # Market analysis
```

### @ui-architect
```bash
*research-design "type"     # Competitor analysis
*wireframe "layout"         # ASCII wireframe
*style-guide               # Live style guide creation
*implement "wireframe"     # Build component
```

### @website-cloner
```bash
*clone-phase "1-7"         # Execute specific phase
*validate-component "selector" # Component validation
*evidence-comparison       # Triage assessment
*automated-validation     # Full automation cycle
```

### @implementation-manager
```bash
*init-codebase            # Enterprise project setup
*implement-features       # Batch feature development
*run-validation          # Quality gates
*deploy                  # Production deployment
```

## MCP Integration Commands

```bash
mcp__playwright__browser_navigate "url"        # Navigate browser
mcp__playwright__browser_take_screenshot "file" # Capture screenshot
mcp__playwright__browser_resize "w" "h"         # Change viewport
mcp__playwright__browser_click "selector"      # Click element
mcp__playwright__browser_type "selector" "text" # Type input
```

## Status Commands

```bash
/system-status           # Complete system status
/validation-dashboard    # All validation requirements
/confidence-report      # Confidence tracking
/project-health-check   # Overall project health
```

## Stage Progression

1. **/start** → Technical Requirements (85% confidence)
2. **/progress** → Feature Discovery → PRD Creation
3. **/progress** → Design Direction → **Branching Decision**
   - Path A: **/clone-website** → OneRedOak 7-phase
   - Path B: **@style-guide-builder** → Original design
4. **/progress** → Architecture → Implementation → Deployment

## Usage Examples

```bash
# Start new project
/start "fitness tracking app for remote teams"

# Website cloning workflow
/clone-website "https://linear.app"

# Original design workflow
@ui-architect *research-design "fitness + professional users"
@ui-architect *wireframe "dashboard with metrics"
@ui-architect *style-guide
```

---

**All commands designed for token efficiency and rapid development**