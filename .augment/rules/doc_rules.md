---
type: "always_apply"
---

# Documentation Retrieval Rules

## Overview
Before proceeding with any implementation or answering questions about libraries, frameworks, or APIs, use the following MCP tools to ensure you have the most up-to-date and accurate documentation.

## Available Tools

### 1. Exa MCP (`get_code_context_exa`)
Use this tool to retrieve the latest context for any programming libraries, SDKs, or APIs. This provides high-quality, fresh documentation and code examples.

### 2. Context7 MCP
- **`resolve-library-id`**: First, resolve the library ID for the package you need
- **`get-library-docs`**: Then fetch the official documentation using the resolved library ID

## When to Use These Tools

Use these documentation retrieval tools in the following scenarios:

- ✅ Before implementing features using external libraries or frameworks
- ✅ When answering questions about API usage, methods, or best practices
- ✅ When you need to verify current syntax, parameters, or return types
- ✅ When checking for the latest features or deprecations

## Benefits

- **Up-to-date Information**: Ensures you have the most recent documentation (not just training data)
- **Accuracy**: Provides accurate, current API signatures and usage patterns
- **Reliability**: Reduces hallucination risk by grounding responses in real-time documentation
- **Better Decisions**: Gives you better context for making implementation decisions

## Priority

⚠️ **Always prioritize using these tools over relying solely on training data when working with external dependencies.**

## Workflow

1. Identify the library/framework/API needed
2. Use `get_code_context_exa` for general context and examples
3. Use `resolve-library-id` to find the specific library in Context7
4. Use `get-library-docs` to fetch official documentation
5. Proceed with implementation using verified, current information

