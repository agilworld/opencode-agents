# opencode-agents

Multi-agent AI development templates for [opencode](https://github.com/sst/opencode).

## What Is This?

A ready-to-use template for setting up **multi-agent AI development workflows** with opencode. Instead of a single AI assistant doing everything, work is delegated to specialized agents—each optimized for their role.

Two stacks are available: **Python** and **TypeScript**.

---

## The Agents

### Python Stack

| Agent | Name | Role | Model |
|-------|------|------|-------|
| **Oscar** | `oscar` | Orchestrator — coordinates, delegates, synthesizes | DeepSeek Pro |
| **Scout** | `scout` | Researcher + Planner — deep analysis, actionable plans | DeepSeek Pro |
| **Ivan** | `ivan` | Implementor — writes code, runs tests, git operations | DeepSeek Flash |
| **Jester** | `jester` | Truth-Teller — challenges assumptions | DeepSeek Flash |
| **Marco** | `marco` | QA Engineer + Documenter (optional) — verifies, tests, documents | DeepSeek Flash |

**Jester Consensus variants:**

| Agent | Model | Purpose |
|-------|-------|---------|
| `jester_opus` | DeepSeek Pro | Consensus trio |
| `jester_qwen` | DeepSeek Flash | Consensus trio |
| `jester_grok` | DeepSeek Flash | Consensus trio |

### TypeScript Stack

| Agent | Name | Role | Model |
|-------|------|------|-------|
| **Ostype** | `ostype` | Orchestrator — coordinates, delegates, synthesizes | DeepSeek Pro |
| **Tylead** | `tylead` | Technical Lead — research, architecture, planning | DeepSeek Pro |
| **Tyson** | `tyson` | Backend Implementor — Node.js, Bun.js, all frameworks/ORMs | DeepSeek Flash |
| **Nova** | `nova` | Frontend Implementor — React, TanStack Router/Query/Table | DeepSeek Flash |
| **Marco** | `marco` | Truth-Teller — challenges assumptions | DeepSeek Flash |
| **Quill** | `quill` | QA Engineer + Documenter (optional) — verifies, tests, documents | DeepSeek Flash |

**Marco Consensus variants:**

| Agent | Model | Purpose |
|-------|-------|---------|
| `marco_opus` | DeepSeek Pro | Consensus trio |
| `marco_qwen` | DeepSeek Flash | Consensus trio |
| `marco_grok` | DeepSeek Flash | Consensus trio |

---

## Workflow

### Python Orchestrator Pattern

```
User Request
    │
    ▼
  Oscar ─────────────────────────────┐
    │                                │
    ├──→ Scout (research + plan)     │
    │         │                      │
    │         ├──→ Jester (challenge)│ ← optional
    │         │                      │
    │         ▼                      │
    └──→ Ivan (implement) ──→ Done ◄─┘
```

### TypeScript Orchestrator Pattern

```
User Request
    │
    ▼
  Ostype ─────────────────────────────────────┐
    │                                          │
    ├──→ Tylead (research + plan)              │
    │         │                                │
    │         ├──→ Marco (challenge)           │ ← optional
    │         │                                │
    │         ▼                                │
    ├──→ Tyson (backend implement) ──┐         │
    ├──→ Nova (frontend implement) ──┤──→ Done◄┘
```

### With-QA Variant

When QA Engineer is included, the workflow adds a verification gate:

```
... → implement → Quill/Marco (verify + document) → Done
```

The QA Engineer verifies acceptance criteria, writes missing tests, updates documentation, and reports bugs before work is marked complete.

### Consensus Pattern

For high-stakes decisions, run all three variants in parallel:

```
Oscar/Ostype
  │
  ├──→ @jester_opus / @marco_opus ──┐
  ├──→ @jester_qwen / @marco_qwen ──┼──→ Synthesize → Decision
  └──→ @jester_grok / @marco_grok ──┘
```

---

## Installation

### 1. Install opencode

```bash
curl -fsSL https://opencode.ai/install | bash
```

Or see [opencode installation docs](https://github.com/sst/opencode#installation).

### 2. Run the installer

```bash
# Clone this repo
git clone https://github.com/yourusername/opencode-agents.git
cd opencode-agents

# Run the installer
./install.sh
```

The installer will prompt you to:

1. **Select tech stack** — Python or TypeScript
2. **Include QA Engineer** — Optionally add a QA + Documentation agent to the team
3. **Generate opencode.json** — Automatically merges `agents.json` into the template

The installer copies agent `.md` files to `~/.config/opencode/agent/` and generates `~/.config/opencode/opencode.json` from the selected stack's `agents.json`.

### 3. Set your API key

```bash
export ZEN_API_KEY="your-api-key-here"
```

### 4. Copy AGENTS.md to your project

```bash
cp AGENTS.md /path/to/your/project/
```

Edit `AGENTS.md` in your project to add project-specific context.

### 5. Start using agents

```bash
# In your project directory
opencode
```

Then talk to the orchestrator:

```bash
# Python stack
@oscar: I need to add user authentication to the app

# TypeScript stack
@ostype: I need to add user authentication to the app
```

---

## Configuration

Agent registrations live in `agents.json` at each stack path:

- `.opencode/agent/python/agents.json`
- `.opencode/agent/typescript/agents.json`

The installer reads the selected `agents.json` and merges it into `opencode.json.example` to produce `~/.config/opencode/opencode.json`.

### Example generated config

```json
{
  "model": "zen/claude-opus-4-5",
  "default_agent": "oscar",
  "agent": {
    "oscar": {
      "description": "Orchestrator - coordinates, delegates, synthesizes",
      "mode": "primary",
      "model": "zen/deepseek-v4-pro",
      "prompt": "{file:~/.config/opencode/agent/oscar.md}"
    },
    "scout": {
      "description": "Researcher + Planner - deep analysis, actionable plans",
      "mode": "subagent",
      "model": "zen/deepseek-v4-pro",
      "prompt": "{file:~/.config/opencode/agent/scout.md}"
    },
    "ivan": {
      "description": "Implementor - writes code, runs tests, git operations",
      "mode": "subagent",
      "model": "zen/deepseek-v4-flash",
      "prompt": "{file:~/.config/opencode/agent/ivan.md}"
    }
  }
}
```

### Customizing Models

Edit `~/.config/opencode/opencode.json` to change model assignments per agent.

---

## File Structure

```
opencode-agents/
├── .opencode/
│   ├── agent/
│   │   ├── python/
│   │   │   ├── agents.json           # Agent registrations
│   │   │   ├── oscar.md              # Orchestrator
│   │   │   ├── scout.md              # Researcher + Planner
│   │   │   ├── ivan.md               # Implementor
│   │   │   ├── jester.md             # Truth-Teller
│   │   │   └── with-qa/
│   │   │       ├── oscar.md          # Orchestrator (with QA workflow)
│   │   │       ├── scout.md          # Researcher (with QA workflow)
│   │   │       └── marco.md          # QA Engineer + Documenter
│   │   └── typescript/
│   │       ├── agents.json           # Agent registrations
│   │       ├── ostype.md             # Orchestrator
│   │       ├── tylead.md             # Technical Lead
│   │       ├── tyson.md              # Backend Implementor
│   │       ├── nova.md               # Frontend Implementor
│   │       ├── marco.md              # Truth-Teller
│   │       └── with-qa/
│   │           ├── ostype.md         # Orchestrator (with QA workflow)
│   │           ├── tylead.md         # Tech Lead (with QA workflow)
│   │           └── quill.md          # QA Engineer + Documenter
│   └── skills/                       # Reusable knowledge modules
│       ├── 5whys/
│       ├── feynman/
│       ├── git-commit/
│       ├── issue-triage/
│       ├── pr-review/
│       ├── prompt-engineering/
│       ├── python-venv/
│       ├── senior-qa/
│       ├── test-driven-development/
│       └── ... (40+ skills)
├── AGENTS.md                         # Template for project-specific context
├── README.md                         # This file
├── install.sh                        # Installer script
└── opencode.json.example             # Template config (agents filled by installer)
```

---

## Skills

Skills are reusable knowledge modules that agents can load on-demand using the `Skill` tool. Each skill contains domain-specific expertise in a `SKILL.md` file.

### Available Skills (40+)

| Skill | Description |
|-------|-------------|
| **5whys** | Root cause analysis |
| **cynefin** | Problem categorization |
| **feynman** | Explain complex concepts simply |
| **git-commit** | Conventional commit messages |
| **issue-triage** | GitHub issue triage |
| **ooda** | OODA loop decisions |
| **pr-review** | PR review guidelines |
| **premortem** | Imagine failure, identify risks |
| **prompt-engineering** | LLM prompt design patterns |
| **python-venv** | Virtual environment management |
| **senior-architect** | System design + architecture patterns |
| **senior-qa** | QA strategies + test automation |
| **senior-fullstack** | Full-stack patterns |
| **subagent-driven-development** | Implementer/spec-reviewer/code-quality prompts |
| **test-driven-development** | TDD + testing anti-patterns |
| **verification-before-completion** | Pre-completion verification |
| ... | (40+ total) |

### How Skills Work

Agents with `skill: true` in their frontmatter can load skills dynamically:

```yaml
---
tools: [Read, Write, Glob, Grep, Bash, Task]
skill: true
---
```

When an agent needs specialized knowledge, they call the Skill tool:

```
Agent: I need to review this Python code thoroughly.
[Loads skill: python-code-review]
Agent: Now applying the checklist...
```

### Creating Custom Skills

1. Create a directory under `.opencode/skills/` with your skill name
2. Add a `SKILL.md` file with the skill content
3. Skills are automatically available to agents with `skill: true`

```bash
mkdir -p ~/.config/opencode/skills/my-custom-skill
echo "# My Custom Skill\n\nSkill content here..." > ~/.config/opencode/skills/my-custom-skill/SKILL.md
```

---

## Key Principles

1. **Orchestrator delegates everything** — Never reads files or writes code
2. **Researcher digs deep, plans lean** — Research flows naturally into actionable tasks
3. **Implementor follows specs** — No improvisation; if the plan is unclear, ask
4. **Truth-Teller challenges** — Called for complex refactors (>5 files) or risky changes
5. **QA verifies before done** — Acceptance criteria must be met, tests written, docs updated

---

## Customization

The agent files are designed to be project-agnostic. Customize them by:

1. **Adjusting tool permissions** in the frontmatter
2. **Adding project-specific rules** to `AGENTS.md`
3. **Modifying code standards** in implementor files for your language/framework
4. **Editing `agents.json`** to change model assignments or add new agents

---

## License

MIT
