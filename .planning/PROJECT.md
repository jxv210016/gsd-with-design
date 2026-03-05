# GSD with Design

## What This Is

A public fork of [get-shit-done](https://github.com/gsd-build/get-shit-done) that integrates the [Design-workflow](https://github.com/AI-by-design/Design-workflow) as a built-in design thinking phase. It adds a mandatory design step to `/gsd:new-project` (Problem Space, Emotional Core, Solution Space + Brand Identity), three parallel design agents for UI phases (ui-design, ux-design, motion-design), and new design commands — all while remaining a clean superset of vanilla GSD.

## Core Value

Every project starts with design thinking that produces a DESIGN.md, and every UI phase is automatically informed by three parallel design agents that map implementation back to the product's emotional promise — without changing any existing GSD behavior for non-UI work.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Design thinking phase integrated into `/gsd:new-project` flow (after questioning, before research)
- [ ] DESIGN.md written to `.planning/DESIGN.md` with Problem Space, Emotional Core, Brand Identity sections
- [ ] All GSD agents that load PROJECT.md also load DESIGN.md as context
- [ ] `agents/design/stack-conventions.md` — generic/adaptive stack + git conventions agent, spawned once at init
- [ ] `agents/design/ui-design.md` — 8pt grid, 60-30-10 color, typography, component states agent
- [ ] `agents/design/ux-design.md` — Hick's Law, Peak-end rule, decision architecture, honest design agent
- [ ] `agents/design/motion-design.md` — animation principles, Framer Motion recipes, reduced motion agent
- [ ] Three design agents spawned as parallel wave during discuss-phase/plan-phase when UI components detected
- [ ] Orchestrator synthesizes agent output into `{phase}-UI.md`
- [ ] UI phase auto-detection (components, layouts, screens, interactions, animations, forms, empty states, errors, navigation)
- [ ] `gsd:design-thinking` standalone command to re-run design phase on existing project
- [ ] `gsd:design-ui` quick reference command for UI/UX/motion craft standards
- [ ] `gsd:design-stack` quick reference command for stack and git conventions
- [ ] `/gsd:discuss-phase` updated to spawn design agents for UI phases
- [ ] `/gsd:plan-phase` updated to load `{phase}-UI.md` alongside CONTEXT.md
- [ ] `/gsd:update` preserves design files (`commands/gsd/design-*`, `agents/design/`)
- [ ] `install.sh` (Mac/Linux) combined installer: base GSD + design layer
- [ ] `install.ps1` (Windows) combined installer: base GSD + design layer
- [ ] Installer supports global (`~/.claude/`) and local (`./.claude/`) install with user prompt
- [ ] README documents full integration: new flow, agent lifecycles, {phase}-UI.md, commands, update behavior, install
- [ ] Non-UI phases produce zero design artifacts (identical to vanilla GSD)
- [ ] No new dependencies beyond what GSD already uses

### Out of Scope

- Modifying existing GSD commands besides new-project, discuss-phase, plan-phase, update — clean superset principle
- Renaming or restructuring GSD's existing file outputs — maintain compatibility
- Standalone `/gsd:plan` or `/gsd:new-project` replacements — these already exist in GSD
- Adding new npm dependencies — use what GSD already ships with
- Design-workflow's `new-project.md` and `plan.md` commands — GSD already has these

## Context

- GSD source: `github.com/gsd-build/get-shit-done` — meta-prompting and context engineering system for Claude Code
- Design-workflow source: `github.com/AI-by-design/Design-workflow` — Cursor rules for design thinking, UI/UX/motion craft
- GSD uses agent spawning pattern (Task tool) with parallel waves — design agents follow the same pattern
- GSD research agents (4 parallel researchers + synthesizer) are the template for design agent orchestration
- Design-workflow's `.cursor/rules/*.mdc` files become GSD agents in `agents/design/`
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
| DESIGN.md in `.planning/` not repo root | Consistent with all other GSD planning artifacts | -- Pending |
| Stack agent is generic, not Next.js-specific | Fork should work for any tech stack, not just the Design-workflow's defaults | -- Pending |
| Three parallel design agents (not one combined) | Matches GSD's existing parallel research agent pattern; each agent has distinct expertise | -- Pending |
| Design thinking is mandatory in new-project, not optional | The whole point of the fork — design thinking isn't an add-on, it's the foundation | -- Pending |
| UI phase detection triggers design agents automatically | No manual flags needed — if the phase has UI work, design agents run | -- Pending |

---
*Last updated: 2026-03-05 after initialization*
