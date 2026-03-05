# GSD with Design

## What This Is

A public fork of [get-shit-done](https://github.com/gsd-build/get-shit-done) that integrates the [Design-workflow](https://github.com/AI-by-design/Design-workflow) as a built-in design thinking phase. It adds a design step to `/gsd:new-project` (Problem Space, Emotional Core, Solution Space + Brand Identity), three parallel design agents for UI phases (ui-design, ux-design, motion-design), and new design commands -- all while remaining a clean superset of vanilla GSD.

## Core Value

Every project starts with design thinking that produces a DESIGN.md, and every UI phase is automatically informed by three parallel design agents that map implementation back to the product's emotional promise -- without changing any existing GSD behavior for non-UI work.

## Requirements

### Validated

- R1.1: Standalone `/gsd:design-thinking` slash command -- v1.0
- R1.2: DESIGN.md schema with Problem Space, Emotional Core, Solution Space, Brand Identity -- v1.0
- R1.3: Design thinking integrated into `/gsd:new-project` via marker injection -- v1.0
- R1.4: Skip support (no DESIGN.md = vanilla behavior) -- v1.0
- R1.5: User validation loop (Edit/Regenerate/Yes) -- v1.0
- R2.1: Stack-conventions agent with init-once lifecycle -- v1.0
- R2.2: UI design agent (8pt grid, 60-30-10, typography, states) -- v1.0
- R2.3: UX design agent (Hick's Law, Peak-end, honest design) -- v1.0
- R2.4: Motion design agent (purposeful animation, reduced-motion first) -- v1.0
- R2.5: All design agents stack-agnostic -- v1.0
- R3.1: UI auto-detection with 2+ keyword threshold across 6 categories -- v1.0
- R3.2: Negative keyword suppression for backend-dominant phases -- v1.0
- R3.3: Manual override markers (`<!-- ui-phase -->`, `<!-- no-ui -->`) -- v1.0
- R3.4: Parallel agent spawning via Task() -- v1.0
- R3.5: Synthesis into `{phase}-UI.md` with conflict resolution hierarchy -- v1.0
- R3.6: Graceful degradation (partial results on agent failure) -- v1.0
- R3.7: Conditional DESIGN.md loading (UI phases only) -- v1.0
- R4.1: `/gsd:new-project` patched with GSD-DESIGN markers -- v1.0
- R4.2: `/gsd:discuss-phase` patched with UI detection and orchestration -- v1.0
- R4.3: `/gsd:plan-phase` patched with design context loading -- v1.0
- R4.4: Guard clause pattern (no DESIGN.md = vanilla GSD) -- v1.0
- R4.5: Non-UI phases produce zero design artifacts -- v1.0
- R5.1: `/gsd:design-ui` read-only quick-reference command -- v1.0
- R5.2: `/gsd:design-stack` read-only quick-reference command -- v1.0
- R6.1: `/gsd:update` preserves design-layer files -- v1.0
- R6.2: `design-version.json` with version and SHA-256 checksums -- v1.0
- R6.3: `install.sh` POSIX sh overlay installer -- v1.0
- R6.4: `install.ps1` PowerShell overlay installer -- v1.0
- R6.5: Global vs local install detection with user prompt -- v1.0
- R6.6: POSIX sh compliance (shellcheck clean) -- v1.0
- R7.1: README.md with Mermaid diagrams and full documentation -- v1.0
- R7.2: Documentation-only phase (no code modified) -- v1.0

### Active

(None -- planning next milestone)

### Out of Scope

- Modifying GSD commands beyond new-project, discuss-phase, plan-phase, update
- Visual design tools, Figma import/export, component libraries, design token management
- Automated accessibility testing (agents provide a11y guidance in prose instead)
- Image/icon generation, design system documentation generators
- Real-time collaboration, CI/CD design linting pipelines
- Adding new npm dependencies

## Context

Shipped v1.0 with ~5,400 lines across 82 files (markdown prompts + POSIX sh/PowerShell installers).
Tech stack: GSD meta-prompting system, Claude Code slash commands, Task-based parallel agents.
16 design-layer files total: 4 agent prompts, 2 orchestration workflows, 6 command shims, 2 installers, 1 version tracker, 1 patched update command.

## Constraints

- **Superset**: Someone who doesn't use design commands must have identical GSD behavior
- **No new deps**: Only use what GSD already provides (Node.js, its bin tools)
- **File layout**: Design files in `commands/gsd/design-*` and `workflows/design/` -- clear namespace separation
- **Update safety**: `gsd:update` must never overwrite or delete design files during updates

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| DESIGN.md in `.planning/` not repo root | Consistent with all other GSD planning artifacts | Good |
| Stack agent is generic, not Next.js-specific | Fork should work for any tech stack | Good |
| Three parallel design agents (not one combined) | Matches GSD's parallel wave pattern; each agent has distinct expertise | Good |
| Design thinking is mandatory but skippable | Foundation of the fork, but skip = no DESIGN.md = vanilla behavior | Good |
| UI phase detection triggers design agents automatically | 2+ keyword threshold + negative list + manual override markers | Good |
| Marker-based injection for command patches | `<!-- GSD-DESIGN-START/END -->` -- survives upstream updates cleanly | Good |
| Design files in `workflows/design/` not `agents/` | GSD uses `workflows/` dir, not `agents/` -- match actual structure | Good |
| Inline synthesis, not separate synthesizer agent | 3 design agents are smaller scope than 4 research agents -- orchestrator merges directly | Good |
| Conditional DESIGN.md loading, not blanket | Only loaded for UI phases -- prevents context bloat for backend/infra phases | Good |
| POSIX sh for installer, not bash | macOS ships bash 3.2 -- POSIX sh avoids version issues | Good |

---
*Last updated: 2026-03-05 after v1.0 milestone*
