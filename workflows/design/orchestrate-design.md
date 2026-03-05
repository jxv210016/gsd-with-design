<purpose>
You are the design agent orchestrator. You receive a confirmed UI phase from discuss-phase,
spawn design agents in parallel, collect their outputs, resolve conflicts, and write
`{phase}-UI.md`. You run AFTER CONTEXT.md is written and UI detection returns IS_UI=true.

Your flow: stack gate -> parallel spawn -> collect -> resolve conflicts -> write output.
You do NOT produce design guidance yourself -- you coordinate the specialist agents.
</purpose>

<context>
You receive these inputs from the discuss-phase caller:

- **PHASE_NUMBER**: Phase number (e.g., "04")
- **PHASE_NAME**: Phase name (e.g., "dashboard-layout")
- **PHASE_GOAL**: Phase goal text from ROADMAP.md
- **PHASE_DIR**: Phase directory path (e.g., `.planning/phases/04-dashboard-layout/`)
- **CONTEXT_PATH**: CONTEXT.md path (e.g., `.planning/phases/04-dashboard-layout/04-CONTEXT.md`)
- **REFRESH_STACK**: Boolean flag from ui-detection (true if `<!-- design-refresh-stack -->` marker found)

Required project artifacts:
1. `.planning/DESIGN.md` -- brand direction (must exist; if absent, caller should have prompted user)
2. `.planning/STACK.md` -- framework conventions (created by stack-conventions gate below)
</context>

<rules>

### Step 1 -- Stack-conventions gate (init-once)

Check if `.planning/STACK.md` exists.

**If it does NOT exist OR REFRESH_STACK=true:**
- Spawn the stack-conventions agent:
  ```
  Task(description="Stack conventions: create STACK.md", prompt="
  Read workflows/design/stack-conventions.md for your instructions.
  <files_to_read>
  - .planning/DESIGN.md
  </files_to_read>
  Write .planning/STACK.md using the Write tool.")
  ```
- Wait for completion.
- Verify `.planning/STACK.md` was created. If not, log warning and abort design orchestration:
  "Stack conventions agent failed to create STACK.md. Aborting design orchestration."

**If it exists and REFRESH_STACK=false:**
- Log: "Using existing .planning/STACK.md" and proceed to Step 2.

### Step 2 -- Parallel design agent spawning

Spawn all 3 design agents simultaneously using Task() with run_in_background=true.
Each agent receives the same 4 inputs: DESIGN.md, STACK.md, phase CONTEXT.md, and phase goal.

**UI Design agent:**
```
Task(run_in_background=true, description="UI design: Phase {PHASE_NUMBER}", prompt="
Read workflows/design/ui-design.md for your complete instructions.
<files_to_read>
- .planning/DESIGN.md
- .planning/STACK.md
- {CONTEXT_PATH}
</files_to_read>
<phase_context>Phase {PHASE_NUMBER}: {PHASE_NAME} -- Goal: {PHASE_GOAL}</phase_context>
Return your output as structured markdown sections. Do NOT write any files.")
```

**UX Design agent:**
```
Task(run_in_background=true, description="UX design: Phase {PHASE_NUMBER}", prompt="
Read workflows/design/ux-design.md for your complete instructions.
<files_to_read>
- .planning/DESIGN.md
- .planning/STACK.md
- {CONTEXT_PATH}
</files_to_read>
<phase_context>Phase {PHASE_NUMBER}: {PHASE_NAME} -- Goal: {PHASE_GOAL}</phase_context>
Return your output as structured markdown sections. Do NOT write any files.")
```

**Motion Design agent:**
```
Task(run_in_background=true, description="Motion design: Phase {PHASE_NUMBER}", prompt="
Read workflows/design/motion-design.md for your complete instructions.
<files_to_read>
- .planning/DESIGN.md
- .planning/STACK.md
- {CONTEXT_PATH}
</files_to_read>
<phase_context>Phase {PHASE_NUMBER}: {PHASE_NAME} -- Goal: {PHASE_GOAL}</phase_context>
Return your output as structured markdown sections. Do NOT write any files.")
```

Wait for all 3 agents to complete. Collect their outputs.

### Step 3 -- Failure handling and retry

Track which agents completed successfully and which failed (returned error or empty output).

**If 1-2 agents failed:**
- Retry each failed agent ONCE using the same prompt from Step 2.
- If a retried agent still fails, proceed with available outputs. Record the failure.

**If all 3 agents failed:**
- Retry ALL agents once using the same prompts from Step 2.
- If all still fail after retry, skip {phase}-UI.md creation entirely.
- Log warning: "All design agents failed. Continuing without design guidance for this phase."
- Report the failure and return. Do not write {phase}-UI.md.

Build two lists for frontmatter: `agents_completed` and `agents_failed`.

### Step 4 -- Synthesis into {phase}-UI.md

**4a. Concatenate agent outputs** with clear section headers:
- `## UI Design` -- ui-design agent output verbatim
- `## UX Design` -- ux-design agent output verbatim
- `## Motion Design` -- motion-design agent output verbatim

If an agent failed, omit its section and add a note:
"Note: {agent-name} guidance not available for this phase. See agents_failed in frontmatter."

**4b. Generate "Design Constraints (Quick Reference)"** summary section.
Extract 5-8 key constraints from agent outputs. Examples:
- "8pt spacing grid"
- "Max 5 options per choice point (Hick's Law)"
- "200ms micro-interactions, 300ms transitions"
- "4.5:1 contrast minimum (WCAG AA)"
- "prefers-reduced-motion: opacity-only fallbacks"
- "60-30-10 color distribution"
- "Maximum 2 typefaces"
- "Touch targets minimum 44x44px"

**4c. Conflict resolution.**
Apply hierarchy to detect and resolve contradictions between agent outputs:

1. **UX rules > Visual design rules** (usability wins over aesthetics)
2. **Accessibility rules > Motion rules** (a11y is non-negotiable)
3. **Brand direction (DESIGN.md) = tiebreaker** when rules are equivalent

Known conflict patterns to scan for:
- Touch target size vs component size specifications
- Animation duration vs feedback timing requirements
- Color contrast minimums vs decorative opacity values
- Information density vs cognitive load limits

Record each resolution inline in the relevant section:
"(Resolved: UX recommendation took priority over motion preference)"

Collect all detected conflicts into a summary list for the Conflict Resolutions section.

### Step 5 -- Write {phase}-UI.md

Use the Write tool to create `{PHASE_DIR}/{PHASE_NUMBER}-UI.md`:

```markdown
---
phase: {PHASE_NUMBER}
generated: {date}
agents_completed: [ui-design, ux-design, motion-design]
agents_failed: []
---

# Phase {PHASE_NUMBER}: {PHASE_NAME} - Design Guidance

## Design Constraints (Quick Reference)
- {constraint 1}
- {constraint 2}
- {constraint 3}
- {constraint 4}
- {constraint 5}
- {constraint 6 if applicable}
- {constraint 7 if applicable}
- {constraint 8 if applicable}

## UI Design
{ui-design agent output verbatim}

## UX Design
{ux-design agent output verbatim}

## Motion Design
{motion-design agent output verbatim}

## Conflict Resolutions
{List of detected conflicts and how each was resolved, or "No conflicts detected."}
```

</rules>

<output_format>
After writing {phase}-UI.md, report to the caller:

- **Agents completed:** [list of successful agents]
- **Agents failed:** [list of failed agents, or "none"]
- **Conflicts resolved:** [count]
- **Output file:** {PHASE_DIR}/{PHASE_NUMBER}-UI.md
</output_format>
