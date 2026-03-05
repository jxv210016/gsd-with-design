# Phase 1: Design Thinking Foundation - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Create the design-thinking command (`commands/gsd/design-thinking.md`) and define the DESIGN.md schema (Problem Space, Emotional Core, Solution Space, Brand Identity) with `schema_version: 1`. Includes skip support and user validation. This is the foundation everything else depends on — no design agents, no UI detection, no GSD patching.

</domain>

<decisions>
## Implementation Decisions

### Interview Flow
- Linear progression: Problem Space -> Emotional Core -> Solution Space -> Brand Identity, each building on prior answers
- Use AskUserQuestion with concrete options (+ automatic "Other") for each key decision — 2-3 questions per section (8-12 total)
- Include inline examples of good vs bad answers to guide users (e.g., Emotional Core: "modern and clean" vs "calm confidence — like a trusted advisor who never rushes you")
- Load PROJECT.md if it exists to pre-fill context (project name, description, tech stack) — avoid re-asking what new-project already captured

### DESIGN.md Schema Depth
- Structured bullet points under consistent sub-headings per section (not prose, not key-value)
- Problem Space: Target Users, Core Problem, Current Alternatives, Pain Points
- Emotional Core: One primary emotional statement + 3-4 supporting attributes (e.g., trustworthy, unhurried, expert, approachable)
- Solution Space: Key capabilities, tech stack (framework, styling approach, key libraries) — stack captured here so design agents don't need to also load PROJECT.md
- Brand Identity: Visual direction included — color mood (warm/cool/neutral), typography feel (geometric/humanist/monospace), visual density preference (spacious/balanced/dense)
- Schema includes `schema_version: 1` for future evolution

### Validation UX
- Show complete DESIGN.md, then ask: "Does this capture your direction?" with Yes / Edit / Regenerate
- Edit: Ask "What would you like to change?" in natural language, Claude updates relevant sections, re-displays for approval
- Regenerate: Keep user's interview answers but produce a fresh DESIGN.md interpretation (don't re-interview)
- Unlimited edit/regenerate cycles until user explicitly approves — no artificial limit

### Skip Behavior
- Skip offered at the start only: "Design thinking helps ground your project. Skip to use vanilla GSD, or continue?"
- Once user starts answering, they're committed to finishing (no mid-interview skip)
- Skip produces no DESIGN.md — downstream behavior is identical to vanilla GSD

### Re-run & Standalone
- Standalone command and embedded (new-project) experience are identical — same interview, same validation, same output. Single implementation.
- When DESIGN.md already exists: Ask "Update, View, or Replace?" (consistent with GSD's existing context handling pattern)
- Update = revise specific parts via natural language edits
- View = show current DESIGN.md, then offer update/replace
- Replace = full re-interview from scratch

### Claude's Discretion
- Exact question wording and option labels for each interview question
- Sub-heading names within each DESIGN.md section
- How PROJECT.md context is woven into interview questions (phrasing, pre-filling)
- Error messaging and edge case copy

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- No existing codebase — this is a greenfield project (first phase)

### Established Patterns
- GSD commands live in `~/.claude/commands/gsd/` as markdown prompt files
- GSD uses AskUserQuestion for interactive decision-gathering (discuss-phase pattern)
- GSD uses `<role>/<context>/<output>` conventions for agent/workflow prompts
- File-based communication: agents read from `.planning/` and write back to `.planning/`

### Integration Points
- `commands/gsd/design-thinking.md` — new standalone command
- `.planning/DESIGN.md` — output artifact consumed by Phase 2+ design agents
- Phase 4 will inject this into `new-project.md` via marker-based injection

</code_context>

<specifics>
## Specific Ideas

- Interview should feel like a conversation with a thinking partner, not a form to fill out
- AskUserQuestion choices keep it fast and focused — matching GSD's established interaction pattern
- Emotional Core examples are critical for quality — users default to vague adjectives without guidance
- Stack info in DESIGN.md (not just PROJECT.md) so design agents have a single file to load

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-design-thinking-foundation*
*Context gathered: 2026-03-05*
