# MCP Server Refactor Log

**Objective:** Modify the `claude-mcp` server to accept a string for its parameters, similar to the `codex-mcp` server, to increase flexibility.

## Phase 1: Deconstruction and Discovery

In this phase, we analyzed the current implementations of both the `claude-mcp` and `codex-mcp` servers to understand their parameter handling mechanisms.

**Steps:**

1.  Read the `index.ts` file for `claude-mcp` to understand its current parameter handling.
2.  Read the `index.ts` file for `codex-mcp` to understand its current parameter handling.
3.  Consulted with the AI team (Claude and Codex) for their input on the best approach.

**Initial Findings:**

*   `claude-mcp` currently uses a rigid array of options for its parameters.
*   `codex-mcp` uses a more flexible string-based approach.

## Phase 2: Collaborative Brainstorming & User Alignment

In this phase, we brainstormed with the AI team to determine the best approach for refactoring the `claude-mcp` server.

**Codex's Recommendations:**

1.  Drop enums and use `z.string()`.
2.  Union of enum + string.
3.  Single source of truth + auto-generate JSON schemas.
4.  Config-driven enums loaded at runtime.

**Decision:**

We decided to proceed with **Option 3: Single source of truth + auto-generate JSON schemas**, as it provides the best balance of flexibility, maintainability, and robustness.

## Phase 3: Coordinated Implementation & Integration

In this phase, we implemented the chosen solution.

**Steps:**

1.  Installed the `zod-to-json-schema` library.
2.  Refactored `claude-mcp/src/index.ts` to use a single source of truth for tool definitions.
3.  Dynamically generate the JSON schema for the tool list using `zod-to-json-schema`.
4.  Fixed a TypeScript type error by adding a type assertion to the `handler` call.
5.  Successfully built the `claude-mcp` server.

**Next Steps:**

*   The refactoring is complete. The `claude-mcp` server is now more flexible and easier to maintain.