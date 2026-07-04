#!/bin/bash

# OpenCode Agents Installer
# Copies agent .md files and generates opencode.json from agents.json

set -e

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

# Ask which tech stack
echo "Select tech stack:"
echo "  1) Python"
echo "  2) TypeScript"
read -p "Enter choice [1-2]: " STACK_CHOICE
echo ""

case "$STACK_CHOICE" in
    1) STACK="python"
       STACK_NAME="Python"
       ;;
    2) STACK="typescript"
       STACK_NAME="TypeScript"
       ;;
    *) echo "Invalid choice. Exiting."
       exit 1
       ;;
esac

# Ask about QA Engineer
read -p "Include QA Engineer/Documenter in the team? (y/N): " -n 1 -r QA_CHOICE
echo ""

if [[ $QA_CHOICE =~ ^[Yy]$ ]]; then
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
