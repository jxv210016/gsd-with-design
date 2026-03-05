# Phase 4: GSD Workflow Integration - Research

**Researched:** 2026-03-05
**Domain:** Marker-based injection patching of GSD command/workflow files
**Confidence:** HIGH

## Summary

Phase 4 patches three existing GSD files to wire in design thinking (new-project), UI detection + agent orchestration (discuss-phase), and design context loading (plan-phase). All patches use `<!-- GSD-DESIGN-START -->` / `<!-- GSD-DESIGN-END -->` marker-based injection so upstream GSD updates do not collide with design additions. The guard clause pattern (no DESIGN.md = vanilla behavior) ensures the superset guarantee.

The three target files are GSD workflow files (not the command shims). The command files (`~/.claude/commands/gsd/new-project.md`, `discuss-phase.md`, `plan-phase.md`) are thin wrappers that `@import` the workflow files. The actual logic lives in `~/.claude/get-shit-done/workflows/new-project.md`, `workflows/discuss-phase.md`, and `workflows/plan-phase.md`. However, since this fork ships its own copies of these files (the project repo has `commands/gsd/design-thinking.md` already), the patches should be applied to forked copies stored in the project repo, not to the user's global GSD installation. The installer (Phase 6) handles copying patched files into the user's `~/.claude/` directory.

**Primary recommendation:** Create patched copies of the three GSD command files in the project repo under `.claude/commands/gsd/` (where `design-thinking.md` already lives), and patched workflow files under `workflows/` -- each with marker-delimited injection blocks. The installer overlays these onto the user's GSD installation.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| R1.3 | Design thinking integrated into /gsd:new-project (after questioning, before research) via marker-based injection | new-project.md workflow analysis identifies injection point between Step 4 (Write PROJECT.md) and Step 5 (Workflow Preferences) / Step 6 (Research Decision) |
| R4.1 | /gsd:new-project modified via marker injection -- design thinking after questioning | Same as R1.3; marker block wraps design-thinking invocation with skip guard |
| R4.2 | /gsd:discuss-phase modified -- UI detection gate, parallel design agent spawning, {phase}-UI.md synthesis | discuss-phase.md workflow analysis identifies injection point after write_context step, before confirm_creation/git_commit |
| R4.3 | /gsd:plan-phase modified -- loads {phase}-UI.md + DESIGN.md alongside CONTEXT.md (optional, graceful if missing) | plan-phase.md workflow analysis identifies injection in Step 7 (context path loading) and planner prompt (Step 8) |
| R4.4 | All modifications use DESIGN.md existence as guard -- no DESIGN.md = identical vanilla GSD behavior | Guard clause pattern documented in Architecture Patterns |
| R4.5 | Non-UI phases produce zero design artifacts | UI detection gate (from Phase 3) ensures IS_UI=false phases skip all design work |
</phase_requirements>

## Standard Stack

### Core

This phase creates no new libraries or tools. It patches existing GSD markdown prompt files.

| File | Location | Purpose | Why Patched |
|------|----------|---------|-------------|
| new-project.md | `.claude/commands/gsd/new-project.md` | Project initialization | Inject design thinking invocation after questioning |
| discuss-phase.md | `.claude/commands/gsd/discuss-phase.md` | Phase context gathering | Inject UI detection + design agent orchestration |
| plan-phase.md | `.claude/commands/gsd/plan-phase.md` | Phase planning | Inject DESIGN.md + {phase}-UI.md loading |

### Supporting Artifacts (from Prior Phases)

| File | Location | Created By | Consumed By |
|------|----------|------------|-------------|
| design-thinking.md | `.claude/commands/gsd/design-thinking.md` | Phase 1 | new-project patch (invoked via inline reference) |
| ui-detection.md | `workflows/design/ui-detection.md` | Phase 3 | discuss-phase patch (inlined logic) |
| orchestrate-design.md | `workflows/design/orchestrate-design.md` | Phase 3 | discuss-phase patch (called after UI detection) |
| DESIGN.md | `.planning/DESIGN.md` | design-thinking command | Guard clause check in all three patches |
| STACK.md | `.planning/STACK.md` | stack-conventions agent | plan-phase patch (optional loading) |
| {phase}-UI.md | `.planning/phases/XX-name/XX-UI.md` | orchestrate-design | plan-phase patch (optional loading) |

## Architecture Patterns

### Marker-Based Injection Pattern

**What:** All design-layer additions to GSD files are wrapped in HTML comment markers that delimit the injected block. This allows the installer to locate, replace, or remove design additions without affecting surrounding GSD content.

**Marker format:**
```markdown
<!-- GSD-DESIGN-START -->
{injected design-layer content}
<!-- GSD-DESIGN-END -->
```

**Rules:**
- One marker pair per injection point per file (a file may have multiple injection points)
- Content between markers is entirely owned by the design fork
- Upstream GSD updates that don't touch the injection zone survive cleanly
- The installer can re-inject updated content by finding and replacing between markers

### Guard Clause Pattern

**What:** Every injected block starts with a DESIGN.md existence check. If no DESIGN.md exists, the entire injected block is skipped, producing identical vanilla GSD behavior.

**Pattern:**
```markdown
<!-- GSD-DESIGN-START -->
## Design Thinking (optional)

Check if `.planning/DESIGN.md` exists or if design thinking was previously run.

**If no DESIGN.md AND user has not explicitly skipped design thinking:**
- [offer design thinking / inject behavior]

**If no DESIGN.md (skipped or not run):**
- Skip this section entirely. Continue with vanilla GSD flow.
<!-- GSD-DESIGN-END -->
```

**Why:** Requirement R4.4 -- the superset guarantee. Users who never run design-thinking get identical GSD behavior on all code paths.

### Injection Point Strategy (Per File)

#### 1. new-project.md -- Design Thinking Injection

**Injection point:** Between Step 4 (Write PROJECT.md) and Step 5 (Workflow Preferences).

**Rationale:** By Step 4, the user has answered all project questions and PROJECT.md exists. Design thinking needs PROJECT.md context (Step 2 of design-thinking command loads it). Running design thinking here means DESIGN.md exists before research begins, so research can optionally account for design direction. Running it BEFORE Step 5 (config) means the design step happens during the creative exploration phase, not during the configuration phase.

**What to inject:**
- A new step (e.g., "Step 4.5: Design Thinking") that:
  1. Checks if `.planning/DESIGN.md` already exists (skip if yes)
  2. Offers design thinking with AskUserQuestion: "Run design thinking to create a design brief?" with options "Yes" / "Skip"
  3. If "Yes": Inline-reference the design-thinking command process (Steps 1-7 from `commands/gsd/design-thinking.md`), but skip Step 0 (re-run check) and Step 1 (skip offer -- user just said yes) -- go directly to Step 2 (load PROJECT.md)
  4. If "Skip": Continue without DESIGN.md. Log: "Design thinking skipped. Downstream behavior will be vanilla GSD."
  5. Auto mode: Skip design thinking by default (no user prompt) -- consistent with auto mode's non-interactive nature. OR offer a `--design` flag to opt-in during auto mode.

**Key detail:** The design-thinking command already exists as a standalone command at `.claude/commands/gsd/design-thinking.md`. The injection should NOT duplicate the command content. Instead, it should reference the command's workflow inline (using `@` reference) or invoke the command's process steps by loading the file. The simplest approach: reference the design-thinking command file so Claude reads it and executes the design thinking interview flow in-context.

#### 2. discuss-phase.md -- UI Detection + Agent Orchestration Injection

**Injection point:** After the `write_context` step, before `confirm_creation` and `git_commit`.

**Rationale:** At this point, CONTEXT.md has been written (user decisions captured). UI detection needs CONTEXT.md to scan for keywords. The orchestrator needs CONTEXT.md as input for design agents. Running after CONTEXT.md write but before git commit means {phase}-UI.md can be committed in the same commit or immediately after.

**What to inject:**
- A new step (e.g., "design_detection" step) between `write_context` and `confirm_creation`:
  1. Guard clause: Check if `.planning/DESIGN.md` exists. If not, skip entirely.
  2. Run UI detection logic (inline-reference `workflows/design/ui-detection.md`):
     - Get phase section from ROADMAP.md
     - Concatenate with CONTEXT.md text
     - Run detection algorithm (markers > negative > positive threshold)
  3. If IS_UI=false: Log "Non-UI phase -- skipping design agents" and continue to confirm_creation
  4. If IS_UI=true:
     - Check DESIGN.md exists (should already be verified in guard, but double-check)
     - If DESIGN.md missing: prompt user "UI phase detected but no DESIGN.md found. Run /gsd:design-thinking first, or continue without design guidance?"
     - Call orchestrate-design workflow (inline-reference `workflows/design/orchestrate-design.md`):
       - Pass PHASE_NUMBER, PHASE_NAME, PHASE_GOAL, PHASE_DIR, CONTEXT_PATH, REFRESH_STACK
       - Stack gate runs (STACK.md created if needed)
       - 3 design agents spawn in parallel
       - Output synthesized into {phase}-UI.md
     - Log result: agents completed, agents failed, conflicts resolved, output file path
  5. Continue to confirm_creation (which now also mentions {phase}-UI.md if created)

**Key detail:** The discuss-phase.md workflow file uses `<step>` XML tags for its process flow. The injected section should be a new `<step name="design_detection">` that fits into the existing step sequence. The `auto_advance` step already chains to plan-phase; the design detection step must run BEFORE auto_advance since plan-phase needs {phase}-UI.md to exist.

**Correct step order after patching:**
1. initialize
2. check_existing
3. load_prior_context
4. scout_codebase
5. analyze_phase
6. present_gray_areas
7. discuss_areas
8. write_context
9. **design_detection** (NEW -- injected)
10. confirm_creation (updated to mention {phase}-UI.md if created)
11. git_commit (updated to also commit {phase}-UI.md if created)
12. update_state
13. auto_advance

#### 3. plan-phase.md -- Design Context Loading Injection

**Injection point:** Two locations:

**Location A -- Step 7 (context path loading):** Add DESIGN.md and {phase}-UI.md to the files the planner receives.

**Location B -- Step 8 (planner prompt `<files_to_read>`):** Add DESIGN.md and {phase}-UI.md paths to the files_to_read block in the planner spawn prompt.

**What to inject at Location A:**
```markdown
<!-- GSD-DESIGN-START -->
## Design Context (optional)

Check for design artifacts:
```bash
DESIGN_PATH=$(test -f .planning/DESIGN.md && echo ".planning/DESIGN.md" || echo "")
UI_PATH=$(ls "${PHASE_DIR}"/*-UI.md 2>/dev/null | head -1)
```

These paths are optional -- if files don't exist, simply omit them from the planner prompt.
<!-- GSD-DESIGN-END -->
```

**What to inject at Location B (inside planner prompt):**
```markdown
<!-- GSD-DESIGN-START -->
- {DESIGN_PATH} (Design brief -- if exists, optional)
- {UI_PATH} (UI design guidance for this phase -- if exists, optional)
<!-- GSD-DESIGN-END -->
```

**Graceful behavior:** If DESIGN.md or {phase}-UI.md don't exist, the paths are simply empty/omitted from files_to_read. The planner never errors on missing design files -- it just doesn't have design context. This is the R4.5 guarantee: non-UI phases produce zero design artifacts and the planner doesn't look for them.

### File Modification Strategy

**Critical decision:** Where do the patched files live?

The GSD commands at `~/.claude/commands/gsd/*.md` are thin shims that `@import` workflow files from `~/.claude/get-shit-done/workflows/`. The actual patching targets depend on which file contains the logic:

| Command | Shim Location | Logic Location | Patch Target |
|---------|---------------|----------------|--------------|
| new-project | `commands/gsd/new-project.md` | `workflows/new-project.md` | **Workflow file** (logic lives here) |
| discuss-phase | `commands/gsd/discuss-phase.md` | `workflows/discuss-phase.md` | **Workflow file** (logic lives here) |
| plan-phase | `commands/gsd/plan-phase.md` | `workflows/plan-phase.md` | **Workflow file** (logic lives here) |

The patched workflow files are stored in the project repo and the installer (Phase 6) overlays them. The command shims may also need minor updates to reference design workflow files in `execution_context`.

### Anti-Patterns to Avoid

- **Duplicating design-thinking command content in new-project:** Reference the command file, don't copy-paste 300+ lines of interview flow into new-project.md.
- **Patching the command shim instead of the workflow:** The command shim is just metadata + an `@import`. The real logic is in the workflow file.
- **Making design artifacts required:** Every design file read must be optional/graceful. Missing DESIGN.md = skip. Missing {phase}-UI.md = skip. Missing STACK.md = skip.
- **Running design detection before CONTEXT.md exists:** The detection algorithm scans CONTEXT.md text. It must run AFTER write_context, not before.
- **Breaking auto mode:** Auto mode (`--auto` flag) in new-project and discuss-phase has specific non-interactive behavior. Design additions must respect this -- either skip design thinking in auto mode or make it non-interactive.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UI detection logic | Custom keyword matching in discuss-phase | Reference `workflows/design/ui-detection.md` | Phase 3 already built the complete detection algorithm |
| Agent orchestration | Custom Task() spawning in discuss-phase | Reference `workflows/design/orchestrate-design.md` | Phase 3 already built the complete orchestration flow |
| Design interview | Inline design questions in new-project | Reference `commands/gsd/design-thinking.md` | Phase 1 already built the complete interview |
| DESIGN.md schema | New schema definition | Existing schema with `schema_version: 1` | Phase 1 defined the schema |

**Key insight:** Phase 4 is pure wiring. All the design logic already exists in files created by Phases 1-3. This phase connects existing pieces to existing GSD commands, nothing more.

## Common Pitfalls

### Pitfall 1: Incorrect Injection Point in new-project.md
**What goes wrong:** Injecting design thinking too early (before PROJECT.md exists) or too late (after research, when DESIGN.md can't inform it).
**Why it happens:** The new-project workflow has 9 steps with complex branching (auto mode, brownfield, etc.).
**How to avoid:** Inject between Step 4 (PROJECT.md written and committed) and Step 5 (Workflow Preferences). At this point PROJECT.md exists for the design-thinking interview to consume, and research hasn't started yet.
**Warning signs:** Design-thinking command tries to load PROJECT.md but it doesn't exist yet, or DESIGN.md is created but research doesn't account for it.

### Pitfall 2: Breaking Auto Mode
**What goes wrong:** Design thinking injection adds an interactive prompt in auto mode, blocking the non-interactive flow.
**Why it happens:** Auto mode is designed to run without user interaction after initial config.
**How to avoid:** In auto mode, either skip design thinking entirely (default) or support a `--design` flag that enables it with auto-approved defaults. The simplest approach: skip design thinking in auto mode since design is an interactive creative process.
**Warning signs:** Auto mode hangs waiting for user input at the design thinking step.

### Pitfall 3: Design Detection Running Before CONTEXT.md
**What goes wrong:** UI detection returns false because it can't scan CONTEXT.md (doesn't exist yet).
**Why it happens:** Inserting the design detection step too early in the discuss-phase flow.
**How to avoid:** Insert AFTER write_context step, BEFORE confirm_creation.
**Warning signs:** Phases that should be detected as UI are not, because keyword matches in CONTEXT.md are missed.

### Pitfall 4: Forgetting the Guard Clause
**What goes wrong:** Users without DESIGN.md see errors or unexpected behavior from design-related code.
**Why it happens:** Injected code assumes DESIGN.md always exists.
**How to avoid:** Every injection block starts with `if DESIGN.md exists` check. Failing the check = skip entirely, zero side effects.
**Warning signs:** Error messages about missing DESIGN.md in projects that never ran design-thinking.

### Pitfall 5: Not Updating the Command Shim execution_context
**What goes wrong:** The workflow file references design workflow files, but Claude can't access them because the command shim's `execution_context` doesn't include them.
**Why it happens:** Only the workflow file is patched, but the command shim controls which files Claude loads.
**How to avoid:** Update the command shim's `<execution_context>` section to include `@workflows/design/ui-detection.md` and `@workflows/design/orchestrate-design.md` for discuss-phase, and the design-thinking command reference for new-project.
**Warning signs:** Claude says it can't find the workflow files or doesn't know about design detection.

### Pitfall 6: {phase}-UI.md Not Committed Before Plan Phase
**What goes wrong:** plan-phase runs but can't find {phase}-UI.md because discuss-phase didn't commit it.
**Why it happens:** The discuss-phase git_commit step only commits CONTEXT.md by default.
**How to avoid:** Update git_commit step to also commit {phase}-UI.md if it was created.

## Code Examples

### Example 1: new-project.md Injection Block

```markdown
<!-- GSD-DESIGN-START -->
## 4.5. Design Thinking (optional)

**If auto mode:** Skip design thinking. Log: "Design thinking skipped in auto mode."
Proceed to Step 5.

**If interactive mode:**

Check if `.planning/DESIGN.md` already exists.
- If yes: Log "DESIGN.md exists -- skipping design thinking offer." Proceed to Step 5.
- If no: Offer design thinking.

Use AskUserQuestion:
- header: "Design"
- question: "Would you like to run design thinking? This creates a design brief (DESIGN.md) that informs UI decisions later."
- options:
  - "Yes -- run design thinking"
  - "Skip -- use vanilla GSD"

**If "Skip":** Log "Design thinking skipped." Proceed to Step 5.

**If "Yes":**
Read and execute the design thinking interview from the design-thinking command:

@{path-to}/commands/gsd/design-thinking.md

Execute Steps 2-7 of the design-thinking process (skip Step 0 re-run check and Step 1 skip offer -- user just opted in).

After DESIGN.md is written and approved, proceed to Step 5.
<!-- GSD-DESIGN-END -->
```

### Example 2: discuss-phase.md Injection Block

```markdown
<!-- GSD-DESIGN-START -->
<step name="design_detection">
## Design Detection & Agent Orchestration

**Guard clause:** Check if `.planning/DESIGN.md` exists.
- If DESIGN.md does NOT exist: Skip this step entirely. Continue to confirm_creation.
  Log: "No DESIGN.md found -- skipping design detection."

**Run UI detection:**
Execute the detection logic from workflows/design/ui-detection.md:

1. Get phase section: `node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" roadmap get-phase "${PHASE}"`
2. Read CONTEXT.md text from `${phase_dir}/${padded_phase}-CONTEXT.md`
3. Apply detection algorithm (markers > negative suppression > keyword threshold)
4. Capture result: IS_UI, DETECTION_METHOD, MATCHED_CATEGORIES, REFRESH_STACK

**If IS_UI=false:**
Log: "Phase ${PHASE} is not a UI phase (${DETECTION_METHOD}). Skipping design agents."
Continue to confirm_creation.

**If IS_UI=true:**
Log: "UI phase detected (${DETECTION_METHOD}). Spawning design agents..."

Execute the orchestration logic from workflows/design/orchestrate-design.md:
- Pass: PHASE_NUMBER, PHASE_NAME, PHASE_GOAL, PHASE_DIR, CONTEXT_PATH, REFRESH_STACK
- Stack gate runs (creates STACK.md if needed)
- 3 design agents spawn in parallel
- Output synthesized into {phase}-UI.md

Log result: "Design guidance written to ${phase_dir}/${padded_phase}-UI.md"
Set DESIGN_UI_CREATED=true for use in confirm_creation and git_commit.

Continue to confirm_creation.
</step>
<!-- GSD-DESIGN-END -->
```

### Example 3: plan-phase.md Injection Block (in planner prompt)

```markdown
<!-- GSD-DESIGN-START -->
## Design Context Loading

Check for design artifacts (optional -- graceful if missing):

DESIGN_PATH: `.planning/DESIGN.md` (if exists)
UI_PATH: `${PHASE_DIR}/*-UI.md` (if exists)

Add to planner prompt <files_to_read> block:
- {DESIGN_PATH} (Design brief -- brand direction, emotional core, visual identity. Optional.)
- {UI_PATH} (Phase-specific design guidance from UI/UX/motion agents. Optional.)

These files are informational context only. The planner should:
- Reference design constraints when creating UI-related tasks
- Ignore these files entirely for non-UI phases (they won't exist)
- Never fail or warn if these files are missing
<!-- GSD-DESIGN-END -->
```

## State of the Art

| Aspect | Current State | Impact on Phase 4 |
|--------|---------------|-------------------|
| GSD command structure | Thin command shim + workflow file pattern | Patch workflow files, possibly update shim execution_context |
| GSD uses `@` references | `@/path/to/file` loads file content into context | Can reference design workflow files this way |
| GSD uses `<step>` tags | discuss-phase uses named steps in XML | Injected step must follow this convention |
| GSD Task() pattern | `Task(run_in_background=true, ...)` for parallel agents | Orchestrator already uses this pattern (Phase 3) |
| GSD init tool | `gsd-tools.cjs init phase-op` returns JSON context | No changes needed -- existing init provides all needed paths |

## Open Questions

1. **Command shim vs workflow file patching**
   - What we know: Commands are shims that `@import` workflow files. Logic lives in workflow files.
   - What's unclear: Should we patch ONLY the workflow files, or also add `@` references in the command shims? The command shim's `execution_context` determines what Claude loads into context.
   - Recommendation: Patch workflow files for logic injection. Add `@` references to command shims only if needed for Claude to access design workflow files. Test whether Claude can resolve `@` references from within workflow files (it likely can, since the workflow is already loaded into Claude's context).

2. **Auto mode design thinking behavior**
   - What we know: Auto mode is non-interactive. Design thinking is inherently interactive.
   - What's unclear: Should auto mode always skip, or should there be a `--design` flag?
   - Recommendation: Skip by default in auto mode. Document that users can run `/gsd:design-thinking` separately before `/gsd:new-project --auto` if they want design context.

3. **Reference vs inline for design-thinking in new-project**
   - What we know: The design-thinking command is 336 lines. Duplicating it in new-project would be wasteful.
   - What's unclear: Whether `@` referencing a command file from within a workflow works as expected in Claude Code.
   - Recommendation: Use `@` reference to the design-thinking command file. If that doesn't work, inline only the process steps (Steps 2-7) as a condensed version.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual verification (prompt-based system, no automated test framework) |
| Config file | N/A |
| Quick run command | `grep -c "GSD-DESIGN-START" <patched-file>` to verify marker injection |
| Full suite command | Manual walkthrough of each patched command |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| R1.3 | Design thinking offered in new-project after questioning | manual-only | `grep "GSD-DESIGN-START" .claude/commands/gsd/new-project.md` + `grep "design-thinking" workflows/new-project.md` | Wave 0 |
| R4.1 | new-project marker injection | smoke | `grep -c "GSD-DESIGN-START" workflows/new-project.md` returns 1+ | Wave 0 |
| R4.2 | discuss-phase UI detection + orchestration | smoke | `grep "GSD-DESIGN-START" workflows/discuss-phase.md` + `grep "ui-detection" workflows/discuss-phase.md` + `grep "orchestrate-design" workflows/discuss-phase.md` | Wave 0 |
| R4.3 | plan-phase loads DESIGN.md + UI.md | smoke | `grep "GSD-DESIGN-START" workflows/plan-phase.md` + `grep "DESIGN.md" workflows/plan-phase.md` + `grep "UI.md" workflows/plan-phase.md` | Wave 0 |
| R4.4 | Guard clause on all paths | smoke | `grep -A2 "GSD-DESIGN-START" workflows/*.md` shows DESIGN.md check in each block | Wave 0 |
| R4.5 | Non-UI phases produce zero artifacts | manual-only | Run discuss-phase on a non-UI phase, verify no {phase}-UI.md created | N/A |

### Sampling Rate
- **Per task commit:** `grep -c "GSD-DESIGN-START" <file>` to verify markers present
- **Per wave merge:** Check all three patched files have markers and correct guard clauses
- **Phase gate:** Manual walkthrough: new-project with skip, new-project with design, discuss-phase on UI phase, discuss-phase on non-UI phase, plan-phase with and without DESIGN.md

### Wave 0 Gaps
- [ ] Patched `workflows/new-project.md` (or equivalent) with design thinking injection
- [ ] Patched `workflows/discuss-phase.md` (or equivalent) with UI detection injection
- [ ] Patched `workflows/plan-phase.md` (or equivalent) with design context loading

## Sources

### Primary (HIGH confidence)
- `~/.claude/commands/gsd/new-project.md` -- command shim structure (read directly)
- `~/.claude/commands/gsd/discuss-phase.md` -- command shim structure (read directly)
- `~/.claude/commands/gsd/plan-phase.md` -- command shim structure (read directly)
- `~/.claude/get-shit-done/workflows/new-project.md` -- full workflow logic (read directly, 1087 lines)
- `~/.claude/get-shit-done/workflows/discuss-phase.md` -- full workflow logic (read directly, 677 lines)
- `~/.claude/get-shit-done/workflows/plan-phase.md` -- full workflow logic (read directly, 561 lines)
- `.claude/commands/gsd/design-thinking.md` -- design thinking command (read directly, 337 lines)
- `workflows/design/ui-detection.md` -- UI detection logic (read directly, 138 lines)
- `workflows/design/orchestrate-design.md` -- agent orchestration (read directly, 196 lines)
- `.planning/PROJECT.md` -- project decisions and constraints (read directly)

### Secondary (MEDIUM confidence)
- Phase 3 plans (03-01-PLAN.md, 03-02-PLAN.md) -- verified integration points described
- Phase 3 CONTEXT.md -- locked decisions about detection and orchestration

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all files read directly, injection points identified precisely
- Architecture: HIGH -- marker injection pattern is simple and well-defined; all three workflow files analyzed line-by-line
- Pitfalls: HIGH -- derived from direct analysis of workflow branching logic (auto mode, step ordering, guard clauses)

**Research date:** 2026-03-05
**Valid until:** 2026-04-05 (stable -- GSD workflow structure unlikely to change)
