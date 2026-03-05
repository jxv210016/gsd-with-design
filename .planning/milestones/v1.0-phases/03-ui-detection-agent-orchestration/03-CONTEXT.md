# Phase 3: UI Detection & Agent Orchestration - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire design agents into GSD's discuss-phase with auto-detection and parallel spawning. This phase builds the orchestration logic: detecting UI phases, spawning design agents, synthesizing their output into `{phase}-UI.md`. It does NOT modify GSD commands (Phase 4) or create new user-facing commands (Phase 5).

</domain>

<decisions>
## Implementation Decisions

### Detection Logic
- Detection logic lives in a separate file (`workflows/design/ui-detection.md`), not inline in discuss-phase
- Category-based threshold: match keywords in 2+ different categories (components, layouts, interactions, visual, navigation, states) to trigger
- Scans both ROADMAP.md phase section AND CONTEXT.md (if exists) for keyword matches
- Always auto-decides at threshold — no borderline prompting. Manual override markers handle edge cases
- Negative keyword list suppresses false positives (unit test, migration, CLI, API endpoint, backend)

### Agent Spawning
- Stack-conventions agent runs first (produces STACK.md), then 3 design agents spawn in parallel
- Stack agent runs once at first UI phase, writes `.planning/STACK.md`. Subsequent UI phases read existing STACK.md. User can force re-run with a refresh flag
- Each design agent receives: DESIGN.md (brand), STACK.md (framework conventions), CONTEXT.md (user decisions), and phase goal
- Agents run AFTER CONTEXT.md is written — user finishes discussion first, then design agents run with full context
- Agents return structured sections to orchestrator (don't write files directly — confirmed Phase 2 decision)

### Synthesis & UI.md
- Orchestrator concatenates agent outputs with clear section headers (## UI Design, ## UX Design, ## Motion Design)
- Conflict resolution uses hierarchy (UX > visual, a11y > motion, brand = tiebreaker) and notes resolutions inline: "(Resolved: UX recommendation took priority over motion preference)"
- `{phase}-UI.md` written to phase directory alongside CONTEXT.md and PLAN.md
- Includes a summary section at the top with 5-8 key design constraints for quick planner reference (e.g., "8pt grid", "max 5 nav items", "200ms transitions")

### Failure & Edge Cases
- No DESIGN.md detected at UI phase: prompt user "UI phase detected but no DESIGN.md. Run /gsd:design-thinking first?" — skip or proceed based on choice
- 1 agent fails: retry that agent once. If still fails, synthesize from remaining agents with note about missing guidance
- All 3 agents fail: auto-retry all once. If still failing, continue without {phase}-UI.md with a warning
- Manual override markers (`<!-- ui-phase -->`, `<!-- no-ui -->`) always take absolute priority over keyword detection, with a notice displayed: "UI detection overridden by manual marker"

### Claude's Discretion
- Exact keyword lists for each of the 6 categories
- Exact negative keyword list
- How stack-conventions refresh flag is exposed (CLI flag vs config)
- Timeout duration for agent spawning
- Exact wording of the summary section in {phase}-UI.md

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `workflows/design/stack-conventions.md` (87 lines): Stack discovery agent prompt — ready to be spawned
- `workflows/design/ui-design.md` (112 lines): UI design agent prompt — ready to be spawned
- `workflows/design/ux-design.md` (96 lines): UX design agent prompt — ready to be spawned
- `workflows/design/motion-design.md` (96 lines): Motion design agent prompt — ready to be spawned
- `commands/gsd/design-thinking.md` (336 lines): Creates DESIGN.md — prerequisite artifact

### Established Patterns
- GSD uses `Task()` with `subagent_type` for agent spawning (see plan-phase.md researcher/planner/checker pattern)
- Agent prompts use `<purpose>/<context>/<rules>/<output_format>` XML structure
- File-based communication: agents read from `.planning/`, return output to orchestrator
- GSD workflows live in `~/.claude/get-shit-done/workflows/`

### Integration Points
- discuss-phase.md will call ui-detection logic after CONTEXT.md is written (Phase 4 wires this in)
- plan-phase.md will load `{phase}-UI.md` alongside CONTEXT.md (Phase 4 wires this in)
- `.planning/STACK.md` is a new project-level artifact (written once, read by all design agents)
- `.planning/DESIGN.md` is the prerequisite artifact from design-thinking command

</code_context>

<specifics>
## Specific Ideas

- Stack-conventions as a "gate" before design agents — ensures all 3 agents have framework-specific context
- Concat-with-headers synthesis keeps agent outputs traceable — you can see which agent said what
- Summary section at top of {phase}-UI.md acts as a "cheat sheet" for the planner — most important constraints at a glance
- Notice on marker overrides keeps behavior transparent without being intrusive

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-ui-detection-agent-orchestration*
*Context gathered: 2026-03-05*
