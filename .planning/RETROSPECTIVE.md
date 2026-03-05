# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 -- MVP

**Shipped:** 2026-03-05
**Phases:** 7 | **Plans:** 13

### What Was Built
- Design thinking interview command producing structured DESIGN.md
- Four design agent prompts (stack-conventions, ui-design, ux-design, motion-design)
- UI auto-detection and parallel agent orchestration with {phase}-UI.md synthesis
- Marker-based injection into 3 existing GSD workflows
- Cross-platform installers (POSIX sh + PowerShell) with update-safe preservation
- Complete documentation with Mermaid diagrams and MIT license

### What Worked
- Parallel agent pattern matched GSD's existing Task-based architecture naturally
- Marker-based injection (`GSD-DESIGN-START/END`) kept patches isolated and identifiable
- Guard clause pattern (no DESIGN.md = vanilla GSD) eliminated integration risk
- Each design agent stayed under 800 tokens by using concise action statements
- POSIX sh installer achieved shellcheck compliance on first pass after targeting `--shell=sh`

### What Was Inefficient
- REQUIREMENTS.md was not created during project setup, causing audit to flag process debt
- SUMMARY.md files lacked `requirements-completed` frontmatter, requiring manual cross-referencing
- ROADMAP.md plan checkboxes were not updated during execution (cosmetic but flagged by audit)
- Nyquist validation was never executed -- all 7 VALIDATION.md files remained in draft status

### Patterns Established
- `workflows/design/` namespace for all design agent files
- `commands/gsd/design-*` namespace for design slash commands
- XML structure (`<purpose>/<context>/<rules>/<output_format>`) for all design agents
- Conflict resolution hierarchy: UX > visual, a11y > motion, brand = tiebreaker
- Stack-conventions as init-once blocking gate before parallel agent spawning

### Key Lessons
1. Create REQUIREMENTS.md immediately during project setup -- retrofitting it at audit time creates unnecessary rework
2. Update ROADMAP.md checkboxes in the same commit as plan completion to avoid cosmetic debt accumulation
3. Design agents benefit from strict token budgets -- 800 tokens forced clarity and eliminated bloat
4. Installer scripts should target the lowest common denominator shell (POSIX sh) from the start

### Cost Observations
- Model mix: 100% Opus (quality profile)
- Sessions: ~5
- Notable: Entire milestone shipped in a single day (78 commits)

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 7 | 13 | Initial release -- established design agent architecture |

### Top Lessons (Verified Across Milestones)

1. (First milestone -- lessons need cross-validation in future milestones)
