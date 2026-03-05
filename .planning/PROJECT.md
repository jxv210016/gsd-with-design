# GSD with Design

## What This Is

A public fork of [get-shit-done](https://github.com/gsd-build/get-shit-done) that integrates the [Design-workflow](https://github.com/AI-by-design/Design-workflow) as a built-in design thinking phase. It adds a mandatory design step to `/gsd:new-project` (Problem Space, Emotional Core, Solution Space + Brand Identity), three parallel design agents for UI phases (ui-design, ux-design, motion-design), and new design commands — all while remaining a clean superset of vanilla GSD.

## Core Value

Every project starts with design thinking that produces a DESIGN.md, and every UI phase is automatically informed by three parallel design agents that map implementation back to the product's emotional promise — without changing any existing GSD behavior for non-UI work.

## Requirements

### Validated

(None yet — ship to validate)

### Active

**R1 — Design Thinking Foundation**
- [ ] R1.1: `commands/gsd/design-thinking.md` — standalone design thinking command
- [ ] R1.2: DESIGN.md schema defined (Problem Space, Emotional Core, Solution Space, Brand Identity) with `schema_version: 1`
- [ ] R1.3: Design thinking integrated into `/gsd:new-project` (after questioning, before research) via marker-based injection
- [ ] R1.4: Design thinking is skippable — "skip" exits cleanly, no DESIGN.md = vanilla behavior downstream
- [ ] R1.5: DESIGN.md validated with user before proceeding ("Does this capture your direction? [Yes/Edit/Regenerate]")

**R2 — Design Agents**
- [ ] R2.1: `workflows/design/stack-conventions.md` — generic/adaptive stack conventions agent, spawned once at init
- [ ] R2.2: `workflows/design/ui-design.md` — 8pt grid, 60-30-10 color, typography, component states (<1500 tokens)
- [ ] R2.3: `workflows/design/ux-design.md` — Hick's Law, Peak-end rule, decision architecture, honest design (<1500 tokens)
- [ ] R2.4: `workflows/design/motion-design.md` — animation principles, reduced motion first, purposeful not decorative (<1500 tokens)
- [ ] R2.5: Agents are stack-agnostic — reference DESIGN.md stack section, never hardcode framework

**R3 — UI Phase Detection & Agent Orchestration**
- [ ] R3.1: UI auto-detection with 2+ keyword threshold across 6 categories (components, layouts, interactions, visual, navigation, states)
- [ ] R3.2: Negative keyword list to suppress false positives (unit test, migration, CLI, API endpoint, backend)
- [ ] R3.3: Manual override markers in ROADMAP.md (`<!-- ui-phase -->`, `<!-- no-ui -->`)
- [ ] R3.4: Three design agents spawned as parallel wave (Task tool) during discuss-phase when UI detected
- [ ] R3.5: Orchestrator synthesizes agent output into `{phase}-UI.md` — concatenation with conflict hierarchy (UX > visual, a11y > motion, brand = tiebreaker)
- [ ] R3.6: Graceful partial results — if 1 agent fails, use outputs from remaining agents
- [ ] R3.7: DESIGN.md loaded only for UI phases (conditional context, never blanket)

**R4 — GSD Workflow Integration**
- [ ] R4.1: `/gsd:new-project` modified via marker injection (`<!-- GSD-DESIGN-START/END -->`) — design thinking after questioning
- [ ] R4.2: `/gsd:discuss-phase` modified — UI detection gate, parallel design agent spawning, {phase}-UI.md synthesis
- [ ] R4.3: `/gsd:plan-phase` modified — loads `{phase}-UI.md` + DESIGN.md alongside CONTEXT.md (optional, graceful if missing)
- [ ] R4.4: All modifications use DESIGN.md existence as guard — no DESIGN.md = identical vanilla GSD behavior
- [ ] R4.5: Non-UI phases produce zero design artifacts

**R5 — Auxiliary Commands**
- [ ] R5.1: `commands/gsd/design-ui.md` — quick reference for UI/UX/motion craft standards (read-only output)
- [ ] R5.2: `commands/gsd/design-stack.md` — quick reference for stack + git conventions (read-only output)

**R6 — Update Safety & Installation**
- [ ] R6.1: `/gsd:update` modified to preserve `commands/gsd/design-*` and `workflows/design/`
- [ ] R6.2: `design-version.json` tracks fork version + file checksums for user customization detection
- [ ] R6.3: `install.sh` (Mac/Linux) — overlay installer: verify base GSD, copy design layer, patch commands via markers
- [ ] R6.4: `install.ps1` (Windows/PowerShell) — same overlay logic, handle execution policy
- [ ] R6.5: Installer supports global (`~/.claude/`) and local (`./.claude/`) with user prompt
- [ ] R6.6: POSIX sh for `install.sh` (not bash) — macOS bash 3.2 compatibility

**R7 — Documentation**
- [ ] R7.1: README documents full integration: new flow, agent lifecycles, {phase}-UI.md, commands, update behavior, install
- [ ] R7.2: No new dependencies beyond what GSD already uses

### Out of Scope

- Modifying GSD commands beyond new-project, discuss-phase, plan-phase, update
- Visual design tools, Figma import/export, component libraries, design token management
- Automated accessibility testing (agents provide a11y guidance in prose instead)
- Image/icon generation, design system documentation generators
- Real-time collaboration, CI/CD design linting pipelines
- Adding new npm dependencies

## Context

- GSD source: `github.com/gsd-build/get-shit-done` — meta-prompting and context engineering system for Claude Code
- Design-workflow source: `github.com/AI-by-design/Design-workflow` — Cursor rules for design thinking, UI/UX/motion craft
- **GSD actual structure:** `~/.claude/get-shit-done/` contains `bin/`, `workflows/`, `templates/`, `references/`, `VERSION` — no `agents/` directory
- GSD commands live in `~/.claude/commands/gsd/` (34 commands)
- GSD uses Task tool with parallel waves — design agents follow the same pattern
- Design-workflow's `.cursor/rules/*.mdc` files become GSD workflows in `workflows/design/`
- Design-workflow's `.claude/commands/design-thinking.md` becomes `commands/gsd/design-thinking.md`
- DESIGN.md replaces what Design-workflow wrote to CLAUDE.md — same content, different location
- Design agents read DESIGN.md first (brand direction), then apply craft rules (how to build well)
- `{phase}-UI.md` is the synthesis of all three design agents' output for a phase
- Stack conventions agent is generic/adaptive — discovers stack from design-thinking answers rather than hardcoding Next.js

## Constraints

- **Superset**: Someone who doesn't use design commands must have identical GSD behavior
- **No new deps**: Only use what GSD already provides (Node.js, its bin tools)
- **File layout**: Design files in `commands/gsd/design-*` and `agents/design/` — clear namespace separation
- **Update safety**: `gsd:update` must never overwrite or delete design files during updates

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| DESIGN.md in `.planning/` not repo root | Consistent with all other GSD planning artifacts | Confirmed |
| Stack agent is generic, not Next.js-specific | Fork should work for any tech stack | Confirmed |
| Three parallel design agents (not one combined) | Matches GSD's parallel wave pattern; each agent has distinct expertise | Confirmed |
| Design thinking is mandatory but skippable | Foundation of the fork, but skip = no DESIGN.md = vanilla behavior | Confirmed |
| UI phase detection triggers design agents automatically | 2+ keyword threshold + negative list + manual override markers | Confirmed |
| Marker-based injection for command patches | `<!-- GSD-DESIGN-START/END -->` — survives upstream updates cleanly | Confirmed |
| Design files in `workflows/design/` not `agents/` | GSD uses `workflows/` dir, not `agents/` — match actual structure | Confirmed |
| Inline synthesis, not separate synthesizer agent | 3 design agents are smaller scope than 4 research agents — orchestrator merges directly | Confirmed |
| Conditional DESIGN.md loading, not blanket | Only loaded for UI phases — prevents context bloat for backend/infra phases | Confirmed |
| POSIX sh for installer, not bash | macOS ships bash 3.2 — POSIX sh avoids version issues | Confirmed |

---
*Last updated: 2026-03-05 after initialization*
