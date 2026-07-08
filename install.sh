#!/bin/bash

# OpenCode Agents Installer
# Copies agent .md files and generates opencode.json from agents.json

set -e

# OS Detection
OS="Unknown"
IS_WSL=false

case "$(uname -s)" in
    Linux)
        if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ] || [ -n "$WSL_DISTRO_NAME" ]; then
            OS="WSL"
            IS_WSL=true
            echo "→ WSL (Windows Subsystem for Linux) detected"
        else
            OS="Linux"
            echo "→ Linux detected"
        fi
        ;;
    Darwin)
        OS="macOS"
        echo "→ macOS detected — native Unix support"
        ;;
    MSYS_NT-*|MINGW*|CYGWIN*)
        OS="GitBash"
        echo "⚠ Git Bash/MSYS2 detected — this script is designed for Linux/macOS/WSL"
        echo "  For native Windows, use: .\install.ps1"
        echo "  Continuing anyway (may work if python3 is available)..."
        ;;
    *)
        echo "⚠ Unknown OS: $(uname -s) — proceeding with Unix defaults"
        OS="Unknown"
        ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.opencode/agent"
TARGET_DIR="$HOME/.config/opencode/agent"

echo "OpenCode Agents Installer"
echo "========================="
echo ""

# Check source exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# ─── Tech Stack Selection ──────────────────────────────────────
if [ -n "$STACK" ]; then
    case "$STACK" in
        python|typescript)
            echo "→ Stack pre-selected via STACK env var: $STACK"
            STACK_CHOICE="$STACK"
            ;;
        *)
            echo "Error: Invalid STACK value '$STACK'. Must be 'python' or 'typescript'."
            exit 1
            ;;
    esac
else
    echo "Select tech stack:"
    echo "  1) Python"
    echo "  2) TypeScript"
    echo "  3) PHP"
    read -p "Enter choice (1 or 2 or 3): " STACK_CHOICE

    case "$STACK_CHOICE" in
        1|python|Python)
            STACK_CHOICE="python"
            ;;
        2|typescript|TypeScript|ts|TS)
            STACK_CHOICE="typescript"
            ;;
        3|php|PHP)
            STACK_CHOICE="php"
            ;;
        *)
            echo "Invalid choice. Please select 1, 2, or 3."
            exit 1
            ;;
    esac
fi

case "$STACK_CHOICE" in
    python) STACK="python"
            STACK_NAME="Python"
            ;;
    typescript) STACK="typescript"
                STACK_NAME="TypeScript"
                ;;
    php) STACK="php"
         STACK_NAME="PHP"
         ;;
esac

# ─── QA Engineer Agent ─────────────────────────────────────────
if [ -n "$WITH_QA" ]; then
    case "$(echo "$WITH_QA" | tr '[:upper:]' '[:lower:]')" in
        true|1|yes|y)
            INCLUDE_QA="y"
            echo "→ QA agent pre-selected via WITH_QA env var: yes"
            ;;
        false|0|no|n)
            INCLUDE_QA="n"
            echo "→ QA agent pre-selected via WITH_QA env var: no"
            ;;
        *)
            echo "Error: Invalid WITH_QA value '$WITH_QA'. Use true/false, yes/no, 1/0."
            exit 1
            ;;
    esac
else
    read -p "Include QA Engineer/Documenter in the team? (y/N): " -n 1 -r QA_CHOICE
    echo ""

    if [[ $QA_CHOICE =~ ^[Yy]$ ]]; then
        INCLUDE_QA="y"
    else
        INCLUDE_QA="n"
    fi
fi

if [ "$INCLUDE_QA" = "y" ]; then
    WITH_QA=true
else
    WITH_QA=false
fi

STACK_SRC="$SOURCE_DIR/$STACK"

if [ ! -d "$STACK_SRC" ]; then
    echo "Error: Stack source directory not found: $STACK_SRC"
    exit 1
fi

echo "Installing $STACK_NAME agents..."
echo ""

# Create target directory
mkdir -p "$TARGET_DIR"

# ──────────────────────────────────────────────
# 1. Copy agent .md files
# ──────────────────────────────────────────────

# Copy base agent files (top-level .md only, skip with-qa/)
for agent in "$STACK_SRC"/*.md; do
    if [ -f "$agent" ]; then
        AGENT_NAME="$(basename "$agent")"
        cp "$agent" "$TARGET_DIR/$AGENT_NAME"
        echo "  ✓ $AGENT_NAME"
    fi
done

# If QA selected, overwrite with with-qa variants
if [ "$WITH_QA" = true ]; then
    WITH_QA_DIR="$STACK_SRC/with-qa"
    if [ -d "$WITH_QA_DIR" ]; then
        echo ""
        echo "  Applying with-qa variants:"
        for variant in "$WITH_QA_DIR"/*.md; do
            if [ -f "$variant" ]; then
                VARIANT_NAME="$(basename "$variant")"
                cp "$variant" "$TARGET_DIR/$VARIANT_NAME"
                echo "    ✓ $VARIANT_NAME (with-qa)"
            fi
        done
    else
        echo "  ⚠ Warning: with-qa directory not found: $WITH_QA_DIR"
    fi
fi

echo ""

# ──────────────────────────────────────────────
# 2. Copy skills
# ──────────────────────────────────────────────

SKILLS_SRC="$SCRIPT_DIR/.opencode/skills"
SKILLS_TARGET="$HOME/.config/opencode/skills"

if [ -d "$SKILLS_SRC" ]; then
    echo "Copying skills..."
    mkdir -p "$SKILLS_TARGET"
    cp -r "$SKILLS_SRC"/* "$SKILLS_TARGET/"
    echo "  ✓ Skills installed ($(ls -d "$SKILLS_SRC"/*/ 2>/dev/null | wc -l) skill directories)"
    echo ""
fi

# ──────────────────────────────────────────────
# 3. Generate opencode.json from template + agents.json
# ──────────────────────────────────────────────

AGENTS_JSON="$STACK_SRC/agents.json"
TEMPLATE_JSON="$SCRIPT_DIR/opencode.json.example"

if [ ! -f "$AGENTS_JSON" ]; then
    echo "⚠ Warning: agents.json not found at $AGENTS_JSON"
    echo "  Skipping opencode.json generation."
else
    read -p "Generate opencode.json from template? (Y/n): " -n 1 -r GEN_CHOICE
    echo ""

    if [[ ! $GEN_CHOICE =~ ^[Nn]$ ]]; then
        if [ -f "$TEMPLATE_JSON" ]; then
            echo "Generating opencode.json..."

            # Use python3 to merge agents.json into opencode.json.example
            python3 -c "
import json

# Read template
with open('$TEMPLATE_JSON') as f:
    config = json.load(f)

# Read agents
with open('$AGENTS_JSON') as f:
    agents = json.load(f)

# Filter out QA agents if not selected
WITH_QA = $WITH_QA
if not WITH_QA:
    # Python QA agent is 'marco' (but only when marco is QA, not truth-teller)
    # TypeScript QA agent is 'quill'
    qa_agents = {'quill'}
    if '$STACK' == 'python':
        # In Python stack, 'marco' is the QA engineer — remove it
        qa_agents.add('marco')
    agents = {k: v for k, v in agents.items() if k not in qa_agents}

# Merge agents into template
config['agent'] = agents

# Set default_agent based on stack
if '$STACK' == 'python':
    config['default_agent'] = 'oscar'
else:
    config['default_agent'] = 'ostype'

# Write to target
target = '$HOME/.config/opencode/opencode.json'
with open(target, 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')

print('  ✓ opencode.json generated at', target)
print('  ✓ Agents registered:', ', '.join(agents.keys()))
"
        else
            echo "⚠ Warning: template not found at $TEMPLATE_JSON"
        fi
    else
        echo "Skipping opencode.json generation."
    fi
fi

# ─── AGENTS.md Configuration ──────────────────────────────────
echo ""
echo "Configuring AGENTS.md for $STACK_NAME stack..."

if [ -f "$SCRIPT_DIR/AGENTS.$STACK.md" ]; then
    cp "$SCRIPT_DIR/AGENTS.$STACK.md" "$SCRIPT_DIR/AGENTS.md"
    echo "  ✓ AGENTS.md generated from AGENTS.$STACK.md"
else
    echo "  ⚠ Warning: AGENTS.$STACK.md not found — skipping AGENTS.md generation"
fi

# ──────────────────────────────────────────────
# 4. Summary
# ──────────────────────────────────────────────

echo ""
echo "=============================================="
echo "  Installation Complete"
echo "=============================================="
echo ""
echo "Stack:        $STACK_NAME"
echo "QA Engineer:  $([ "$WITH_QA" = "true" ] && echo 'Yes' || echo 'No')"
echo "Target:       $TARGET_DIR"
echo ""

echo "Installed agents:"
for agent in "$TARGET_DIR"/*.md; do
    if [ -f "$agent" ]; then
        echo "  - $(basename "$agent" .md)"
    fi
done

echo ""
echo "Next steps:"
echo "  1. Verify ~/.config/opencode/opencode.json has the correct agents"
echo "  2. Set your ZEN_API_KEY environment variable"
echo "  3. Run 'opencode' to start!"
