---
phase: 02-design-agent-prompts
plan: 02
subsystem: design-agents
tags: [ux-design, motion-design, cognitive-science, animation, honest-design, accessibility]

# Dependency graph
requires:
  - phase: 01-design-thinking-foundation
    provides: "DESIGN.md schema with Emotional Core, Problem Space, Brand Identity"
provides:
  - "UX design agent prompt enforcing cognitive science and honest design patterns"
  - "Motion design agent prompt enforcing purposeful animation with reduced-motion-first"
affects: [03-ui-detection-orchestration, 04-gsd-workflow-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared XML prompt structure: <purpose>, <context>, <rules>, <output_format>"
    - "Conditional recipes keyed to DESIGN.md Emotional Core with fallback defaults"
    - "Stack-agnostic rules referencing STACK.md for implementation syntax"

key-files:
  created:
    - "workflows/design/ux-design.md"
    - "workflows/design/motion-design.md"
  modified: []

key-decisions:
  - "Both agents under ~800 tokens each (well within 1500 budget) by using concise action statements"
  - "Honest design rules marked non-negotiable in UX agent -- no conditional override"
  - "prefers-reduced-motion rules marked non-negotiable in motion agent -- no conditional override"

patterns-established:
  - "Non-negotiable sections: design rules that cannot be overridden by brand direction"
  - "Fallback defaults: every conditional recipe handles missing DESIGN.md fields"

requirements-completed: [R2.3, R2.4, R2.5]

# Metrics
duration: ~3min
completed: 2026-03-05
---

# Phase 2 Plan 02: UX and Motion Design Agents Summary

**UX agent with Hick's Law, Peak-end rule, and honest design enforcement; motion agent with duration/easing defaults, enter/exit recipes, and prefers-reduced-motion as non-negotiable**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-05T16:46:33Z
- **Completed:** 2026-03-05T16:48:00Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments
- UX design agent covering 8 behavioral dimensions: cognitive load, decision architecture, feedback, error/empty states, honest design, forms, accessibility, Peak-end rule
- Motion design agent covering 8 motion dimensions: duration defaults, easing, safe-to-animate, enter/exit recipes, stagger, motion gaps, accessibility, restraint principle
- Both agents fully stack-agnostic with zero framework/library names (R2.5)
- Conditional recipes keyed to DESIGN.md Emotional Core with graceful fallback defaults

## Task Commits

Each task was committed atomically:

1. **Task 1: Create UX design agent prompt** - `335e7b9` (feat)
2. **Task 2: Create motion design agent prompt** - `ad4f2e7` (feat)

## Files Created/Modified
- `workflows/design/ux-design.md` - UX psychology and honest design agent prompt (579 words)
- `workflows/design/motion-design.md` - Motion design and animation agent prompt (522 words)

## Decisions Made
- Kept both agents concise (~550-580 words each) rather than filling to the 1500 token budget -- principles are stated as action rules, not explanations
- Honest design and prefers-reduced-motion marked as non-negotiable sections that cannot be overridden by brand direction or Emotional Core
- Both agents reference DESIGN.md and STACK.md but never cross-reference each other (agent independence)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Both UX and motion design agents are complete and ready for Phase 3 orchestrator to spawn via Task()
- Combined with Plan 01 (stack-conventions + UI design agents), all four design agent prompts will be available in workflows/design/
- Phase 3 can register these as subagent_types and spawn them in parallel

## Self-Check: PASSED

- FOUND: `workflows/design/ux-design.md`
- FOUND: `workflows/design/motion-design.md`
- FOUND: `02-02-SUMMARY.md`
- FOUND: commit `335e7b9`
- FOUND: commit `ad4f2e7`

---
*Phase: 02-design-agent-prompts*
*Completed: 2026-03-05*
