# Phase 7: Documentation & README - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Create a comprehensive README.md documenting the full integration: what it is, how to install, commands reference, design agent lifecycles, {phase}-UI.md flow, update behavior, and superset guarantee. This phase produces documentation only — no code changes.

</domain>

<decisions>
## Implementation Decisions

### README Structure
- Hero + Quick Start first: 1-2 sentence description, quick install command, then detailed sections
- Structure for new users discovering this repo, but link to vanilla GSD for base concepts
- Commands reference table with brief descriptions AND usage examples for each new/modified command
- Brief uninstall section showing which files to remove to revert to vanilla GSD

### Visual Aids
- Mermaid diagrams (GitHub-rendered) for all 4 key flows:
  1. Design thinking pipeline (new-project -> interview -> DESIGN.md -> downstream)
  2. UI phase agent lifecycle (detection -> stack gate -> 3 parallel agents -> synthesis -> {phase}-UI.md)
  3. File architecture (commands/, workflows/design/, .planning/ artifacts)
  4. Update safety flow (how /gsd:update preserves design layer)
- Main pipeline diagram inline in hero/overview area for immediate visual impact
- Other diagrams in collapsible `<details>` sections to keep README scannable

### Installation Instructions
- Lead with one-liner (`curl | sh` style) quick-start
- Expanded details below for manual install, PowerShell/Windows, and edge cases
- Installer handles prerequisite checks (GSD installed, Node.js available) — README trusts the installer, just mentions it briefly
- No troubleshooting section for now — add later based on real user issues

### Tone & Positioning
- Technical and direct: "This adds X. Install with Y. It works by Z." Engineering-audience tone
- Positioned as community fork, additive: "A fork that adds design thinking to GSD" — emphasize non-breaking, compatible, friendly to upstream
- Open to contributions: include a brief contributing section or link to CONTRIBUTING.md signaling PRs are welcome

### Claude's Discretion
- Badge selection (version, license, GSD compatibility) — use if they add value, skip if cluttered
- License approach — match upstream GSD or pick appropriate open-source license
- "How It Works" section depth — pick appropriate detail level per section
- Exact Mermaid diagram syntax and level of detail
- Section ordering after hero + quick start

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `install.sh` (403 lines): POSIX sh overlay installer — document its flags and behavior
- `install.ps1` (410 lines): PowerShell overlay installer — document Windows usage
- `design-version.json` (24 lines): Version tracking with file checksums
- `.claude/commands/gsd/design-thinking.md`: Primary new command (336 lines)
- `.claude/commands/gsd/design-ui.md`: Quick reference command
- `.claude/commands/gsd/design-stack.md`: Quick reference command
- `.claude/commands/gsd/update.md`: Patched update command with design-layer preservation
- `.claude/commands/gsd/new-project.md`: Patched command shim with design thinking injection
- `.claude/commands/gsd/discuss-phase.md`: Patched command shim with UI detection gate
- `.claude/commands/gsd/plan-phase.md`: Patched command shim with design context loading
- `workflows/design/`: 6 workflow files (stack-conventions, ui-design, ux-design, motion-design, ui-detection, orchestrate-design)

### Established Patterns
- GSD commands are slash commands in `.claude/commands/gsd/` — invoked as `/gsd:command-name`
- Design workflows live in `workflows/design/` — spawned by orchestrator, not invoked directly
- `.planning/DESIGN.md` is the central design artifact consumed by all agents
- `.planning/STACK.md` is the framework translation file (written once by stack-conventions agent)
- `{phase}-UI.md` files live in phase directories alongside CONTEXT.md and PLAN.md

### Integration Points
- README.md goes in repo root — the only user-facing documentation file
- References all files in commands/, workflows/design/, and install scripts
- Links to upstream GSD repo for base documentation

</code_context>

<specifics>
## Specific Ideas

- One-liner install as the hero call-to-action — minimize friction to try it
- Collapsible `<details>` for secondary diagrams keeps the README from feeling overwhelming
- Commands table should cover: /gsd:design-thinking, /gsd:design-ui, /gsd:design-stack, plus modified commands (new-project, discuss-phase, plan-phase, update)
- Uninstall section builds trust: "you can always revert to vanilla GSD"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-documentation-readme*
*Context gathered: 2026-03-05*
