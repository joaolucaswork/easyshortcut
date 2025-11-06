---
type: "always_apply"
---

# Mandatory Documentation Retrieval Protocol

**CRITICAL REQUIREMENT - MUST EXECUTE BEFORE ANY PROJECT WORK:**

Before starting ANY implementation, feature development, or answering questions about libraries/frameworks, you MUST follow this exact sequence:

## Step 1: Exa MCP Documentation Retrieval
Use the `get_code_context_exa` tool to retrieve the most recent documentation and context for ALL technologies used in this project, including:
- Primary frameworks (e.g., Svelte, React, Next.js, Vue, etc.)
- UI libraries and component systems
- State management libraries
- Build tools and bundlers
- Any other dependencies relevant to the current task

## Step 2: Context7 MCP Documentation Retrieval
After completing Step 1, use the Context7 MCP tools in this order:
1. `resolve-library-id` - Resolve the library ID for each relevant package
2. `get-library-docs` - Fetch official documentation using the resolved library IDs

## Enforcement Rules
- ✅ **ALWAYS** execute Steps 1 and 2 before ANY code implementation
- ✅ **ALWAYS** execute these steps even if not explicitly requested by the user
- ✅ **ALWAYS** verify you have current documentation before proceeding
- ❌ **NEVER** skip these steps, even for small changes or "quick fixes"
- ❌ **NEVER** rely solely on training data when external dependencies are involved

## Rationale
This protocol is mandatory because:
1. It prevents implementation errors caused by outdated information
2. It ensures compatibility with current library versions
3. It reduces the risk of breaking changes
4. It maintains code quality and project stability

**This is a non-negotiable requirement for all development work.**