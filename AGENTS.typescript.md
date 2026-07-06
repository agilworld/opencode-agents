# AGENTS.typescript.md - TypeScript Stack Agent Configuration

> **TypeScript stack agent configuration — see AGENTS.md for the generic template**

## Project Overview

<!-- TODO: Add project-specific content -->
<!-- Describe what your project does, its goals, and key features -->

## The Agent System

This project uses a multi-agent system for context-efficient development.

### Agents

#### Core Agents

| Agent | Role | Mode |
|-------|------|------|
| **@ostype** | Orchestrator — coordinates, delegates, synthesizes | primary |
| **@tylead** | Technical Lead — research, architecture, planning | subagent |
| **@tyson** | Backend Implementor — Node.js, Bun.js, all frameworks/ORMs | subagent |
| **@nova** | Frontend Implementor — React, TanStack Router/Query/Table | subagent |
| **@marco** | Truth-Teller (default) — challenges assumptions | subagent |

#### Marco Variants

| Agent | Model | Purpose |
|-------|-------|---------|
| **@marco_opus** | DeepSeek Pro | Default truth-teller |
| **@marco_qwen** | DeepSeek Flash | Code-focused analysis |
| **@marco_grok** | DeepSeek Flash | Alternative perspective |

### Workflow

```
User Request
    │
    ▼
  Ostype ─────────────────────────────────────┐
    │                                          │
    ├──→ Tylead (research + plan)              │
    │         │                                │
    │         ├──→ Marco (challenge)           │ ← optional, for complex/risky changes
    │         │                                │
    │         ▼                                │
    ├──→ Tyson (backend implement) ──┐         │
    ├──→ Nova (frontend implement) ──┤──→ Done◄┘
```

### Marco Consensus Pattern

For high-stakes decisions, run all three Marco variants in parallel:

```
Ostype
  │
  ├──→ @marco_opus ──┐
  ├──→ @marco_qwen ──┼──→ Synthesize → Decision
  └──→ @marco_grok ──┘
```

**When to use:**
- Major architectural decisions
- Risky refactors (>5 files)
- When you want diverse AI perspectives
- When the team is stuck

**How to interpret:**
- **All agree** = High confidence signal
- **Disagree** = Explore each angle
- **One unique insight** = Investigate further

### Key Principles

- **Ostype orchestrates everything** — delegates to Tylead, Tyson, Nova, Marco; never does the work himself
- **Tylead researches and plans** — digs deep, evaluates tradeoffs, routes tasks to the right implementor
- **Tyson implements backend** — server/API/data-layer code, follows the spec precisely
- **Nova implements frontend** — React/TanStack Router/Query/Table, follows the spec precisely
- **Marco challenges** — called for complex refactors (>5 files), risky changes, or when stuck

## Quick Start

<!-- TODO: Add project-specific content -->
<!-- Add setup instructions, common commands, and daily workflow -->

```bash
# Setup (detect package manager from lockfiles)
npm install        # package-lock.json
pnpm install       # pnpm-lock.yaml
yarn install       # yarn.lock
bun install        # bun.lockb

# Type check
npx tsc --noEmit

# Run tests
npx vitest run

# Lint
npx eslint .
```

## TypeScript Environment

**CRITICAL:** Always detect the project's package manager from lockfiles before running commands:

| Lockfile | Package Manager |
|----------|-----------------|
| `bun.lockb` | bun |
| `pnpm-lock.yaml` | pnpm |
| `yarn.lock` | yarn |
| `package-lock.json` | npm |

```bash
# Use npx/bunx — never assume global binaries
npx tsc --noEmit        # npm/yarn/pnpm
bunx tsc --noEmit       # bun

# Run tests with the project's test runner
npx vitest run          # Vitest
npx jest                # Jest
bun test                # Bun test runner
```

**NEVER** assume global `tsc`, `vitest`, or `eslint` binaries. Always use `npx` or `bunx`.

## Workflow Rules

<workflow>
### After Code Fixes
When `@tyson` or `@nova` completes a fix for a GitHub issue:
1. **Commit** with message format: `fix #<issue_number>: <short description>`
2. **Push** to remote immediately
3. **Close issue** with `gh issue close <number> --reason completed --comment "<summary of fix>"`
4. **Move to next** issue in priority order

### Commit Ownership
- **@tyson commits backend changes** — server code, API routes, ORM queries, database schemas
- **@nova commits frontend changes** — React components, routes, hooks, styles
- **Never route backend commits through Nova or frontend commits through Tyson**

### Commit Frequency
- **In branches:** Commit after EVERY meaningful change (don't batch)
- **Small, atomic commits** are preferred over large ones
- **Always push** after committing - don't let commits pile up locally

### Branch Workflow
When working in a feature branch:
1. Commit and push frequently (after each fix/change)
2. When all issues for the branch are complete:
   - Check if other branches exist: `git branch -a`
   - If **no other branches**: prepare PR and merge to main
   - If **other branches exist**: prepare PR but **do NOT merge** - ask user first
3. Always use `gh pr create` with clear summary

### Task Tagging
When `@tylead` creates plans, every task must be tagged with its implementor:
- **`Assigned: Tyson`** — backend/server-side work
- **`Assigned: Nova`** — frontend/client-side work
- **`Assigned: Tyson + Nova (sequenced)`** — full-stack tasks, ordered by dependency

### Issue Management
- Close issues **immediately** after fix is verified (tests pass, `tsc --noEmit` clean)
- Always include in close comment:
  - What was changed
  - Problems encountered during the work on this issue, and how you solved them
  - Which file(s) were modified
  - Commit hash if relevant
- Link related issues in comments when applicable

### Commit Message Format
```
<type> #<issue>: <description>

Types: fix, feat, refactor, docs, test, chore
```

Examples:
- `fix #42: handle null response from API`
- `feat #15: add user authentication endpoint`
- `refactor #30: extract shared Zod schema`
- `fix #145: correct case-insensitive filter in Prisma query`
</workflow>

## Scripts

<!-- TODO: Add project-specific content -->
<!-- Document your project's scripts and their purposes -->

| Script | Purpose |
|--------|---------|
| `npm run dev` | Start development server |
| `npm run build` | Compile TypeScript |
| `npm run test` | Run test suite |
| `npm run lint` | Lint source files |
| `npm run typecheck` | Run `tsc --noEmit` |

## Project Structure

<!-- TODO: Add project-specific content -->
<!-- Document your project's directory structure -->

```
your-project/
├── AGENTS.md                 # This file
├── package.json              # Dependencies and scripts
├── tsconfig.json             # TypeScript configuration
├── .env.example              # Environment variables template
├── src/                      # Source code
│   ├── index.ts              # Entry point
│   ├── routes/               # API routes / TanStack Router routes
│   ├── schemas/              # Shared Zod schemas
│   ├── hooks/                # TanStack Query hooks
│   └── components/           # React components
├── tests/                    # Unit and integration tests
└── scripts/                  # Utility scripts
```

## Architecture

<!-- TODO: Add project-specific content -->
<!-- Document key architectural patterns, abstractions, and design decisions -->

## Key Modules

<!-- TODO: Add project-specific content -->
<!-- Document the main modules and their responsibilities -->

| Module | Purpose |
|--------|---------|
| `src/schemas/` | Shared Zod validation schemas (imported by both server and client) |
| `src/routes/api/` | API route handlers (Tyson) |
| `src/routes/pages/` | TanStack Router route definitions (Nova) |
| `src/hooks/` | TanStack Query hooks with typed query key factories (Nova) |
| `src/components/` | Reusable React components (Nova) |
| `src/lib/` | Shared utilities, middleware, database client (Tyson) |

## Configuration

<!-- TODO: Add project-specific content -->
<!-- Document configuration files and environment variables -->

| File | Purpose |
|------|---------|
| `tsconfig.json` | TypeScript compiler options |
| `eslint.config.js` | ESLint rules |
| `prettier.config.js` | Prettier formatting rules |
| `.env.example` | Environment variable documentation |

## Code Style

- **TypeScript:** 5.x+, `"strict": true` in tsconfig
- **Types:** No `any` — use `unknown` and narrow with Zod or type guards
- **Validation:** Zod schemas at every API boundary (never trust raw `req.body`)
- **Naming:** `camelCase` for variables/functions, `PascalCase` for types/interfaces/components, `UPPER_CASE` for constants
- **Formatting:** Prettier with consistent config
- **Modules:** ESM by default (`import`/`export`); avoid CJS unless the project requires it
- **Async:** `async`/`await` over raw Promises; no floating promises
- **Testing:** Vitest (preferred) or Jest; React Testing Library for components; Playwright for e2e
- **Error handling:** Typed error classes, never throw bare strings, never swallow errors

<!-- TODO: Add project-specific code style rules if needed -->
