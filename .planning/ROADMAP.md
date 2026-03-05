# Roadmap — GSD with Design v1.0

## Phase 1: Design Thinking Foundation
**Goal:** Create the design-thinking command and DESIGN.md schema — the foundation everything else depends on.
**Dependencies:** None
**Delivers:** R1.1, R1.2, R1.4, R1.5
**Plans:** 1 plan

Plans:
- [x] 01-01-PLAN.md — Create design-thinking slash command with interview flow, DESIGN.md schema, skip support, and validation loop

- Define DESIGN.md schema (Problem Space, Emotional Core, Solution Space, Brand Identity) with `schema_version: 1`
- Write `commands/gsd/design-thinking.md` — standalone design thinking command
- Structured prompts with examples of good vs bad emotional core statements
- Skip support — "skip" exits cleanly without producing DESIGN.md
- User validation step before finalizing DESIGN.md

## Phase 2: Design Agent Prompts
**Goal:** Create all four design agent prompt files following GSD's `<purpose>/<context>/<rules>/<output_format>` conventions.
**Dependencies:** Phase 1 (DESIGN.md schema must exist for agents to consume)
**Delivers:** R2.1, R2.2, R2.3, R2.4, R2.5
**Plans:** 2/2 plans complete

Plans:
- [ ] 02-01-PLAN.md — Stack-conventions agent (Rosetta Stone) and UI design agent (8pt grid, 60-30-10, typography, states)
- [ ] 02-02-PLAN.md — UX design agent (Hick's Law, honest design, Peak-end) and motion design agent (purposeful animation, reduced-motion first)

- Write `workflows/design/stack-conventions.md` — adaptive stack discovery agent (init-once lifecycle)
- Write `workflows/design/ui-design.md` — 8pt grid, 60-30-10 color, typography, component states
- Write `workflows/design/ux-design.md` — Hick's Law, Peak-end, Fitts's Law, honest design enforcement
- Write `workflows/design/motion-design.md` — purposeful animation, reduced-motion first, restraint principle
- All agents stack-agnostic, <1500 tokens each, read DESIGN.md stack section for framework-appropriate recipes

## Phase 3: UI Detection & Agent Orchestration
**Goal:** Wire design agents into GSD's discuss-phase with auto-detection and parallel spawning.
**Dependencies:** Phase 2 (agents must exist), Phase 1 (DESIGN.md must exist)
**Delivers:** R3.1, R3.2, R3.3, R3.4, R3.5, R3.6, R3.7
**Plans:** 2/2 plans complete

Plans:
- [ ] 03-01-PLAN.md — UI detection workflow with keyword categories, negative suppression, manual override markers, and conditional DESIGN.md gate
- [ ] 03-02-PLAN.md — Design agent orchestration with stack gate, parallel spawning, synthesis into {phase}-UI.md, and graceful degradation

- UI auto-detection logic: 2+ keyword threshold across 6 categories + negative keyword suppression
- Manual override markers (`<!-- ui-phase -->`, `<!-- no-ui -->`)
- Parallel agent wave spawning via Task tool (3 concurrent design agents)
- Inline synthesis into `{phase}-UI.md` with conflict resolution hierarchy
- Graceful partial results — remaining agents used if one fails
- Conditional DESIGN.md loading (UI phases only)

## Phase 4: GSD Workflow Integration
**Goal:** Patch existing GSD commands with marker-based injection to wire in design thinking and design context.
**Dependencies:** Phase 3 (orchestration must work), Phase 1 (design thinking command must exist)
**Delivers:** R1.3, R4.1, R4.2, R4.3, R4.4, R4.5
**Plans:** 3 plans

Plans:
- [ ] 04-01-PLAN.md — Patch new-project workflow with design thinking injection (Step 4.5) and update command shim
- [ ] 04-02-PLAN.md — Patch discuss-phase workflow with UI detection gate, agent orchestration, and UI.md commit
- [ ] 04-03-PLAN.md — Patch plan-phase workflow with design context loading and cross-file guard clause verification

- Patch `new-project.md` — inject design thinking phase after questioning, before research
- Patch `discuss-phase.md` — inject UI detection gate and design agent spawning
- Patch `plan-phase.md` — inject DESIGN.md + {phase}-UI.md loading (optional/graceful)
- All patches use `<!-- GSD-DESIGN-START -->` / `<!-- GSD-DESIGN-END -->` markers
- Guard clause pattern: no DESIGN.md = vanilla GSD behavior on all paths

## Phase 5: Auxiliary Commands & Quick Reference
**Goal:** Add convenience commands for design reference during implementation.
**Dependencies:** Phase 1 (DESIGN.md schema), Phase 2 (agent content to reference)
**Delivers:** R5.1, R5.2

- Write `commands/gsd/design-ui.md` — outputs UI/UX/motion craft standards (read-only)
- Write `commands/gsd/design-stack.md` — outputs stack + git conventions (read-only)

## Phase 6: Update Safety & Installation
**Goal:** Ensure the fork survives GSD updates and can be installed cross-platform.
**Dependencies:** Phase 4 (must know which files to preserve)
**Delivers:** R6.1, R6.2, R6.3, R6.4, R6.5, R6.6

- Patch `update.md` to preserve `commands/gsd/design-*` and `workflows/design/`
- Create `design-version.json` with version + file checksums
- Write `install.sh` in POSIX sh — overlay installer (verify base GSD, copy design files, patch commands)
- Write `install.ps1` in PowerShell — same overlay logic with execution policy handling
- Global vs local install prompt with existing installation detection

## Phase 7: Documentation & README
**Goal:** Document the full integration for users.
**Dependencies:** All prior phases (document what was built)
**Delivers:** R7.1, R7.2

- README: what it is, how it works, install, commands, agent lifecycles, {phase}-UI.md flow
- Update behavior documentation
- Superset guarantee explanation
