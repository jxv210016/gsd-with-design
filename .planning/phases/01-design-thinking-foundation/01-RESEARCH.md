# Phase 1: Design Thinking Foundation - Research

**Researched:** 2026-03-05
**Domain:** Claude Code slash command authoring / interactive interview prompt design / DESIGN.md schema definition
**Confidence:** HIGH

## Summary

Phase 1 creates two artifacts: (1) `commands/gsd/design-thinking.md` -- a standalone Claude Code slash command that runs a design thinking interview, and (2) the DESIGN.md schema it produces. This is purely a prompt engineering task -- no code, no dependencies, no runtime. The "stack" is markdown files following GSD's established conventions for slash commands.

The command must follow GSD's existing patterns: frontmatter with `name`, `description`, `argument-hint`, and `allowed-tools`; workflow structured with `<objective>`, `<execution_context>`, `<process>`, and `<success_criteria>` blocks; interactive questioning via AskUserQuestion tool with concrete options (header max 12 chars); and file output to `.planning/DESIGN.md`. The upstream Design-workflow project provides the interview structure (Problem Space, Emotional Core, Solution Space + Brand Identity) which must be adapted to GSD's conventions.

**Primary recommendation:** Build the command as a single markdown file following GSD's `discuss-phase.md` as the structural template, with the upstream Design-workflow's three-phase interview (Problem Space -> Emotional Core -> Solution Space + Brand Identity) adapted to use AskUserQuestion with 2-3 concrete options per question.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Linear progression: Problem Space -> Emotional Core -> Solution Space -> Brand Identity, each building on prior answers
- Use AskUserQuestion with concrete options (+ automatic "Other") for each key decision -- 2-3 questions per section (8-12 total)
- Include inline examples of good vs bad answers to guide users (e.g., Emotional Core: "modern and clean" vs "calm confidence -- like a trusted advisor who never rushes you")
- Load PROJECT.md if it exists to pre-fill context (project name, description, tech stack) -- avoid re-asking what new-project already captured
- Structured bullet points under consistent sub-headings per section (not prose, not key-value)
- Problem Space: Target Users, Core Problem, Current Alternatives, Pain Points
- Emotional Core: One primary emotional statement + 3-4 supporting attributes (e.g., trustworthy, unhurried, expert, approachable)
- Solution Space: Key capabilities, tech stack (framework, styling approach, key libraries) -- stack captured here so design agents don't need to also load PROJECT.md
- Brand Identity: Visual direction included -- color mood (warm/cool/neutral), typography feel (geometric/humanist/monospace), visual density preference (spacious/balanced/dense)
- Schema includes `schema_version: 1` for future evolution
- Show complete DESIGN.md, then ask: "Does this capture your direction?" with Yes / Edit / Regenerate
- Edit: Ask "What would you like to change?" in natural language, Claude updates relevant sections, re-displays for approval
- Regenerate: Keep user's interview answers but produce a fresh DESIGN.md interpretation (don't re-interview)
- Unlimited edit/regenerate cycles until user explicitly approves -- no artificial limit
- Skip offered at the start only: "Design thinking helps ground your project. Skip to use vanilla GSD, or continue?"
- Once user starts answering, they're committed to finishing (no mid-interview skip)
- Skip produces no DESIGN.md -- downstream behavior is identical to vanilla GSD
- Standalone command and embedded (new-project) experience are identical -- same interview, same validation, same output. Single implementation
- When DESIGN.md already exists: Ask "Update, View, or Replace?" (consistent with GSD's existing context handling pattern)
- Update = revise specific parts via natural language edits
- View = show current DESIGN.md, then offer update/replace
- Replace = full re-interview from scratch

### Claude's Discretion
- Exact question wording and option labels for each interview question
- Sub-heading names within each DESIGN.md section
- How PROJECT.md context is woven into interview questions (phrasing, pre-filling)
- Error messaging and edge case copy

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| R1.1 | `commands/gsd/design-thinking.md` -- standalone design thinking command | GSD command structure analyzed; frontmatter, allowed-tools, process blocks documented; discuss-phase.md serves as structural template |
| R1.2 | DESIGN.md schema defined (Problem Space, Emotional Core, Solution Space, Brand Identity) with `schema_version: 1` | Schema sections locked in CONTEXT.md; sub-headings identified; upstream Design-workflow output format studied |
| R1.4 | Design thinking is skippable -- "skip" exits cleanly, no DESIGN.md = vanilla behavior downstream | Skip UX decided in CONTEXT.md (start-only offer); guard clause pattern from existing GSD commands documented |
| R1.5 | DESIGN.md validated with user before proceeding ("Does this capture your direction? [Yes/Edit/Regenerate]") | Validation loop pattern documented; matches GSD's existing checkpoint/approval patterns |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Markdown (.md) | N/A | Command definition and DESIGN.md output | GSD's native format; Claude Code reads markdown as system prompts |
| AskUserQuestion tool | Built-in | Interactive questioning during interview | GSD's established interaction pattern; adds "Other" automatically |
| Read tool | Built-in | Load PROJECT.md context | Standard file reading in GSD commands |
| Write tool | Built-in | Write DESIGN.md output | Standard file writing in GSD commands |
| Bash tool | Built-in | Init tool calls, directory creation | Standard for GSD phase operations |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `gsd-tools.cjs init` | Bundled with GSD | Phase initialization, path resolution | At command start to resolve phase directories |
| `gsd-tools.cjs commit` | Bundled with GSD | Commit DESIGN.md to git | After user approves DESIGN.md |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AskUserQuestion | Plain text prompts | AskUserQuestion provides structured options + automatic "Other"; plain text is slower and less focused |
| Single command file | Command + workflow split | GSD uses command + workflow for complex commands (new-project), but design-thinking is simple enough for a single file |

## Architecture Patterns

### Recommended File Structure
```
commands/
  gsd/
    design-thinking.md     # The slash command (this phase's primary deliverable)

.planning/
  DESIGN.md                # Output artifact (generated by the command)
```

### Pattern 1: GSD Slash Command Structure
**What:** Every GSD command follows a consistent markdown structure with frontmatter + XML-tagged sections.
**When to use:** Always -- this is the format Claude Code expects for slash commands.
**Example:**
```markdown
---
name: gsd:design-thinking
description: Run design thinking to create DESIGN.md
argument-hint: "[--skip]"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---

<objective>
[What this command does and what it produces]
</objective>

<execution_context>
[@ references to workflow files, templates, references]
</execution_context>

<process>
[Step-by-step execution flow]
</process>

<success_criteria>
[What "done" looks like]
</success_criteria>
```
Source: Analyzed from `/Users/jayvanam/.claude/commands/gsd/discuss-phase.md` and `new-project.md`

### Pattern 2: AskUserQuestion Interaction Pattern
**What:** GSD uses AskUserQuestion for structured user input with concrete options.
**When to use:** Every decision point in the interview.
**Constraints discovered from GSD source:**
- `header` must be max 12 characters (hard limit -- validation rejects longer)
- `options` should be 2-4 concrete choices (AskUserQuestion adds "Other" automatically)
- When user selects "Other" and provides freeform input, follow up with plain text (NOT another AskUserQuestion)
- `multiSelect: true` available but not needed for this command (single-choice per question)

**Example:**
```
AskUserQuestion:
  header: "Color Mood"
  question: "What color temperature fits your product's emotional direction?"
  options:
    - "Warm (oranges, reds, earth tones) -- inviting, human, approachable"
    - "Cool (blues, greens, grays) -- professional, calm, trustworthy"
    - "Neutral (black, white, silver) -- minimal, modern, sophisticated"
```

### Pattern 3: Existing-File Check Pattern
**What:** GSD commands check for existing artifacts and offer Update/View/Skip options.
**When to use:** When DESIGN.md already exists and user re-runs the command.
**Example from discuss-phase.md:**
```
If CONTEXT.md exists:
  AskUserQuestion:
    header: "Context"
    question: "Phase [X] already has context. What do you want to do?"
    options:
      - "Update it"
      - "View it"
      - "Skip"
```

Adapt for DESIGN.md: "Update, View, or Replace?" as specified in CONTEXT.md decisions.

### Pattern 4: Guard Clause for Skip Behavior
**What:** Check file existence as the gate for downstream behavior.
**When to use:** Skip produces no DESIGN.md; all downstream design features check `if DESIGN.md exists`.
**Critical principle:** The absence of DESIGN.md IS the skip state. No flags, no config, no state tracking needed.

### Pattern 5: PROJECT.md Context Pre-loading
**What:** Load PROJECT.md at interview start to avoid re-asking already-answered questions.
**When to use:** When design-thinking runs as standalone command on an existing GSD project.
**What to extract:** Project name, description, tech stack, target users (if captured in PROJECT.md).
**How to use it:** Weave into interview questions as pre-filled context: "Your project targets [X users]. What specific problem are they facing?" instead of asking who the users are again.

### Anti-Patterns to Avoid
- **Checklist walking:** Don't ask questions mechanically. Build each question on the user's prior answer. The CONTEXT.md says "feel like a conversation with a thinking partner, not a form to fill out."
- **Vague emotional core:** Without inline examples, users default to adjectives like "modern" and "clean." The examples are critical: show bad ("modern and clean") vs good ("calm confidence -- like a trusted advisor who never rushes you").
- **Prose in DESIGN.md:** Output must be structured bullet points under consistent sub-headings, not paragraph prose. Agents parse bullet points more reliably than prose.
- **Re-asking PROJECT.md questions:** If PROJECT.md says "React + Tailwind," don't ask about tech stack -- pre-fill it in Solution Space and let the user confirm or change.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| User interaction | Custom prompting logic | AskUserQuestion tool | Built-in, adds "Other", consistent UX across all GSD commands |
| File path resolution | Manual path construction | `gsd-tools.cjs init phase-op` | Handles padded phase numbers, slug generation, directory creation |
| Git commits | Manual git commands | `gsd-tools.cjs commit` | Handles commit message formatting, respects `commit_docs` config |
| Interview flow state | State machine / JSON tracking | Linear markdown process steps | GSD commands are stateless -- the conversation IS the state |

**Key insight:** This is a prompt file, not a program. There is no runtime state management. The interview flows linearly through the markdown process steps, and Claude maintains conversational state naturally.

## Common Pitfalls

### Pitfall 1: AskUserQuestion Header Too Long
**What goes wrong:** Headers over 12 characters cause validation rejection, breaking the interview flow.
**Why it happens:** Natural section names like "Brand Identity" or "Solution Space" exceed 12 chars.
**How to avoid:** Use abbreviated headers: "Brand", "Solution", "Emotional", "Problem", "Skip?", "Validate", "Color Mood", "Typography".
**Warning signs:** Headers like "Current Alternatives" (21 chars) or "Visual Density" (14 chars).

### Pitfall 2: Emotional Core Produces Vague Output
**What goes wrong:** Users respond with adjectives ("modern," "clean," "professional") that are too generic to drive downstream design agent behavior.
**Why it happens:** Emotional direction is unfamiliar territory for most developers. Without examples, they default to surface-level descriptors.
**How to avoid:** Show inline examples of good vs bad emotional core statements BEFORE asking. The examples in CONTEXT.md are the blueprint: "modern and clean" (bad) vs "calm confidence -- like a trusted advisor who never rushes you" (good). Frame the question to elicit feeling-statements, not adjective-lists.
**Warning signs:** DESIGN.md Emotional Core section contains only single words or generic adjectives.

### Pitfall 3: DESIGN.md Schema Inconsistency
**What goes wrong:** The command produces DESIGN.md with sections/sub-headings that design agents (Phase 2) don't expect, or missing sections that agents require.
**Why it happens:** Schema is defined implicitly in the command rather than as a formal template.
**How to avoid:** Define the exact DESIGN.md template in the command file itself. Every section header, every sub-heading, documented. Include `schema_version: 1` at the top so future changes can be detected. Design agents (Phase 2) will parse these exact headings.
**Warning signs:** Different runs of design-thinking produce structurally different DESIGN.md files.

### Pitfall 4: Skip State Not Clean
**What goes wrong:** Skip produces a partial DESIGN.md or leaves state that confuses downstream commands.
**Why it happens:** Skip logic exits mid-flow without cleanup, or early exit writes a placeholder file.
**How to avoid:** Skip = no DESIGN.md written. Period. The absence of the file IS the skip state. Don't write empty files, placeholder files, or "skipped" markers. All downstream features use `if DESIGN.md exists` as their guard.
**Warning signs:** A `.planning/DESIGN.md` file exists after skipping.

### Pitfall 5: Validation Loop Doesn't Actually Loop
**What goes wrong:** User selects "Edit" or "Regenerate" but the command doesn't re-display the updated DESIGN.md for re-validation.
**Why it happens:** The process flow doesn't loop back to the validation step after edits.
**How to avoid:** Explicitly structure the validation as a loop: display -> ask -> if Yes: done, if Edit: ask what to change, update, re-display -> ask, if Regenerate: rewrite from interview answers, re-display -> ask. The loop continues until "Yes."
**Warning signs:** User can only edit once, or regenerate doesn't show the result for approval.

### Pitfall 6: Not Loading PROJECT.md Context
**What goes wrong:** Design thinking re-asks questions already answered during `/gsd:new-project`, frustrating users.
**Why it happens:** The command doesn't check for PROJECT.md or doesn't extract relevant context from it.
**How to avoid:** At command start, read `.planning/PROJECT.md` if it exists. Extract: project name, description, tech stack, target users, constraints. Use these to pre-fill Solution Space (tech stack) and inform Problem Space questions (target users, core problem).
**Warning signs:** User is asked "What tech stack?" when PROJECT.md already says "React + Tailwind."

## Code Examples

### DESIGN.md Schema Template
```markdown
---
schema_version: 1
generated: {date}
---

# DESIGN.md

## Problem Space

### Target Users
- {Who experiences this problem -- specific, not generic}

### Core Problem
- {What breaks, for whom, and when -- one clear statement}

### Current Alternatives
- {What users do today instead}
- {Why those alternatives fall short}

### Pain Points
- {Specific friction points in the current experience}

## Emotional Core

### Primary Emotional Statement
{One sentence describing how using this product should feel}
{Example: "Calm confidence -- like a trusted advisor who never rushes you"}

### Supporting Attributes
- {Attribute 1: e.g., trustworthy}
- {Attribute 2: e.g., unhurried}
- {Attribute 3: e.g., expert}
- {Attribute 4: e.g., approachable}

## Solution Space

### Key Capabilities
- {v1 feature/capability 1}
- {v1 feature/capability 2}
- {v1 feature/capability 3}

### Tech Stack
- **Framework:** {e.g., React, Vue, Svelte, vanilla}
- **Styling:** {e.g., Tailwind, CSS Modules, styled-components}
- **Key Libraries:** {e.g., Framer Motion, Radix UI}

## Brand Identity

### Visual Direction
- **Color Mood:** {warm / cool / neutral}
- **Typography Feel:** {geometric / humanist / monospace}
- **Visual Density:** {spacious / balanced / dense}

### Brand Personality
- {How the brand speaks and presents itself}
- {Tone: e.g., confident but not arrogant, friendly but not casual}

### Anti-Patterns
- {What this brand must NEVER feel like}
- {e.g., "Never feel corporate or impersonal"}
```

### Command Frontmatter
```markdown
---
name: gsd:design-thinking
description: Run design thinking interview to create DESIGN.md
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---
```
Source: Pattern from existing GSD commands at `~/.claude/commands/gsd/`

### Interview Question Example (with AskUserQuestion)
```
AskUserQuestion:
  header: "Problem"
  question: "What specific problem does your product solve?\n\nGood: 'Developers waste 30 minutes per PR reviewing inconsistent UI decisions'\nBad: 'Bad design'"
  options:
    - "Let me describe the problem"
    - "I have a specific user story"
    - "It's more of a feeling/frustration"
```

### Validation Loop Example
```
Step: Validate DESIGN.md
  1. Display the complete DESIGN.md content
  2. AskUserQuestion:
       header: "Direction"
       question: "Does this capture your direction?"
       options:
         - "Yes -- looks good"
         - "Edit -- I want to change something"
         - "Regenerate -- rewrite from my answers"
  3. If "Yes": Write DESIGN.md, proceed to commit
  4. If "Edit": Ask "What would you like to change?" as plain text
     -> User describes changes in natural language
     -> Update relevant sections of DESIGN.md
     -> Return to step 1
  5. If "Regenerate": Keep interview answers, produce fresh interpretation
     -> Return to step 1
```

### Skip Flow Example
```
Step 1: Skip Offer (first interaction)
  AskUserQuestion:
    header: "Design"
    question: "Design thinking helps ground your project in user needs and emotional direction. Skip to use vanilla GSD, or continue?"
    options:
      - "Continue -- let's think about design"
      - "Skip -- I'll use vanilla GSD"

  If "Skip": Exit command. No DESIGN.md written. Done.
  If "Continue": Proceed to interview.
```

### Re-run Flow (DESIGN.md exists)
```
Step 0: Check existing
  If .planning/DESIGN.md exists:
    AskUserQuestion:
      header: "DESIGN.md"
      question: "You already have a DESIGN.md. What would you like to do?"
      options:
        - "Update -- revise specific parts"
        - "View -- show me what's there"
        - "Replace -- start fresh"

    If "Update": Show DESIGN.md, ask what to change, enter edit loop
    If "View": Display DESIGN.md, then offer Update/Replace
    If "Replace": Full re-interview from scratch
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Design-workflow writes to CLAUDE.md | GSD-with-Design writes to .planning/DESIGN.md | This project | Consistent with GSD's .planning/ convention; CLAUDE.md stays for project-wide config |
| Design-workflow uses .cursor/rules/*.mdc | GSD-with-Design uses workflows/design/*.md | This project | Matches GSD's workflow file convention |
| Freeform interview (no structured options) | AskUserQuestion with concrete choices | GSD pattern | Faster, more focused, consistent UX |

## Open Questions

1. **Exact number of questions per section**
   - What we know: CONTEXT.md says "2-3 questions per section (8-12 total)" across 4 sections
   - What's unclear: Whether some sections need more depth than others (Emotional Core likely needs more guidance than Problem Space)
   - Recommendation: Start with 2 per section (8 total), let the quality of the DESIGN.md output determine if more are needed. The AskUserQuestion "Other" option provides escape hatch for users who need more nuance.

2. **PROJECT.md field extraction**
   - What we know: Load PROJECT.md if exists, extract project name, description, tech stack
   - What's unclear: Exact fields in PROJECT.md vary by project. What if tech stack isn't captured?
   - Recommendation: Gracefully handle missing fields. If tech stack isn't in PROJECT.md, ask about it in Solution Space. If it is, pre-fill and let user confirm.

3. **Command file size**
   - What we know: GSD commands range from simple (30 lines for quick-reference) to complex (discuss-phase.md at ~600 lines via its workflow reference)
   - What's unclear: Whether design-thinking.md should reference a separate workflow file or be self-contained
   - Recommendation: Self-contained single file. The interview logic is linear and doesn't need the complexity of a separate workflow. If it exceeds ~400 lines, consider splitting into command + workflow.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual validation (prompt-based system, no automated test framework applies) |
| Config file | None -- this is a markdown prompt file, not executable code |
| Quick run command | `/gsd:design-thinking` (invoke the command and verify behavior) |
| Full suite command | Run command through all paths: skip, full interview, re-run with existing DESIGN.md |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| R1.1 | Command exists and is invocable as `/gsd:design-thinking` | manual-only | Verify `commands/gsd/design-thinking.md` exists with correct frontmatter | No -- Wave 0 |
| R1.2 | DESIGN.md output matches schema with all sections and `schema_version: 1` | manual-only | Run command, inspect `.planning/DESIGN.md` for required sections | No -- Wave 0 |
| R1.4 | Skip produces no DESIGN.md | manual-only | Run command, select Skip, verify no `.planning/DESIGN.md` exists | No -- Wave 0 |
| R1.5 | Validation loop works (Yes/Edit/Regenerate) | manual-only | Run command through each validation path | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Invoke the command and verify output manually
- **Per wave merge:** Run all paths (skip, full, re-run) and verify DESIGN.md schema compliance
- **Phase gate:** All 4 requirement paths verified before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `commands/gsd/design-thinking.md` -- the primary deliverable (does not exist yet)
- [ ] Validation checklist for DESIGN.md schema compliance (manual, not automated)

Note: This phase produces a markdown prompt file, not executable code. Traditional automated testing does not apply. Validation is by running the command through all decision paths and inspecting output.

## Sources

### Primary (HIGH confidence)
- `/Users/jayvanam/.claude/commands/gsd/discuss-phase.md` -- GSD command structure, AskUserQuestion patterns, process flow conventions
- `/Users/jayvanam/.claude/commands/gsd/new-project.md` -- Command frontmatter format, execution_context pattern
- `/Users/jayvanam/.claude/get-shit-done/workflows/discuss-phase.md` -- Full workflow structure, step definitions, AskUserQuestion constraints (12-char header limit), freeform fallback rules
- `/Users/jayvanam/.claude/get-shit-done/references/questioning.md` -- GSD questioning philosophy, anti-patterns
- `/Users/jayvanam/.claude/get-shit-done/references/ui-brand.md` -- GSD visual patterns for banners, checkpoints
- `/Users/jayvanam/.claude/get-shit-done/templates/context.md` -- CONTEXT.md template showing GSD's output format conventions
- `/Users/jayvanam/.claude/get-shit-done/templates/project.md` -- PROJECT.md template showing fields available for pre-loading

### Secondary (MEDIUM confidence)
- [AI-by-design/Design-workflow GitHub repo](https://github.com/AI-by-design/Design-workflow) -- Upstream design-thinking command structure, three-phase interview model (Problem Space, Emotional Core, Solution Space + Brand Identity), CLAUDE.md output format
- `.planning/research/ARCHITECTURE.md` -- Architecture patterns from project initialization research
- `.planning/research/FEATURES.md` -- Feature landscape from project initialization research
- `.planning/research/PITFALLS.md` -- Domain pitfalls from project initialization research

### Tertiary (LOW confidence)
- None -- all findings verified against primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- GSD's command system is directly inspectable; all tools are built-in Claude Code features
- Architecture: HIGH -- Command structure verified from multiple existing GSD commands; patterns are consistent
- Pitfalls: HIGH -- AskUserQuestion constraints verified from source (12-char header limit); emotional core quality concern well-documented in upstream Design-workflow
- DESIGN.md schema: HIGH -- Locked in CONTEXT.md decisions; sub-headings specified

**Research date:** 2026-03-05
**Valid until:** 2026-04-05 (stable domain -- GSD command conventions unlikely to change in 30 days)
