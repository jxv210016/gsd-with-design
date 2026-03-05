# Architecture Patterns

**Domain:** Design-thinking integration layer for multi-agent CLI workflow system (GSD)
**Researched:** 2026-03-05
**Confidence:** MEDIUM (based on PROJECT.md specifications and GSD's documented patterns; web/source verification was unavailable)

## System Context

GSD is a meta-prompting and context engineering system for Claude Code. It uses:
- **Slash commands** in `.claude/commands/gsd/` that users invoke (e.g., `/gsd:new-project`)
- **Agent prompts** in `.claude/agents/` that orchestrators spawn via the Task tool
- **Parallel wave spawning** where multiple agents run concurrently, then an orchestrator synthesizes results
- **File-based communication** where agents read context files from `.planning/` and write output files back

The design integration must operate within this existing architecture without modifying its core patterns.

## Recommended Architecture

### High-Level Flow

```
User invokes /gsd:new-project
       |
       v
[Existing GSD questioning phase]
       |
       v
[NEW: Design Thinking Phase] --> writes .planning/DESIGN.md
       |
       v
[Existing GSD research phase] (agents now also load DESIGN.md)
       |
       v
[Existing GSD roadmap phase]
       |
       v
User invokes /gsd:discuss-phase (or plan-phase)
       |
       v
[UI Detection Gate] -- not UI --> vanilla GSD behavior (no change)
       |                |
       |                v
       |         [Parallel Design Agent Wave]
       |         ui-design + ux-design + motion-design
       |                |
       |                v
       |         [Orchestrator synthesizes {phase}-UI.md]
       |                |
       v                v
[Phase proceeds with {phase}-UI.md as additional context]
```

### Component Boundaries

| Component | Location | Responsibility | Reads | Writes |
|-----------|----------|---------------|-------|--------|
| `design-thinking.md` | `commands/gsd/design-thinking.md` | Standalone command + embedded phase in new-project. Runs design thinking interview (Problem Space, Emotional Core, Solution Space, Brand Identity) | PROJECT.md (if exists) | `.planning/DESIGN.md` |
| `design-ui.md` | `commands/gsd/design-ui.md` | Quick reference command. Dumps UI/UX/motion craft standards for user reference | Nothing (self-contained) | stdout only |
| `design-stack.md` | `commands/gsd/design-stack.md` | Quick reference command. Dumps adaptive stack + git conventions | Nothing (self-contained) | stdout only |
| `stack-conventions.md` | `agents/design/stack-conventions.md` | Agent prompt. Generic/adaptive stack conventions. Spawned once at project init, not per-phase | `.planning/DESIGN.md`, `.planning/PROJECT.md` | Contributes to design-thinking output |
| `ui-design.md` | `agents/design/ui-design.md` | Agent prompt. 8pt grid, 60-30-10 color, typography, component states | `.planning/DESIGN.md`, phase CONTEXT.md | UI design recommendations (to orchestrator) |
| `ux-design.md` | `agents/design/ux-design.md` | Agent prompt. Hick's Law, Peak-end rule, decision architecture, honest design | `.planning/DESIGN.md`, phase CONTEXT.md | UX design recommendations (to orchestrator) |
| `motion-design.md` | `agents/design/motion-design.md` | Agent prompt. Animation principles, Framer Motion recipes, reduced motion | `.planning/DESIGN.md`, phase CONTEXT.md | Motion design recommendations (to orchestrator) |
| UI Detection Gate | Inline in orchestrator (discuss-phase/plan-phase) | Determines if a phase involves UI work based on keyword/intent analysis | Phase description from roadmap | Boolean decision |
| Design Synthesis | Inline in orchestrator (discuss-phase/plan-phase) | Merges three design agent outputs into single cohesive file | Three agent outputs | `.planning/{phase}-UI.md` |

## Agent Lifecycle Patterns

### Init-Once Agent: `stack-conventions.md`

This agent runs **once during project initialization** (design-thinking phase), not per-phase. It discovers the project's technology stack from the user's design-thinking answers and establishes conventions.

**Rationale:** Stack conventions are project-wide, not phase-specific. Running this per-phase would produce redundant, potentially contradictory output. The design-thinking interview naturally surfaces stack preferences ("What technologies are you using?"), making init the right moment.

**Lifecycle:**
```
/gsd:new-project
  --> design-thinking phase begins
  --> user answers questions (including stack-relevant ones)
  --> stack-conventions agent spawned ONCE
  --> output folded into DESIGN.md (stack section)
  --> never spawned again unless user runs /gsd:design-thinking explicitly
```

### Per-Phase Agents: `ui-design.md`, `ux-design.md`, `motion-design.md`

These three agents run **every time a UI phase is discussed or planned**. They are spawned as a parallel wave (all three concurrently via Task tool), then their outputs are synthesized.

**Rationale:** Each phase has different UI requirements. A login screen needs different design guidance than a dashboard. Phase-specific context (CONTEXT.md, feature list) must inform the design recommendations.

**Lifecycle:**
```
/gsd:discuss-phase (or plan-phase)
  --> orchestrator loads phase description
  --> UI Detection Gate evaluates phase
  --> IF UI phase:
       --> spawn ui-design agent (Task tool)
       --> spawn ux-design agent (Task tool)  [parallel]
       --> spawn motion-design agent (Task tool)
       --> wait for all three
       --> synthesize into {phase}-UI.md
  --> IF NOT UI phase:
       --> proceed with vanilla GSD behavior (zero design artifacts)
```

## Parallel Agent Orchestration

### Wave Pattern (Matching GSD Research Agents)

GSD's research phase already demonstrates the pattern: 4 parallel researcher agents are spawned via Task tool, each writes to a file, then a synthesizer agent reads all outputs and produces a unified result.

Design agents follow the identical pattern:

```
Orchestrator (discuss-phase or plan-phase command)
  |
  |-- Task: ui-design agent
  |     Input: DESIGN.md + phase context
  |     Output: structured UI recommendations (returned to orchestrator)
  |
  |-- Task: ux-design agent      [PARALLEL - all three spawned together]
  |     Input: DESIGN.md + phase context
  |     Output: structured UX recommendations (returned to orchestrator)
  |
  |-- Task: motion-design agent
  |     Input: DESIGN.md + phase context
  |     Output: structured motion recommendations (returned to orchestrator)
  |
  v
Orchestrator receives all three outputs
  |
  v
Orchestrator synthesizes --> writes {phase}-UI.md
```

**Key difference from research agents:** Research agents each write their own files, then a separate synthesizer agent reads them. Design agents should return their output directly to the spawning orchestrator, which performs synthesis inline. This avoids an extra agent spawn and keeps the design layer lightweight.

**Rationale for inline synthesis over separate synthesizer:**
- Research has 4 agents producing large, independent research documents -- a synthesizer agent is justified
- Design has 3 agents producing complementary recommendations about the same UI surface -- the orchestrator can merge them in a single pass
- Fewer agent spawns = faster execution, lower token cost

### Agent Input Contract

Each design agent receives the same context bundle:

```markdown
## Context for Design Agent

### Brand Direction (from DESIGN.md)
{contents of .planning/DESIGN.md}

### Phase Context
Phase: {phase name}
Description: {phase description from roadmap}
Features: {feature list for this phase}

### Existing Design Decisions
{contents of any prior {phase}-UI.md files, if iterating}
```

### Agent Output Contract

Each agent returns structured markdown (not a file write):

```markdown
## [Agent Name] Recommendations for {Phase}

### Component Specifications
[agent-specific recommendations]

### Constraints
[things to avoid]

### Implementation Notes
[practical guidance for developers]
```

## Output Synthesis Pattern

### {phase}-UI.md Structure

The orchestrator merges three agent outputs into a unified file:

```markdown
# {Phase Name} - UI Design Specifications

**Generated:** {date}
**Source:** DESIGN.md (Brand: {brand name/concept})

## Visual Design
[from ui-design agent: grid, color, typography, component states]

## User Experience
[from ux-design agent: information architecture, interaction patterns, accessibility]

## Motion & Animation
[from motion-design agent: transitions, micro-interactions, reduced motion fallbacks]

## Cross-Cutting Concerns
[orchestrator-synthesized: where agents' recommendations interact or conflict]

## Implementation Checklist
[consolidated actionable items from all three agents]
```

### Conflict Resolution

When agents produce contradictory recommendations (e.g., ui-design wants flashy animation, ux-design wants simplicity):
1. UX wins over visual preference (usability > aesthetics)
2. Accessibility wins over motion (reduced-motion > animation)
3. Brand identity (from DESIGN.md) is the tiebreaker for aesthetic conflicts

This hierarchy should be documented in the orchestrator's synthesis prompt.

## Data Flow: DESIGN.md Through the System

### DESIGN.md as Central Design Context

```
                    .planning/DESIGN.md
                    (written once at project init)
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
    ui-design agent  ux-design agent  motion-design agent
          |                |                |
          v                v                v
    UI recs            UX recs         Motion recs
          |                |                |
          +--------+-------+
                   |
                   v
          .planning/{phase}-UI.md
          (written per UI phase)
                   |
                   v
          plan-phase orchestrator
          loads {phase}-UI.md as context
          alongside CONTEXT.md
                   |
                   v
          Implementation agent
          (existing GSD build phase)
          has full design context
```

### File Flow Detail

| Step | Trigger | Input Files | Output File | Location |
|------|---------|-------------|-------------|----------|
| 1. Design Thinking | `/gsd:new-project` or `/gsd:design-thinking` | PROJECT.md (optional) | `DESIGN.md` | `.planning/DESIGN.md` |
| 2. Research | `/gsd:new-project` (continues) | PROJECT.md + DESIGN.md | research files | `.planning/research/` |
| 3. Roadmap | `/gsd:new-project` (continues) | research + DESIGN.md | ROADMAP.md | `.planning/ROADMAP.md` |
| 4. Phase Discussion | `/gsd:discuss-phase` | DESIGN.md + ROADMAP.md + CONTEXT.md | `{phase}-UI.md` | `.planning/{phase}-UI.md` |
| 5. Phase Planning | `/gsd:plan-phase` | DESIGN.md + `{phase}-UI.md` + CONTEXT.md | Phase plan | `.planning/phases/{phase}/` |
| 6. Implementation | `/gsd:build` (unchanged) | Phase plan + `{phase}-UI.md` | Source code | Project source |

## UI Phase Auto-Detection

### Detection Keywords

The orchestrator checks the phase name/description against these categories:

| Category | Trigger Keywords |
|----------|-----------------|
| Components | component, button, card, modal, dialog, form, input, dropdown, select, table, list, menu, sidebar, navbar, header, footer, widget |
| Layouts | layout, page, screen, view, dashboard, grid, responsive, breakpoint |
| Interactions | click, hover, drag, swipe, scroll, gesture, touch, interactive, animation, transition |
| Visual | style, theme, color, typography, icon, image, avatar, badge, toast, notification |
| Navigation | route, navigation, breadcrumb, tab, link, redirect, wizard, stepper |
| States | loading, error, empty state, skeleton, placeholder, disabled, active, selected |

### Detection Logic

```
is_ui_phase(phase):
  keywords = extract_keywords(phase.name + phase.description + phase.features)
  ui_matches = keywords INTERSECT ui_trigger_keywords
  return len(ui_matches) >= 2  // require at least 2 UI signals to avoid false positives
```

**Threshold rationale:** A single keyword like "form" might appear in a backend validation phase. Requiring 2+ UI signals reduces false positives while catching genuine UI work.

### Override Mechanism

Phase descriptions in ROADMAP.md can include explicit markers:
- `<!-- ui-phase -->` forces design agent spawning
- `<!-- no-ui -->` suppresses design agent spawning

This handles edge cases where auto-detection fails.

## Modifying Existing Workflows (Insertion Points)

### Superset Guarantee

The fundamental constraint: any user who never invokes design commands must experience identical GSD behavior. This means modifications to existing commands must be **additive guards**, not behavioral changes.

### `/gsd:new-project` Modifications

**Insertion point:** After the questioning/interview phase, before research phase.

```
EXISTING: questions --> research --> roadmap
MODIFIED: questions --> [DESIGN THINKING PHASE] --> research --> roadmap
                              |
                              v
                        writes DESIGN.md
```

**Implementation approach:**
The new-project command prompt gets an additional section appended (not replacing existing content):

```markdown
## Design Thinking Phase (GSD-with-Design Extension)

After completing the project questioning phase and before spawning research agents:

1. Run design thinking interview (Problem Space, Emotional Core, Solution Space, Brand Identity)
2. Spawn stack-conventions agent once to establish adaptive stack conventions
3. Write results to .planning/DESIGN.md
4. Continue with research phase (research agents now also load DESIGN.md)
```

**Superset safety:** This section is always present in the fork's command file, but it only adds a step. If someone were to remove the design layer, the command still works -- the research phase doesn't *require* DESIGN.md, it just *loads it if present*.

### `/gsd:discuss-phase` Modifications

**Insertion point:** After phase context is loaded, before discussion begins.

```
EXISTING: load phase context --> discuss with user
MODIFIED: load phase context --> [UI DETECTION] --> [SPAWN DESIGN AGENTS IF UI] --> discuss with user
                                                           |
                                                           v
                                                    writes {phase}-UI.md
```

**Implementation approach:**
Append to discuss-phase command prompt:

```markdown
## Design Agent Integration (GSD-with-Design Extension)

After loading phase context, before beginning discussion:

1. Check if phase involves UI work (auto-detection or explicit marker)
2. If UI phase:
   a. Check if .planning/DESIGN.md exists (skip design agents if not -- vanilla GSD project)
   b. Spawn ui-design, ux-design, motion-design agents in parallel
   c. Synthesize outputs into .planning/{phase}-UI.md
   d. Include {phase}-UI.md content in discussion context
3. If not UI phase: proceed without design artifacts
```

**Superset safety:** Step 2a is the critical guard. If DESIGN.md doesn't exist (vanilla GSD project), design agents never spawn. Zero behavioral change.

### `/gsd:plan-phase` Modifications

**Insertion point:** When loading context files for planning.

```
EXISTING: load CONTEXT.md + ROADMAP.md --> plan
MODIFIED: load CONTEXT.md + ROADMAP.md + [{phase}-UI.md if exists] --> plan
```

**Implementation approach:**
Add to file-loading section of plan-phase:

```markdown
## Design Context Loading (GSD-with-Design Extension)

When loading phase context files, also check for and load:
- .planning/DESIGN.md (project-level design direction)
- .planning/{phase}-UI.md (phase-specific UI specifications, if generated by discuss-phase)

These files are optional. If they don't exist, planning proceeds identically to vanilla GSD.
```

**Superset safety:** "If they don't exist" guard means vanilla GSD projects are unaffected.

### `/gsd:update` Modifications

**Insertion point:** File preservation list.

```
EXISTING: preserves user customizations during update
MODIFIED: also preserves commands/gsd/design-* and agents/design/*
```

**Implementation approach:**
Add design file paths to the update command's preservation list. This is the simplest modification -- just additional entries in an existing pattern.

## File Layout

```
.claude/
  commands/
    gsd/
      new-project.md        # MODIFIED: design thinking phase added
      discuss-phase.md       # MODIFIED: UI detection + design agents added
      plan-phase.md          # MODIFIED: loads {phase}-UI.md
      update.md              # MODIFIED: preserves design files
      design-thinking.md     # NEW: standalone design thinking command
      design-ui.md           # NEW: quick reference for UI/UX/motion standards
      design-stack.md        # NEW: quick reference for stack conventions
  agents/
    design/
      stack-conventions.md   # NEW: init-once agent
      ui-design.md           # NEW: per-phase parallel agent
      ux-design.md           # NEW: per-phase parallel agent
      motion-design.md       # NEW: per-phase parallel agent

.planning/
  PROJECT.md                 # Existing GSD artifact
  DESIGN.md                  # NEW: design thinking output
  ROADMAP.md                 # Existing GSD artifact
  {phase}-UI.md              # NEW: per-phase design specifications
  research/                  # Existing GSD directory
  phases/                    # Existing GSD directory
```

## Patterns to Follow

### Pattern 1: Guard-Based Extension

**What:** Every modification to existing GSD commands uses a file-existence guard before activating design behavior.
**When:** Always, for every integration point.
**Why:** This is the mechanism that maintains the superset guarantee.

```markdown
# In a modified GSD command prompt:

## Design Extension
If .planning/DESIGN.md exists:
  [do design-specific work]
Otherwise:
  [skip silently -- vanilla GSD behavior]
```

### Pattern 2: Parallel Wave with Inline Synthesis

**What:** Spawn multiple agents via Task tool concurrently. Orchestrator collects results and synthesizes inline rather than spawning a separate synthesizer.
**When:** Design agent spawning during discuss-phase/plan-phase.

```
# Pseudocode in orchestrator prompt:
1. Spawn Task(ui-design agent, context bundle)
2. Spawn Task(ux-design agent, context bundle)    [parallel]
3. Spawn Task(motion-design agent, context bundle)
4. Collect all three results
5. Merge into {phase}-UI.md with conflict resolution hierarchy
```

### Pattern 3: Context Cascading

**What:** Each phase inherits context from previous phases. DESIGN.md flows forward through all phases.
**When:** Every phase after design thinking.

```
Phase 1: DESIGN.md --> phase-1-UI.md
Phase 2: DESIGN.md + (awareness of phase-1-UI.md patterns) --> phase-2-UI.md
Phase 3: DESIGN.md + (awareness of prior phases) --> phase-3-UI.md
```

This ensures design consistency across phases. Later phases should reference established patterns (e.g., "use the same button style as phase 1") rather than reinventing.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Monolithic Design Agent

**What:** Combining UI, UX, and motion into a single agent prompt.
**Why bad:** Violates GSD's parallel agent architecture. A single agent produces less thorough output because it must context-switch between disciplines. Parallel execution is also faster.
**Instead:** Keep three specialized agents, each with deep expertise in its domain.

### Anti-Pattern 2: Design Agents Writing Files Directly

**What:** Having each design agent write its own output file.
**Why bad:** Creates coordination problems. Three agents writing to the same directory risk partial outputs, inconsistent formatting, and no conflict resolution. The orchestrator loses visibility into what was produced.
**Instead:** Agents return structured markdown to the orchestrator. Orchestrator writes the single synthesized `{phase}-UI.md`.

### Anti-Pattern 3: Hardcoded Stack in Agents

**What:** Baking Next.js/Tailwind/Framer Motion assumptions into agent prompts.
**Why bad:** The fork should work for any tech stack. A React Native project needs different motion guidance than a web app.
**Instead:** stack-conventions agent discovers the stack at init. Design agents reference DESIGN.md's stack section for technology-appropriate recommendations.

### Anti-Pattern 4: Conditional Command Replacement

**What:** Creating separate `new-project-with-design.md` that replaces `new-project.md`.
**Why bad:** Breaks the superset guarantee. Users must use a different command. Updates to upstream GSD's new-project.md won't be reflected.
**Instead:** Modify the existing command file with additive guard sections. When GSD updates, the base command content can be updated and the design extensions re-appended.

### Anti-Pattern 5: Running Design Agents for Non-UI Phases

**What:** Always spawning design agents regardless of phase content.
**Why bad:** Wastes tokens and time. Produces irrelevant output for backend/infrastructure phases. Adds noise to phase context.
**Instead:** UI detection gate with 2+ keyword threshold. Non-UI phases produce zero design artifacts.

## Suggested Build Order

Dependencies dictate this order:

```
Phase 1: DESIGN.md + Design Thinking Command
  - design-thinking.md command (standalone)
  - DESIGN.md schema/structure definition
  - No dependencies on other components
  - Can be tested independently

Phase 2: Agent Prompts
  - stack-conventions.md agent
  - ui-design.md agent
  - ux-design.md agent
  - motion-design.md agent
  - Depends on: DESIGN.md structure (Phase 1)
  - Can be tested by manually spawning agents

Phase 3: Workflow Integration
  - Modify new-project.md (insert design thinking phase)
  - UI detection logic
  - Parallel agent spawning in discuss-phase.md
  - {phase}-UI.md synthesis
  - Modify plan-phase.md (load design context)
  - Depends on: all agents exist (Phase 2), DESIGN.md exists (Phase 1)

Phase 4: Auxiliary Commands + Update Safety
  - design-ui.md quick reference command
  - design-stack.md quick reference command
  - Modify update.md (preserve design files)
  - Install scripts
  - Depends on: core workflow works (Phase 3)
```

**Rationale:** Phase 1 is the foundation -- nothing works without DESIGN.md. Phase 2 creates the tools. Phase 3 wires them into GSD's existing flow. Phase 4 is polish and distribution.

## Scalability Considerations

| Concern | Current Scope | At Scale |
|---------|--------------|----------|
| Agent token cost | 3 agents per UI phase | Consider caching {phase}-UI.md so re-runs only regenerate if DESIGN.md or phase context changed |
| Detection accuracy | Keyword matching | Could evolve to LLM-based classification if false positive/negative rate is too high |
| Cross-phase consistency | Context cascading (each phase sees DESIGN.md) | Could add a design-system.md that accumulates component decisions across phases |
| Multiple design iterations | Re-run discuss-phase overwrites {phase}-UI.md | Could version {phase}-UI.md (v1, v2) for comparison, but YAGNI for now |

## Sources

- `.planning/PROJECT.md` -- primary source for requirements, constraints, and GSD architectural patterns
- GSD's documented parallel research agent pattern (4 agents + synthesizer) as architectural template
- Design-workflow's `.cursor/rules/*.mdc` structure as source material for agent prompts
- Confidence: MEDIUM -- architecture is derived from project specifications and GSD's documented patterns. Direct source code verification of upstream GSD was not possible in this research session.
