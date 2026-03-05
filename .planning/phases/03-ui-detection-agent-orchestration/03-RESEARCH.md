# Phase 3: UI Detection & Agent Orchestration - Research

**Researched:** 2026-03-05
**Domain:** Workflow orchestration, keyword detection, parallel agent spawning, output synthesis
**Confidence:** HIGH

## Summary

Phase 3 creates three interconnected capabilities: (1) a keyword-based UI detection system that scans phase descriptions to determine whether design agents should run, (2) an orchestration workflow that spawns the stack-conventions agent first, then three design agents in parallel, and (3) a synthesis step that concatenates agent outputs into `{phase}-UI.md` with conflict resolution. All of this is implemented as GSD markdown workflow files -- no JavaScript, no new dependencies.

The project is a meta-prompting system where "code" is markdown prompt files that Claude Code interprets. The existing GSD patterns provide clear precedent: `new-project.md` spawns 4 parallel researchers using `Task()` with `run_in_background=true`, `execute-phase.md` spawns parallel executor agents per wave, and `map-codebase.md` spawns 4 parallel mapper agents. Phase 3 follows these exact patterns but with design-specific agents. The four agent prompts (stack-conventions, ui-design, ux-design, motion-design) already exist in `workflows/design/` and return structured markdown sections to the orchestrator.

**Primary recommendation:** Create two new workflow files -- `workflows/design/ui-detection.md` (detection logic) and `workflows/design/orchestrate-design.md` (agent spawning + synthesis) -- following GSD's existing `<purpose>/<context>/<rules>/<output_format>` XML structure. The orchestrator is called by discuss-phase (wired in Phase 4) and writes `{phase}-UI.md` to the phase directory.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Detection logic lives in a separate file (`workflows/design/ui-detection.md`), not inline in discuss-phase
- Category-based threshold: match keywords in 2+ different categories (components, layouts, interactions, visual, navigation, states) to trigger
- Scans both ROADMAP.md phase section AND CONTEXT.md (if exists) for keyword matches
- Always auto-decides at threshold -- no borderline prompting. Manual override markers handle edge cases
- Negative keyword list suppresses false positives (unit test, migration, CLI, API endpoint, backend)
- Stack-conventions agent runs first (produces STACK.md), then 3 design agents spawn in parallel
- Stack agent runs once at first UI phase, writes `.planning/STACK.md`. Subsequent UI phases read existing STACK.md. User can force re-run with a refresh flag
- Each design agent receives: DESIGN.md (brand), STACK.md (framework conventions), CONTEXT.md (user decisions), and phase goal
- Agents run AFTER CONTEXT.md is written -- user finishes discussion first, then design agents run with full context
- Agents return structured sections to orchestrator (don't write files directly)
- Orchestrator concatenates agent outputs with clear section headers (## UI Design, ## UX Design, ## Motion Design)
- Conflict resolution uses hierarchy (UX > visual, a11y > motion, brand = tiebreaker) and notes resolutions inline
- `{phase}-UI.md` written to phase directory alongside CONTEXT.md and PLAN.md
- Includes a summary section at top with 5-8 key design constraints for quick planner reference
- No DESIGN.md detected at UI phase: prompt user with skip/proceed choice
- 1 agent fails: retry once, then synthesize from remaining with note
- All 3 agents fail: auto-retry all once, then continue without {phase}-UI.md with warning
- Manual override markers (`<!-- ui-phase -->`, `<!-- no-ui -->`) always take absolute priority over keyword detection, with notice displayed

### Claude's Discretion
- Exact keyword lists for each of the 6 categories
- Exact negative keyword list
- How stack-conventions refresh flag is exposed (CLI flag vs config)
- Timeout duration for agent spawning
- Exact wording of the summary section in {phase}-UI.md

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| R3.1 | UI auto-detection with 2+ keyword threshold across 6 categories | Detection logic pattern, keyword categories, threshold algorithm |
| R3.2 | Negative keyword list to suppress false positives | Negative keyword pattern, scan precedence over positive matches |
| R3.3 | Manual override markers in ROADMAP.md (`<!-- ui-phase -->`, `<!-- no-ui -->`) | Marker detection via grep, priority over keyword detection |
| R3.4 | Three design agents spawned as parallel wave (Task tool) during discuss-phase | GSD Task() parallel spawning pattern from new-project/map-codebase |
| R3.5 | Orchestrator synthesizes agent output into `{phase}-UI.md` with conflict hierarchy | Concatenation pattern, conflict resolution rules, summary generation |
| R3.6 | Graceful partial results -- if 1 agent fails, use outputs from remaining agents | Retry-once pattern, partial synthesis, missing-agent notes |
| R3.7 | DESIGN.md loaded only for UI phases (conditional context) | Guard clause pattern, detection gates DESIGN.md loading |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GSD workflow markdown | N/A | All "code" is markdown prompt files | This is a meta-prompting system, not a traditional codebase |
| Task() tool | Claude Code built-in | Agent spawning and parallel execution | GSD's established pattern for subagent orchestration |
| gsd-tools.cjs | GSD bundled | Init, commit, state management, roadmap parsing | Already available at `~/.claude/get-shit-done/bin/` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Bash (grep/cat) | System | Keyword scanning, file existence checks | Detection logic reads ROADMAP.md and CONTEXT.md |
| Write tool | Claude Code built-in | Creating {phase}-UI.md and STACK.md | Output artifact creation |
| Read tool | Claude Code built-in | Loading DESIGN.md, STACK.md, CONTEXT.md | Agent context loading |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Bash grep for detection | Inline Claude analysis | Grep is deterministic and reproducible; Claude analysis would vary between runs |
| Concatenation synthesis | Separate synthesizer agent | 3 agents produce smaller output than 4 research agents -- inline synthesis is simpler per CONTEXT.md decision |

**Installation:** None -- all tools already exist in the GSD ecosystem.

## Architecture Patterns

### Recommended Project Structure
```
workflows/design/
├── ui-detection.md         # NEW: keyword detection logic (callable section, not agent)
├── orchestrate-design.md   # NEW: agent spawning + synthesis orchestrator
├── stack-conventions.md    # EXISTS: stack discovery agent (Phase 2)
├── ui-design.md            # EXISTS: visual design agent (Phase 2)
├── ux-design.md            # EXISTS: UX psychology agent (Phase 2)
└── motion-design.md        # EXISTS: motion design agent (Phase 2)
```

Output artifacts:
```
.planning/
├── DESIGN.md               # Created by /gsd:design-thinking (Phase 1)
├── STACK.md                 # Created by stack-conventions agent (first UI phase)
└── phases/
    └── XX-phase-name/
        ├── XX-CONTEXT.md    # Created by discuss-phase
        ├── XX-UI.md         # NEW: created by orchestrate-design
        └── XX-PLAN.md       # Created by plan-phase
```

### Pattern 1: UI Detection Logic
**What:** A deterministic keyword matching algorithm embedded in a workflow markdown file that reads phase text, counts category matches, checks for override markers, and returns a boolean decision.
**When to use:** Called by discuss-phase after CONTEXT.md is written (Phase 4 wires this).

**Algorithm:**
```
1. Check for manual override markers in ROADMAP.md phase section:
   - `<!-- ui-phase -->` found → return IS_UI=true with notice
   - `<!-- no-ui -->` found → return IS_UI=false with notice

2. Check for negative keywords in phase section + CONTEXT.md:
   - If ANY negative keyword appears as a dominant term → return IS_UI=false

3. Scan for positive keywords across 6 categories:
   - Count how many DISTINCT categories have at least 1 keyword match
   - If matched_categories >= 2 → return IS_UI=true
   - If matched_categories < 2 → return IS_UI=false
```

**Recommended keyword categories (Claude's Discretion area):**

| Category | Keywords |
|----------|----------|
| Components | button, card, modal, dialog, form, input, dropdown, menu, table, list, sidebar, navbar, header, footer, toast, tooltip, tab, accordion, carousel, badge, avatar, checkbox, radio, select, textarea, slider |
| Layouts | grid, flexbox, layout, responsive, breakpoint, column, row, container, page, screen, view, panel, dashboard, sidebar-layout, split-view |
| Interactions | click, hover, drag, scroll, swipe, tap, gesture, touch, press, focus, blur, submit, toggle, expand, collapse, sort, filter, search, pagination, infinite-scroll |
| Visual | color, theme, dark-mode, light-mode, icon, image, animation, transition, gradient, shadow, border, typography, font, spacing, padding, margin, opacity, elevation |
| Navigation | route, page, tab, breadcrumb, link, navigate, redirect, back, forward, menu, drawer, stepper, wizard, onboarding, flow |
| States | loading, error, empty, skeleton, placeholder, disabled, active, selected, checked, expanded, collapsed, success, warning, progress, pending |

**Recommended negative keywords:**
```
unit test, integration test, migration, CLI, API endpoint, backend,
database, schema, model, ORM, queue, worker, cron, webhook,
infrastructure, deployment, CI/CD, pipeline, server, microservice,
authentication logic, authorization, RBAC, token, certificate
```

**Confidence:** HIGH -- this is a straightforward text-matching algorithm. The exact keyword lists are Claude's Discretion per CONTEXT.md.

### Pattern 2: Stack-Conventions Gate (Init-Once)
**What:** Before spawning design agents, check if `.planning/STACK.md` exists. If not, spawn stack-conventions agent first, wait for completion, then spawn design agents. If yes, skip to design agents.
**When to use:** Every time the orchestrator runs for a UI phase.

```
1. Check .planning/STACK.md exists
2. If NOT exists OR refresh flag set:
   a. Spawn stack-conventions agent (reads DESIGN.md, writes STACK.md)
   b. Wait for completion
   c. Verify STACK.md was created
3. Proceed to parallel design agent spawning
```

**Refresh flag recommendation:** Use `<!-- design-refresh-stack -->` marker in ROADMAP.md phase section (consistent with existing marker pattern), rather than a CLI flag or config option. This keeps the interface consistent: markers in ROADMAP.md control design behavior.

### Pattern 3: Parallel Design Agent Spawning
**What:** Spawn 3 design agents simultaneously using Task() with `run_in_background=true`, following the exact pattern from `map-codebase.md` (4 parallel agents) and `new-project.md` (4 parallel researchers).
**When to use:** After stack-conventions gate passes.

```
Task(
  subagent_type="design-agent",  # Note: not a real GSD subagent_type
  model="{agent_model}",
  run_in_background=true,
  description="UI design for Phase {X}",
  prompt="Read workflows/design/ui-design.md for your instructions.

<files_to_read>
- .planning/DESIGN.md (Brand direction)
- .planning/STACK.md (Framework conventions)
- {context_path} (User decisions for this phase)
</files_to_read>

<phase_context>
Phase {X}: {name}
Goal: {goal from ROADMAP.md}
</phase_context>

Return your output as structured markdown sections. Do NOT write files."
)
```

**CRITICAL DETAIL:** Design agents do NOT have registered `subagent_type` values in GSD. They are spawned as generic Task() agents that read their workflow file for instructions. The `subagent_type` field may be omitted or set to a descriptive string. Looking at GSD's codebase, `subagent_type` appears to be a routing hint -- for design agents, the prompt itself contains the full instructions via the `@workflows/design/` file reference or inline prompt.

**Spawn pattern (all 3 in parallel):**
```
# Agent 1: UI Design
Task(run_in_background=true, description="UI design: Phase {X}", prompt=...)

# Agent 2: UX Design
Task(run_in_background=true, description="UX design: Phase {X}", prompt=...)

# Agent 3: Motion Design
Task(run_in_background=true, description="Motion design: Phase {X}", prompt=...)

# Wait for all 3 to complete, collect outputs
```

### Pattern 4: Inline Synthesis with Conflict Resolution
**What:** After all agents return, concatenate their outputs with section headers and apply conflict resolution hierarchy.
**When to use:** After parallel agents complete (or partially complete for graceful degradation).

**Synthesis structure for `{phase}-UI.md`:**
```markdown
---
phase: {phase_number}
generated: {date}
agents_completed: [ui-design, ux-design, motion-design]
agents_failed: []
---

# Phase {X}: {Name} - Design Guidance

## Design Constraints (Quick Reference)
- {constraint 1 -- e.g., "8pt spacing grid, balanced density"}
- {constraint 2 -- e.g., "Max 5 options per choice point (Hick's Law)"}
- {constraint 3 -- e.g., "200ms transitions for dropdowns, ease-out entry"}
- {constraint 4 -- e.g., "4.5:1 contrast minimum, WCAG AA"}
- {constraint 5 -- e.g., "prefers-reduced-motion: opacity-only fallbacks"}
- {up to 8 constraints}

## UI Design
{Output from ui-design agent verbatim}

## UX Design
{Output from ux-design agent verbatim}

## Motion Design
{Output from motion-design agent verbatim}

## Conflict Resolutions
{Any conflicts detected and how they were resolved}
- (Resolved: UX recommendation took priority over motion preference)
```

**Conflict resolution hierarchy (from CONTEXT.md decisions):**
1. UX rules > Visual design rules (usability wins over aesthetics)
2. Accessibility rules > Motion rules (a11y is non-negotiable)
3. Brand direction (DESIGN.md) = tiebreaker when rules are equivalent

### Anti-Patterns to Avoid
- **Agents writing files directly:** Agents return structured sections to the orchestrator. Only the orchestrator writes `{phase}-UI.md`. This is a locked decision from Phase 2 and CONTEXT.md.
- **Prompting user about borderline UI detection:** Always auto-decide. Manual markers handle edge cases. No "is this a UI phase?" question.
- **Blanket DESIGN.md loading:** Only load DESIGN.md when UI detection triggers. Non-UI phases never touch design artifacts.
- **Sequential agent spawning:** Design agents are independent -- spawn all 3 in parallel, not sequentially.
- **Custom subagent_type registration:** Design agents don't need registered subagent_types. They use generic Task() with workflow file references.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Agent spawning | Custom agent framework | GSD's Task() tool with run_in_background | Established pattern used by map-codebase, new-project, execute-phase |
| File path resolution | Manual string concatenation | `gsd-tools.cjs init phase-op` | Returns phase_dir, padded_phase, context_path from INIT JSON |
| State management | Custom state tracking | `gsd-tools.cjs state record-session` | Standard GSD state update pattern |
| Git commits | Manual git commands | `gsd-tools.cjs commit` | Handles commit_docs config flag |
| Roadmap parsing | Regex on ROADMAP.md | `gsd-tools.cjs roadmap get-phase` | Returns structured JSON with phase section text |

**Key insight:** This project creates markdown prompt files, not executable code. The "don't hand-roll" principle means: don't invent new patterns when GSD already has established patterns for the same operation.

## Common Pitfalls

### Pitfall 1: Agent Context Overload
**What goes wrong:** Passing too much context to each design agent, causing them to lose focus or exceed context limits.
**Why it happens:** Temptation to give agents full ROADMAP.md, STATE.md, REQUIREMENTS.md when they only need DESIGN.md, STACK.md, CONTEXT.md, and phase goal.
**How to avoid:** Each agent gets exactly 4 inputs: DESIGN.md (brand), STACK.md (framework), CONTEXT.md (user decisions), and phase goal text. Nothing else.
**Warning signs:** Agent outputs that reference requirements, roadmap phases, or project-level concerns instead of design specifications.

### Pitfall 2: Detection False Positives on Backend Phases
**What goes wrong:** A phase like "User Authentication API" matches keywords like "form", "input", "error" and triggers UI detection.
**Why it happens:** Many UI keywords also appear in backend contexts.
**How to avoid:** Negative keyword check runs FIRST. If the phase text contains dominant backend terms (API endpoint, database, migration, backend), suppress UI detection regardless of positive matches. Order matters: markers > negative > positive.
**Warning signs:** STACK.md and {phase}-UI.md being generated for pure backend phases.

### Pitfall 3: Stack-Conventions Agent Re-running Every Phase
**What goes wrong:** STACK.md gets regenerated for every UI phase, potentially overwriting user customizations.
**Why it happens:** Missing the init-once check (`if STACK.md exists, skip`).
**How to avoid:** Gate pattern: check existence first, only spawn if missing or refresh flag is set. Log "Using existing STACK.md" when skipping.
**Warning signs:** STACK.md modification timestamps changing on every UI phase.

### Pitfall 4: Synthesis Conflicts Going Undetected
**What goes wrong:** UX agent says "minimum touch target 44x44px" but UI agent specs a 32px small button height. Both go into {phase}-UI.md without resolution.
**Why it happens:** Simple concatenation without cross-referencing agent outputs.
**How to avoid:** After concatenation, the orchestrator scans for known conflict patterns:
- Touch target size vs component size
- Animation duration vs feedback timing
- Color contrast vs decorative opacity
- Information density vs cognitive load limits
Log each resolution with "(Resolved: ...)" inline.
**Warning signs:** Contradictory specifications appearing in different sections of {phase}-UI.md.

### Pitfall 5: Graceful Degradation Not Actually Graceful
**What goes wrong:** One agent fails, and the orchestrator either crashes or produces a {phase}-UI.md without indicating what's missing.
**Why it happens:** Missing error handling for partial results.
**How to avoid:** Track which agents completed. If any failed after retry, note it in frontmatter (`agents_failed: [motion-design]`) and add a warning section: "Note: Motion design guidance not available for this phase. [Agent error details]."
**Warning signs:** {phase}-UI.md files with only 1-2 sections and no explanation of missing sections.

## Code Examples

### Detection Algorithm (Pseudocode for workflow)
```bash
# Step 1: Check manual override markers
PHASE_SECTION=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" roadmap get-phase "${PHASE}" | jq -r '.section')

# Check markers in phase section
if echo "$PHASE_SECTION" | grep -q '<!-- ui-phase -->'; then
  echo "UI detection overridden by manual marker: forced UI phase"
  IS_UI=true
elif echo "$PHASE_SECTION" | grep -q '<!-- no-ui -->'; then
  echo "UI detection overridden by manual marker: forced non-UI phase"
  IS_UI=false
else
  # Step 2: Check negative keywords
  NEGATIVE_MATCH=false
  for neg_keyword in "unit test" "migration" "CLI" "API endpoint" "backend" "database" "schema" "ORM" "webhook" "pipeline" "server"; do
    if echo "$PHASE_SECTION $CONTEXT_TEXT" | grep -qi "$neg_keyword"; then
      NEGATIVE_MATCH=true
      break
    fi
  done

  if [ "$NEGATIVE_MATCH" = true ]; then
    IS_UI=false
  else
    # Step 3: Count category matches
    # (orchestrator counts distinct categories with keyword hits)
    # If matched_categories >= 2, IS_UI=true
  fi
fi
```

### Agent Spawning Pattern (from orchestrate-design.md)
```
# Stack-conventions gate
if .planning/STACK.md does NOT exist:
  Task(
    description="Stack conventions: create STACK.md",
    prompt="Read workflows/design/stack-conventions.md for instructions.

    <files_to_read>
    - .planning/DESIGN.md
    </files_to_read>

    Write .planning/STACK.md using the Write tool."
  )
  # Wait for completion, verify STACK.md exists

# Parallel design agent wave
Task(
  run_in_background=true,
  description="UI design: Phase {X}",
  prompt="Read workflows/design/ui-design.md for instructions.

  <files_to_read>
  - .planning/DESIGN.md
  - .planning/STACK.md
  - {context_path}
  </files_to_read>

  <phase_context>
  Phase {X}: {name} -- {goal}
  </phase_context>

  Return structured markdown sections. Do NOT write files."
)

Task(
  run_in_background=true,
  description="UX design: Phase {X}",
  prompt="Read workflows/design/ux-design.md for instructions.
  [same file pattern]"
)

Task(
  run_in_background=true,
  description="Motion design: Phase {X}",
  prompt="Read workflows/design/motion-design.md for instructions.
  [same file pattern]"
)

# Collect all 3 outputs, handle failures, synthesize
```

### {phase}-UI.md Synthesis Template
```markdown
---
phase: {phase_number}
generated: {date}
agents_completed: [{list}]
agents_failed: [{list or empty}]
---

# Phase {X}: {Name} - Design Guidance

## Design Constraints (Quick Reference)
{5-8 bullet points extracted from agent outputs -- the most impactful constraints}

## UI Design
{ui-design agent output}

## UX Design
{ux-design agent output}

## Motion Design
{motion-design agent output}

## Conflict Resolutions
{List of detected conflicts and how they were resolved using the hierarchy}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single combined design agent | 3 specialized agents (ui/ux/motion) | Phase 2 (this project) | Each agent has distinct expertise and stays under 1500 tokens |
| Sequential agent execution | Parallel wave with run_in_background | GSD pattern (established) | 3x faster execution for independent agents |
| Agents write files directly | Agents return to orchestrator | Phase 2 decision (confirmed in CONTEXT.md) | Orchestrator controls synthesis and conflict resolution |

**Deprecated/outdated:**
- `agents/` directory: GSD uses `workflows/` -- all design files go in `workflows/design/`
- Blanket DESIGN.md loading: Replaced by conditional loading (UI phases only)

## Open Questions

1. **Subagent_type for design agents**
   - What we know: GSD uses registered `subagent_type` values like "gsd-executor", "gsd-planner", "gsd-phase-researcher" that map to agent definition files in `~/.claude/agents/`
   - What's unclear: Whether design agents need registered subagent_types or can use generic Task() with inline/referenced prompts
   - Recommendation: Use generic Task() without custom subagent_type. The prompt references the workflow file (`workflows/design/ui-design.md`) which contains all instructions. This avoids modifying GSD's agent registry. If GSD requires a subagent_type, use a descriptive string like "design-agent".

2. **Where orchestrate-design.md gets called**
   - What we know: Phase 4 wires this into discuss-phase.md
   - What's unclear: Whether the orchestrator is called inline in discuss-phase or via a separate workflow reference
   - Recommendation: Build orchestrate-design.md as a self-contained workflow that discuss-phase calls. Phase 3 creates the workflow; Phase 4 adds the call site.

3. **CONTEXT.md availability timing**
   - What we know: Per CONTEXT.md decision, agents run AFTER CONTEXT.md is written
   - What's unclear: Whether the orchestrator is called at the end of discuss-phase's write_context step or as a separate post-step
   - Recommendation: Design as a post-step called after CONTEXT.md is committed. Phase 4 adds this step to discuss-phase.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual verification (markdown prompt files, not executable code) |
| Config file | none -- no test runner for prompt files |
| Quick run command | `grep -q "keyword" workflows/design/ui-detection.md && echo PASS` |
| Full suite command | Manual review of all workflow files |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| R3.1 | UI detection with 2+ category threshold | manual + grep | `grep -c "categories" workflows/design/ui-detection.md` | Wave 0 |
| R3.2 | Negative keyword suppression | manual + grep | `grep -c "negative" workflows/design/ui-detection.md` | Wave 0 |
| R3.3 | Manual override markers | manual + grep | `grep -c "ui-phase\|no-ui" workflows/design/ui-detection.md` | Wave 0 |
| R3.4 | Parallel agent spawning via Task() | manual + grep | `grep -c "run_in_background" workflows/design/orchestrate-design.md` | Wave 0 |
| R3.5 | Synthesis into {phase}-UI.md with conflict hierarchy | manual + grep | `grep -c "conflict\|resolution\|hierarchy" workflows/design/orchestrate-design.md` | Wave 0 |
| R3.6 | Graceful partial results on agent failure | manual + grep | `grep -c "fail\|partial\|retry" workflows/design/orchestrate-design.md` | Wave 0 |
| R3.7 | Conditional DESIGN.md loading | manual + grep | `grep -c "DESIGN.md" workflows/design/orchestrate-design.md` | Wave 0 |

### Sampling Rate
- **Per task commit:** `grep` verification of key terms in created files
- **Per wave merge:** Full manual review of workflow logic
- **Phase gate:** All workflow files exist with correct structure and cross-references

### Wave 0 Gaps
- [ ] `workflows/design/ui-detection.md` -- covers R3.1, R3.2, R3.3
- [ ] `workflows/design/orchestrate-design.md` -- covers R3.4, R3.5, R3.6, R3.7
- No framework install needed -- pure markdown files

## Sources

### Primary (HIGH confidence)
- GSD workflow files at `~/.claude/get-shit-done/workflows/` -- examined discuss-phase.md, plan-phase.md, execute-phase.md, new-project.md, map-codebase.md for Task() spawning patterns
- Existing design agent files at `workflows/design/` -- stack-conventions.md, ui-design.md, ux-design.md, motion-design.md for output format and context requirements
- Phase 2 summaries (02-01-SUMMARY.md, 02-02-SUMMARY.md) -- confirmed agent completion and output patterns
- GSD commands at `~/.claude/commands/gsd/` -- discuss-phase.md for integration point understanding
- `.planning/PROJECT.md` -- confirmed project architecture and key decisions

### Secondary (MEDIUM confidence)
- CONTEXT.md decisions from discuss-phase -- all decisions treated as locked constraints

### Tertiary (LOW confidence)
- None -- all findings verified from primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- GSD patterns are well-established and directly observable in source files
- Architecture: HIGH -- follows existing GSD workflow patterns exactly
- Pitfalls: HIGH -- derived from understanding actual agent behavior and integration points
- Detection algorithm: MEDIUM -- keyword lists are Claude's Discretion; algorithm logic is straightforward

**Research date:** 2026-03-05
**Valid until:** 2026-04-05 (30 days -- stable domain, no external dependencies)
