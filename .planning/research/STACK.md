# Technology Stack

**Project:** GSD with Design
**Researched:** 2026-03-05
**Overall confidence:** MEDIUM (web search/fetch unavailable; based on PROJECT.md requirements, GSD npm package knowledge, and Claude Code conventions)

## Executive Context

This is not a traditional "pick a framework" stack decision. GSD is a **meta-prompting system** -- it is markdown files, shell scripts, and a thin Node.js CLI wrapper. The "stack" is: markdown agent files, bash/PowerShell installers, and file-placement conventions that Claude Code reads. There are no React components, no databases, no API servers. The entire runtime is Claude Code itself interpreting markdown instructions.

## GSD's Existing Architecture (Upstream)

### Directory Layout (installed to `~/.claude/get-shit-done/`)

```
get-shit-done/
  bin/
    gsd-tools.cjs          # Node.js CLI utilities (websearch, file ops)
  commands/
    gsd/
      new-project.md        # /gsd:new-project slash command
      new-milestone.md      # /gsd:new-milestone slash command
      discuss-phase.md      # /gsd:discuss-phase slash command
      plan-phase.md         # /gsd:plan-phase slash command
      build-phase.md        # /gsd:build-phase slash command
      update.md             # /gsd:update slash command
      status.md             # /gsd:status slash command
  agents/
    researcher.md           # Research agent (spawned 4x in parallel)
    synthesizer.md          # Synthesizes parallel research results
    orchestrator.md         # Phase orchestration agent
    verifier.md             # Build verification agent
  workflows/
    init.md                 # Project initialization workflow
    phase-lifecycle.md      # Phase state machine
  CLAUDE.md                 # Root context loaded by Claude Code
  package.json              # npm package metadata
  install.sh                # Mac/Linux installer
  install.ps1               # Windows installer (PowerShell)
```

### How Commands Work

Claude Code discovers slash commands from `~/.claude/commands/` (global) or `.claude/commands/` (project-local). Each `.md` file whose path matches `commands/{namespace}/{name}.md` becomes `/namespace:name`. The file content is a system prompt that Claude Code follows when the user invokes the command.

### How Agents Work

Agents are markdown files containing system prompts. Commands spawn agents using Claude Code's `Task` tool (subagent). The orchestrator pattern: a command reads the agent file content and passes it as instructions to a `Task` call. Parallel agents are multiple `Task` calls in a single response.

### How the Installer Works

GSD ships as an npm package (`get-shit-done-cc`). The install flow:
1. `npx get-shit-done-cc@latest` runs the package
2. Package contains `install.sh` / `install.ps1`
3. Script copies files to `~/.claude/get-shit-done/`
4. Script symlinks or copies commands to `~/.claude/commands/gsd/`
5. Script writes/updates `CLAUDE.md` in `~/.claude/`

### Key Conventions

| Convention | Detail |
|-----------|--------|
| Command namespace | All GSD commands live under `commands/gsd/` |
| Agent location | `agents/` directory, flat or one-level deep |
| File references | Agents/commands use `$HOME/.claude/get-shit-done/` paths |
| Planning output | All artifacts go to `.planning/` in the project |
| Context loading | Commands read files with `Read` tool, pass content to agents |
| State machine | Phase lifecycle tracked in `.planning/phases.json` |

## Recommended Stack for the Fork

### Core: Markdown Agent System

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Markdown (.md) | N/A | Agent prompts, command definitions | GSD's existing pattern; Claude Code's native interface |
| Node.js (cjs) | >=18 | `bin/gsd-tools.cjs` utilities only | GSD already ships this; no new runtime |
| Bash | 3.2+ | `install.sh` for Mac/Linux | Universal on macOS/Linux; GSD's existing pattern |
| PowerShell | 5.1+ | `install.ps1` for Windows | GSD's existing pattern; ships with Windows 10+ |

### No Additional Dependencies

The PROJECT.md constraint is explicit: "No new dependencies beyond what GSD already uses." This is correct. The design layer is purely additive markdown files. The only "runtime" is Claude Code reading markdown.

### File Placement for Design Layer

```
get-shit-done/                        # Upstream GSD root
  commands/
    gsd/
      design-thinking.md              # /gsd:design-thinking command (NEW)
      design-ui.md                    # /gsd:design-ui command (NEW)
      design-stack.md                 # /gsd:design-stack command (NEW)
      new-project.md                  # MODIFIED: adds design-thinking phase
      discuss-phase.md               # MODIFIED: spawns design agents for UI phases
      plan-phase.md                  # MODIFIED: loads {phase}-UI.md
      update.md                      # MODIFIED: preserves design files
  agents/
    design/                           # NEW directory (namespaced)
      stack-conventions.md            # Stack + git conventions agent
      ui-design.md                    # 8pt grid, color, typography agent
      ux-design.md                    # Hick's Law, decision architecture agent
      motion-design.md               # Animation principles, Framer Motion agent
```

**Naming convention:** All new commands prefixed with `design-`. All new agents in `agents/design/` subdirectory. This creates clean namespace separation and makes update-safety straightforward: the `design/` directory and `design-*` files are the fork's territory.

## Install Script Architecture

### Strategy: Overlay Installer

The fork's installer should NOT replace GSD. It should:
1. Verify GSD is installed (or install it first)
2. Copy design-layer files on top
3. Patch modified commands (merge, not replace)

### install.sh (Mac/Linux)

```bash
#!/usr/bin/env bash
set -euo pipefail

GSD_DIR="$HOME/.claude/get-shit-done"
COMMANDS_DIR="$HOME/.claude/commands/gsd"

# Step 1: Ensure base GSD exists
if [ ! -d "$GSD_DIR" ]; then
  echo "Installing base GSD first..."
  npx get-shit-done-cc@latest
fi

# Step 2: Copy design agents (always safe -- new directory)
mkdir -p "$GSD_DIR/agents/design"
cp agents/design/*.md "$GSD_DIR/agents/design/"

# Step 3: Copy new design commands (always safe -- new files)
cp commands/gsd/design-*.md "$COMMANDS_DIR/"

# Step 4: Patch modified commands (merge strategy)
for cmd in new-project discuss-phase plan-phase update; do
  patch_modified_command "$cmd"
done

# Step 5: Prompt for install scope
echo "Install scope:"
echo "  1) Global (~/.claude/) - available in all projects"
echo "  2) Local (./.claude/) - this project only"
read -rp "Choice [1]: " scope
```

**Key patterns:**
- `set -euo pipefail` -- fail fast on errors
- Check for existing install before proceeding
- New files are always safe to copy (no conflict)
- Modified files need a merge strategy (see below)
- User chooses global vs local scope

### install.ps1 (Windows/PowerShell)

```powershell
$ErrorActionPreference = "Stop"

$GsdDir = Join-Path $env:USERPROFILE ".claude\get-shit-done"
$CommandsDir = Join-Path $env:USERPROFILE ".claude\commands\gsd"

# Same logic as bash, PowerShell syntax
if (-not (Test-Path $GsdDir)) {
    Write-Host "Installing base GSD first..."
    npx get-shit-done-cc@latest
}

# Copy design agents
$designAgentsDir = Join-Path $GsdDir "agents\design"
New-Item -ItemType Directory -Force -Path $designAgentsDir | Out-Null
Copy-Item "agents\design\*.md" -Destination $designAgentsDir -Force
```

**Key patterns:**
- `$ErrorActionPreference = "Stop"` -- PowerShell equivalent of `set -e`
- `Join-Path` for cross-platform path handling
- `New-Item -Force` for idempotent directory creation
- Same overlay logic as bash

### Command Patching Strategy

Modified commands (`new-project`, `discuss-phase`, `plan-phase`, `update`) need careful handling. Three approaches, in order of preference:

**Approach 1: Marker-based injection (RECOMMENDED)**

The fork's installer inserts design-specific blocks between marker comments:

```markdown
<!-- GSD-DESIGN-START -->
[design thinking phase instructions]
<!-- GSD-DESIGN-END -->
```

The installer:
1. Reads the existing command file
2. If markers exist, replaces content between them
3. If markers don't exist, inserts at the correct location
4. Writes back

This is update-safe: `gsd:update` can refresh the base GSD content without touching marker blocks. The design installer can refresh its blocks without touching base GSD content.

**Approach 2: Wrapper commands**

Instead of modifying upstream commands, create wrapper commands that call the originals:

```markdown
# /gsd:new-project (design fork)
1. Run design-thinking phase (inline)
2. Read and follow $HOME/.claude/get-shit-done/commands/gsd/new-project.md
```

Downside: Claude Code doesn't have a native "run another command" mechanism. The wrapper would need to inline the original command's full content, which defeats the purpose.

**Approach 3: Full file replacement with version tracking**

Replace the modified commands entirely, tracking the upstream version they're based on. On update, diff the upstream change and re-apply.

Downside: Complex, error-prone, requires diffing markdown.

**Verdict: Use Approach 1 (marker-based injection).** It's the simplest, most maintainable, and most update-safe.

## Update-Safe File Preservation

### The Problem

When a user runs `/gsd:update`, the upstream GSD update process should not destroy fork-added files. When the fork updates, it should not destroy user customizations.

### Three-Tier File Classification

| Tier | Files | Update Behavior |
|------|-------|----------------|
| **Fork-owned** | `agents/design/*.md`, `commands/gsd/design-*.md` | Fork installer overwrites freely; GSD update ignores (different namespace) |
| **Shared-modified** | `commands/gsd/new-project.md`, `discuss-phase.md`, `plan-phase.md`, `update.md` | Marker-based sections; each system only touches its own markers |
| **User-owned** | `.planning/DESIGN.md`, `{phase}-UI.md` | NEVER overwritten by any installer; these are project artifacts |

### Update Command Modifications

The fork's patch to `update.md` adds:

```
When updating GSD:
1. Preserve all files in agents/design/
2. Preserve all commands matching design-*
3. Preserve marker blocks (<!-- GSD-DESIGN-START --> to <!-- GSD-DESIGN-END -->)
4. After base GSD update, re-run design overlay installer
```

### Version Tracking

Store fork version in `~/.claude/get-shit-done/design-version.json`:

```json
{
  "version": "1.0.0",
  "installed": "2026-03-05",
  "baseGsdVersion": "latest",
  "files": {
    "agents/design/ui-design.md": "sha256:abc...",
    "agents/design/ux-design.md": "sha256:def..."
  }
}
```

This lets the update command detect:
- Has the user customized a design agent? (hash mismatch = don't overwrite, warn)
- Is the fork out of date? (version comparison)

## Agent File Conventions

### Agent Markdown Structure

Every GSD agent follows this pattern:

```markdown
<role>
You are a [role description] agent spawned by [command].
[Core instructions]
</role>

<context>
[What files to read, what information is available]
</context>

<output>
[Expected output format and location]
</output>
```

Design agents should follow the same structure. The `<role>`, `<context>`, `<output>` XML-style blocks are GSD's convention for agent prompt sectioning.

### Agent Spawning Pattern

Commands spawn agents via Task tool calls:

```
Task(prompt: "[agent file content]", description: "UI Design Agent for phase: [name]")
```

Parallel spawning = multiple Task calls in one response. The three design agents (ui-design, ux-design, motion-design) are spawned as a parallel wave, matching GSD's 4-researcher pattern.

### Agent Output Convention

Each agent writes to a temporary file. The orchestrator (the command itself) then synthesizes:

```
agents/design/ui-design.md  --> writes .planning/research/ui-design-output.md
agents/design/ux-design.md  --> writes .planning/research/ux-design-output.md
agents/design/motion-design.md --> writes .planning/research/motion-design-output.md

orchestrator synthesizes --> .planning/{phase}-UI.md
```

## Project Output Files

| File | Location | Created By | Purpose |
|------|----------|-----------|---------|
| `DESIGN.md` | `.planning/DESIGN.md` | design-thinking command | Problem space, emotional core, brand identity |
| `{phase}-UI.md` | `.planning/{phase}-UI.md` | discuss-phase (synthesis) | UI/UX/motion guidance for a specific phase |
| `phases.json` | `.planning/phases.json` | GSD core | Phase state machine (existing) |
| `design-version.json` | `~/.claude/get-shit-done/` | fork installer | Fork version tracking |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Install strategy | Overlay on GSD | Standalone fork | Superset constraint; must track upstream |
| Command patching | Marker injection | Full replacement | Update-safety; upstream can evolve independently |
| Agent namespace | `agents/design/` | `agents/` flat | Collision risk with future GSD agents |
| Command naming | `design-*` prefix | Separate namespace | GSD convention is single `gsd/` namespace |
| Version tracking | JSON + hashes | Git submodule | Overkill; users aren't developers |
| Config format | JSON | YAML/TOML | GSD already uses JSON everywhere |

## Installation Commands

```bash
# From the fork repository
# Mac/Linux
curl -fsSL https://raw.githubusercontent.com/[org]/gsd-with-design/main/install.sh | bash

# Windows (PowerShell)
irm https://raw.githubusercontent.com/[org]/gsd-with-design/main/install.ps1 | iex

# Local development
git clone https://github.com/[org]/gsd-with-design.git
cd gsd-with-design
./install.sh --local   # installs to ./.claude/ in current project
```

## Technology Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Runtime | None (Claude Code is the runtime) | Meta-prompting system; markdown is the code |
| Language for agents | Markdown with XML-style blocks | GSD convention |
| Language for installer | Bash + PowerShell | Cross-platform; GSD's existing pattern |
| Language for utilities | Node.js (cjs) | Only if needed; GSD already has `bin/gsd-tools.cjs` |
| Package manager | npm (npx) | GSD's distribution channel |
| File format for config | JSON | GSD convention |
| Command namespace | `gsd/design-*` | Clean separation within GSD's single namespace |
| Agent namespace | `agents/design/` | Subdirectory isolation |
| Update strategy | Marker-based injection | Survives upstream updates cleanly |
| Version tracking | `design-version.json` + SHA hashes | Detect user customizations, prevent data loss |

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| GSD directory structure | MEDIUM | Based on training data + PROJECT.md references; could not verify live |
| Command/agent conventions | MEDIUM | Consistent with Claude Code docs and PROJECT.md descriptions |
| Installer patterns | HIGH | Standard bash/PowerShell patterns; well-established |
| Marker-based patching | HIGH | Common pattern in config management (ansible, helm, etc.) |
| Update-safety strategy | MEDIUM | Approach is sound but implementation details need validation against actual GSD update.md |
| File placement | HIGH | Directly from PROJECT.md constraints |

## Sources

- `/Users/jayvanam/Documents/GitHub/gsd-with-design/.planning/PROJECT.md` -- Primary project context
- Claude Code slash command documentation (training data, MEDIUM confidence)
- GSD npm package `get-shit-done-cc` (training data, MEDIUM confidence)
- Shell script best practices (training data, HIGH confidence -- stable domain)

## Gaps to Address

- **Verify GSD's actual directory structure** against the live installation at `~/.claude/get-shit-done/` (permission was denied during research)
- **Verify GSD's update.md** implementation to confirm marker-based injection is compatible
- **Check if GSD uses symlinks or copies** for command installation (affects patching strategy)
- **Confirm Claude Code's Task tool API** for agent spawning syntax
- **Test PowerShell install on Windows** -- the pattern is standard but untested against GSD specifically
