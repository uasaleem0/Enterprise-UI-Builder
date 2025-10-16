// Forge System - Warp Terminal Autocomplete Specification
// Version: 1.0
// Install: Copy to ~/.warp/completion_specs/forge.ts

const completionSpec: Fig.Spec = {
  name: "forge",
  description: "AI-powered software development system - PRD to production",
  subcommands: [
    // Core Commands
    {
      name: "start",
      description: "Create new project from scratch (from-scratch workflow)",
      args: {
        name: "project-name",
        description: "Name of the project to create",
        isOptional: false,
      },
      icon: "🚀",
    },
    {
      name: "import",
      description: "Import existing PRD for validation (import-prd workflow)",
      args: [
        {
          name: "project-name",
          description: "Name of the project",
          isOptional: false,
        },
        {
          name: "prd-file",
          description: "Path to PRD markdown file",
          template: "filepaths",
          isOptional: false,
        },
      ],
      icon: "📥",
    },
    {
      name: "status",
      description: "Show confidence breakdown and progress",
      icon: "📊",
    },
    {
      name: "show",
      description: "Expand section details (less scrolling)",
      args: {
        name: "section",
        description: "Section to expand",
        isOptional: false,
        suggestions: [
          {
            name: "explicit",
            description: "Show explicitly mentioned features",
            icon: "✅",
          },
          {
            name: "implied",
            description: "Show system-inferred features",
            icon: "🔍",
          },
          {
            name: "blockers",
            description: "Show all blockers with resolution steps",
            icon: "🚨",
          },
          {
            name: "deliverables",
            description: "Show all deliverable details",
            icon: "📋",
          },
          {
            name: "all",
            description: "Show everything",
            icon: "📑",
          },
        ],
      },
      icon: "👁️",
    },

    // GitHub Commands
    {
      name: "setup-repo",
      description: "Create GitHub repo with CI/CD foundation (requires 95% confidence)",
      args: {
        name: "project-name",
        description: "Name of the project",
        isOptional: false,
      },
      icon: "🔧",
    },
    {
      name: "generate-issues",
      description: "Convert PRD features into atomic GitHub issues",
      icon: "📝",
    },
    {
      name: "issue",
      description: "Process GitHub issue (Plan → Create → Test → Deploy)",
      args: {
        name: "issue-number",
        description: "GitHub issue number to process",
        isOptional: false,
      },
      icon: "⚙️",
    },
    {
      name: "review-pr",
      description: "Review pull request in fresh context (run in NEW shell)",
      args: {
        name: "pr-number",
        description: "GitHub pull request number",
        isOptional: false,
      },
      icon: "🔍",
    },
    {
      name: "test",
      description: "Run test suite (auto-detects Rails, Node.js, Python)",
      icon: "🧪",
    },
    {
      name: "deploy",
      description: "Check deployment status via gh CLI",
      icon: "🚀",
    },

    // Utility Commands
    {
      name: "fix",
      description: "Get detailed guidance for specific blocker",
      args: {
        name: "blocker",
        description: "Blocker ID to get guidance for",
        isOptional: false,
        suggestions: [
          {
            name: "missing_tech_stack",
            description: "Tech stack incomplete (blocks architecture phase)",
            icon: "🚨",
          },
          {
            name: "conflicting_features",
            description: "Contradictory requirements detected",
            icon: "⚠️",
          },
          {
            name: "low_confidence",
            description: "Confidence below 95% threshold",
            icon: "📉",
          },
          {
            name: "vague_features",
            description: "Acceptance criteria missing or incomplete",
            icon: "❓",
          },
          {
            name: "missing_compliance",
            description: "Industry compliance not addressed (HIPAA, PCI-DSS, etc.)",
            icon: "⚖️",
          },
        ],
      },
      icon: "🩹",
    },
    {
      name: "export",
      description: "Export PRD as timestamped markdown file",
      icon: "💾",
    },
    {
      name: "help",
      description: "Show command reference",
      icon: "❓",
    },
    {
      name: "version",
      description: "Show Forge version and location",
      icon: "ℹ️",
    },
  ],
  options: [
    {
      name: ["--help", "-h"],
      description: "Show help for forge command",
      icon: "❓",
    },
    {
      name: ["--version", "-v"],
      description: "Show Forge version",
      icon: "ℹ️",
    },
  ],
};

export default completionSpec;
