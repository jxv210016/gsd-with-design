---
phase: 02-design-agent-prompts
plan: 01
subsystem: workflows
tags: [agent-prompts, design-system, stack-conventions, ui-design, 8pt-grid, 60-30-10]

# Dependency graph
requires:
  - phase: 01-design-thinking-foundation
    provides: "DESIGN.md schema with Tech Stack, Brand Identity, Emotional Core"
provides:
  - "Stack-conventions agent prompt (workflows/design/stack-conventions.md)"
  - "UI design agent prompt (workflows/design/ui-design.md)"
  - "STACK.md translation layer concept (written by stack-conventions agent at runtime)"
affects: [03-ui-detection-orchestration, 04-gsd-workflow-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared XML structure: <purpose>, <context>, <rules>, <output_format>"
    - "Conditional recipes keyed to DESIGN.md values with fallback defaults"
    - "Stack-agnostic design principles with STACK.md translation layer"

key-files:
  created:
    - "workflows/design/stack-conventions.md"
    - "workflows/design/ui-design.md"
  modified: []

key-decisions:
  - "Stack-conventions agent scoped to 4 design dimensions only (spacing, color, typography, motion) -- no linting/testing/file-structure"
  - "UI design agent is fully stack-agnostic with zero framework names -- references STACK.md for implementation syntax"
  - "Both agents use shared XML section structure for consistency across all design agents"

patterns-established:
  - "Design agent prompt pattern: <purpose>/<context>/<rules>/<output_format> XML structure"
  - "Conditional recipe pattern: keyed to DESIGN.md values (Color Mood, Typography Feel, Visual Density) with explicit fallback defaults"
  - "Domain boundary enforcement: UI agent owns visual sizing, excludes UX behavior and animation timing"

requirements-completed: [R2.1, R2.2, R2.5]

# Metrics
duration: ~2min
completed: 2026-03-05
---

# Phase 2 Plan 01: Stack-Conventions and UI Design Agent Prompts Summary

**Stack-conventions Rosetta Stone agent (DESIGN.md to STACK.md translation) and stack-agnostic UI design agent with 8pt grid, 60-30-10 color, ratio-based typography, and full component state coverage**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-05T16:46:31Z
- **Completed:** 2026-03-05T16:48:33Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments
- Created stack-conventions agent prompt that translates abstract design concepts to framework-specific STACK.md recipes covering spacing, color, typography, and motion
- Created UI design agent prompt with concrete design scales (8pt grid, 60-30-10 color distribution, ratio-based typography) and conditional recipes keyed to DESIGN.md Brand Identity
- Both agents use shared XML structure and graceful fallback defaults for missing DESIGN.md values
- UI design agent passes framework-name check: zero mentions of React, Vue, Tailwind, Framer Motion, Angular, or Svelte

## Task Commits

Each task was committed atomically:

1. **Task 1: Create stack-conventions agent prompt** - `e2cfe8a` (feat)
2. **Task 2: Create UI design agent prompt** - `ed34792` (feat)

## Files Created/Modified
- `workflows/design/stack-conventions.md` - Init-once agent that reads DESIGN.md Tech Stack and writes STACK.md translation layer
- `workflows/design/ui-design.md` - Per-phase visual design specification agent with 8pt grid, 60-30-10 color, ratio-based typography, component states, accessibility

## Decisions Made
- **Stack-conventions scope:** Restricted to 4 design dimensions (spacing, color, typography, motion). Explicitly excludes linting, testing, file structure, import conventions, and TypeScript patterns per plan requirements.
- **Stack agnosticism enforcement:** UI design agent states all principles in framework-neutral terms (e.g., "16px spacing" not "p-4"). References "see STACK.md for framework syntax" for implementation-specific guidance.
- **Component state completeness:** UI agent requires 8 states per interactive element (default, hover, focus, active, disabled, loading, error, empty) rather than a subset.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Stack-conventions and UI design agent prompts are complete
- Plan 02-02 (UX design and motion design agents) can proceed in parallel or sequentially
- Phase 3 (UI Detection and Orchestration) will reference these agents for spawning via Task()
- STACK.md translation layer pattern is established for all design agents to consume

## Self-Check: PASSED

- FOUND: `workflows/design/stack-conventions.md`
- FOUND: `workflows/design/ui-design.md`
- FOUND: `02-01-SUMMARY.md`
- FOUND: commit `e2cfe8a`
- FOUND: commit `ed34792`

---
*Phase: 02-design-agent-prompts*
*Completed: 2026-03-05*
