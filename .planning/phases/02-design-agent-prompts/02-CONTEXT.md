# Phase 2: Design Agent Prompts - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Create four design agent prompt files following GSD's conventions: stack-conventions.md, ui-design.md, ux-design.md, and motion-design.md. All live in `workflows/design/`. These are prompt files that define how design agents behave when spawned — not the orchestration logic (Phase 3) or GSD command patches (Phase 4).

</domain>

<decisions>
## Implementation Decisions

### Agent Output Format
- Hybrid format: principles with concrete defaults. E.g., "8pt grid (default spacing: 8/16/24/32px) — adjust scale if DESIGN.md specifies dense/spacious"
- Organized by design dimension (spacing, color, typography, states) — not by component type
- Conditional recipes keyed to DESIGN.md values. E.g., "Read DESIGN.md > Brand Identity > Color Mood. If warm: primary in orange-amber range. If cool: primary in blue-slate range"
- Agents return structured sections to the orchestrator — they do NOT write files directly. Phase 3 orchestrator synthesizes into {phase}-UI.md

### Stack Conventions Agent
- Minimal stack detection: framework, styling, and key libraries with their conventions — not full dev conventions
- Reads DESIGN.md > Solution Space > Tech Stack as single source of truth — no codebase scanning
- Writes to `.planning/STACK.md` (project-level, written once, read by all design agents across all phases)
- Includes framework translation recipes. E.g., "In Tailwind, 8pt grid = spacing scale: p-2 (8px), p-4 (16px), p-6 (24px)"

### Design Principle Depth
- UI agent: concrete scales + rules. Define actual spacing scale, color ratio (60-30-10), type scale with specific values
- UX agent: actionable rules. E.g., "Max 5-7 options per choice point (Hick's Law). If more, use progressive disclosure or categorization"
- Motion agent: duration/easing defaults. E.g., "Micro-interactions: 150-200ms ease-out. Page transitions: 300-400ms ease-in-out. Always respect prefers-reduced-motion"
- Accessibility integrated per agent within its domain: UI = contrast ratios, UX = focus management + screen reader order, Motion = prefers-reduced-motion

### Agent Independence
- Independent + shared STACK.md: each agent reads DESIGN.md and STACK.md independently, no cross-references between agents
- Own domain only for overlap areas: UI = visual sizing, UX = cognitive/behavioral, Motion = animation feedback. Orchestrator merges during synthesis
- Shared prompt structure across all three design agents: identical XML sections (<purpose>, <context>, <output_format>, <rules>)
- Conflicts resolved by Phase 3 orchestrator using hierarchy: UX > visual, a11y > motion, brand = tiebreaker

### Claude's Discretion
- Token budget per agent: target ~1500 tokens, balance conciseness vs. completeness as needed
- Exact section names within the shared prompt structure
- Specific design principles to include vs. omit per agent (within the domains defined above)
- How to structure conditional recipes for edge cases (e.g., when DESIGN.md lacks certain values)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `commands/gsd/design-thinking.md`: Defines DESIGN.md schema — agents consume this output (Problem Space, Emotional Core, Solution Space with Tech Stack, Brand Identity)
- GSD's `<purpose>/<process>/<step>` XML structure for workflow prompts (verified from verify-phase.md, discuss-phase.md)

### Established Patterns
- GSD workflows live in `~/.claude/get-shit-done/workflows/` — design agents go in `workflows/design/`
- Agents are spawned via `Task()` with `subagent_type` parameter
- Agent prompts use `<purpose>` (what it does), then process/rules sections
- File-based communication: agents read from `.planning/`, return output to spawning orchestrator

### Integration Points
- Agents read: `.planning/DESIGN.md` (brand direction) and `.planning/STACK.md` (framework conventions)
- Agents return: structured text sections to Phase 3 orchestrator (not files)
- Phase 3 will register these as subagent_types and spawn them in parallel via Task tool
- Phase 4 will wire them into discuss-phase.md

</code_context>

<specifics>
## Specific Ideas

- Stack conventions agent is the "Rosetta Stone" — translates abstract design concepts into framework-specific syntax so UI/UX/motion agents stay stack-agnostic
- Each agent should feel like a senior specialist on the team: opinionated but grounded in established design principles
- Conditional recipes pattern: "If DESIGN.md says X, then apply Y" — makes agents adaptive without being vague

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-design-agent-prompts*
*Context gathered: 2026-03-05*
