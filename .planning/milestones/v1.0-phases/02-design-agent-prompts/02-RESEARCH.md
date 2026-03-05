# Phase 2: Design Agent Prompts - Research

**Researched:** 2026-03-05
**Domain:** Agent prompt engineering / design system principles / GSD workflow conventions
**Confidence:** HIGH

## Summary

Phase 2 creates four markdown prompt files in `workflows/design/`: `stack-conventions.md`, `ui-design.md`, `ux-design.md`, and `motion-design.md`. These are agent system prompts -- not code, not commands, not workflows. Each file defines how a design agent behaves when spawned by the Phase 3 orchestrator via `Task()`. The work is purely prompt engineering constrained by GSD conventions and the DESIGN.md schema from Phase 1.

The upstream Design-workflow project provides substantial source material in its `.cursor/rules/*.mdc` files (ui-design, ux-design, motion-design, stack). However, these are Cursor-specific rule files that hardcode Next.js/Tailwind/shadcn/Bun assumptions. Phase 2 must distill the framework-agnostic design principles from this source material, restructure them into GSD's `<purpose>/<context>/<output>` XML block convention, and make each agent adaptive by reading DESIGN.md's Tech Stack section rather than assuming any specific framework. The stack-conventions agent is unique: it runs once at init, reads DESIGN.md's Tech Stack, and writes `.planning/STACK.md` -- a translation layer that all three design agents reference for framework-specific recipes.

**Primary recommendation:** Adapt upstream Design-workflow rule files into four GSD workflow prompts using shared XML structure (`<purpose>`, `<context>`, `<rules>`, `<output_format>`), each under 1500 tokens, stack-agnostic with conditional recipes keyed to DESIGN.md values. Stack-conventions agent writes STACK.md once; the three design agents read both DESIGN.md and STACK.md, return structured sections to the orchestrator.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Hybrid format: principles with concrete defaults. E.g., "8pt grid (default spacing: 8/16/24/32px) -- adjust scale if DESIGN.md specifies dense/spacious"
- Organized by design dimension (spacing, color, typography, states) -- not by component type
- Conditional recipes keyed to DESIGN.md values. E.g., "Read DESIGN.md > Brand Identity > Color Mood. If warm: primary in orange-amber range. If cool: primary in blue-slate range"
- Agents return structured sections to the orchestrator -- they do NOT write files directly. Phase 3 orchestrator synthesizes into {phase}-UI.md
- Minimal stack detection: framework, styling, and key libraries with their conventions -- not full dev conventions
- Reads DESIGN.md > Solution Space > Tech Stack as single source of truth -- no codebase scanning
- Writes to `.planning/STACK.md` (project-level, written once, read by all design agents across all phases)
- Includes framework translation recipes. E.g., "In Tailwind, 8pt grid = spacing scale: p-2 (8px), p-4 (16px), p-6 (24px)"
- UI agent: concrete scales + rules. Define actual spacing scale, color ratio (60-30-10), type scale with specific values
- UX agent: actionable rules. E.g., "Max 5-7 options per choice point (Hick's Law). If more, use progressive disclosure or categorization"
- Motion agent: duration/easing defaults. E.g., "Micro-interactions: 150-200ms ease-out. Page transitions: 300-400ms ease-in-out. Always respect prefers-reduced-motion"
- Accessibility integrated per agent within its domain: UI = contrast ratios, UX = focus management + screen reader order, Motion = prefers-reduced-motion
- Independent + shared STACK.md: each agent reads DESIGN.md and STACK.md independently, no cross-references between agents
- Own domain only for overlap areas: UI = visual sizing, UX = cognitive/behavioral, Motion = animation feedback. Orchestrator merges during synthesis
- Shared prompt structure across all three design agents: identical XML sections (<purpose>, <context>, <output_format>, <rules>)
- Conflicts resolved by Phase 3 orchestrator using hierarchy: UX > visual, a11y > motion, brand = tiebreaker

### Claude's Discretion
- Token budget per agent: target ~1500 tokens, balance conciseness vs. completeness as needed
- Exact section names within the shared prompt structure
- Specific design principles to include vs. omit per agent (within the domains defined above)
- How to structure conditional recipes for edge cases (e.g., when DESIGN.md lacks certain values)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| R2.1 | `workflows/design/stack-conventions.md` -- generic/adaptive stack conventions agent, spawned once at init | Upstream stack.mdc analyzed (Next.js-specific); must be generalized. DESIGN.md Tech Stack section provides framework/styling/libraries. Agent writes STACK.md with translation recipes. |
| R2.2 | `workflows/design/ui-design.md` -- 8pt grid, 60-30-10 color, typography, component states (<1500 tokens) | Upstream ui-design.mdc provides comprehensive rules. Must distill to ~1500 tokens. Key principles: 8pt spacing, 60-30-10 color, ratio-based type scale, component state completeness. Organize by dimension not component. |
| R2.3 | `workflows/design/ux-design.md` -- Hick's Law, Peak-end rule, decision architecture, honest design (<1500 tokens) | Upstream ux-design.mdc provides full UX psychology rules. Must distill: cognitive load limits, vulnerability moments, honest design enforcement, empty/error states, forms. Actionable rules not suggestions. |
| R2.4 | `workflows/design/motion-design.md` -- animation principles, reduced motion first, purposeful not decorative (<1500 tokens) | Upstream motion-design.mdc provides three philosophies (restraint, polish, experimentation). Must distill: duration/easing defaults, safe-to-animate properties, enter/exit recipes, prefers-reduced-motion as non-negotiable. |
| R2.5 | Agents are stack-agnostic -- reference DESIGN.md stack section, never hardcode framework | Stack-conventions agent is the "Rosetta Stone" -- translates abstract design concepts into framework-specific syntax. Design agents reference STACK.md for implementation recipes, keeping their own rules framework-independent. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Markdown (.md) | N/A | Agent prompt files | GSD's native format for workflows |
| Read tool | Built-in | Agent reads DESIGN.md and STACK.md | Standard file reading in GSD agents |
| Write tool | Built-in | Stack agent writes STACK.md | Standard file writing |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `gsd-tools.cjs commit` | Bundled | Commit agent files to git | After writing prompt files |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Separate STACK.md file | Inline stack info in each agent | STACK.md avoids duplication across 3 agents and enables single-update-point |
| Four separate prompt structures | One combined agent | Four agents match GSD parallel wave pattern; each has distinct expertise |
| Framework-specific agents | Stack-agnostic with STACK.md | Agnostic + translation layer supports any tech stack |

## Architecture Patterns

### Recommended File Structure
```
workflows/
  design/
    stack-conventions.md   # Init-once agent -> writes .planning/STACK.md
    ui-design.md           # Per-phase parallel agent -> returns structured output
    ux-design.md           # Per-phase parallel agent -> returns structured output
    motion-design.md       # Per-phase parallel agent -> returns structured output
```

### Pattern 1: Shared Agent Prompt Structure
**What:** All four agents use identical XML section structure for consistency.
**When to use:** Every design agent prompt file.
**Example:**
```markdown
<purpose>
[What this agent does, its domain, its expertise]
</purpose>

<context>
[What files to read: DESIGN.md, STACK.md, phase context]
[How to interpret DESIGN.md sections]
</context>

<rules>
[Design principles organized by dimension]
[Conditional recipes keyed to DESIGN.md values]
[Accessibility requirements for this domain]
</rules>

<output_format>
[Structured markdown sections to return to orchestrator]
[Section headings that Phase 3 synthesizer expects]
</output_format>
```
Source: GSD workflow convention from `<purpose>/<context>/<output>` pattern observed in discuss-phase.md, research-phase.md, execute-plan.md

### Pattern 2: Conditional Recipe Pattern
**What:** Design rules that adapt based on DESIGN.md values rather than hardcoding.
**When to use:** Wherever a design decision depends on brand direction or stack choice.
**Example:**
```markdown
### Color System
Read DESIGN.md > Brand Identity > Color Mood.
- If warm: primary in orange-amber range, secondary earth tones
- If cool: primary in blue-slate range, secondary cool grays
- If neutral: primary in gray-charcoal range, secondary pure neutrals

Apply 60-30-10 distribution regardless of mood:
- 60% dominant (background/canvas)
- 30% secondary (surfaces/cards)
- 10% accent (interactive elements, CTAs)
```

### Pattern 3: Stack Translation Layer (STACK.md)
**What:** Stack-conventions agent reads DESIGN.md Tech Stack, writes `.planning/STACK.md` with framework-specific translation recipes that other agents reference.
**When to use:** Once at project init. All three design agents read STACK.md for implementation-specific guidance.
**Example STACK.md output:**
```markdown
---
generated_from: DESIGN.md
framework: React
styling: Tailwind CSS
key_libraries: [Framer Motion, Radix UI]
---

# Stack Conventions

## Spacing (8pt grid in Tailwind)
- 8px = p-2, m-2, gap-2
- 16px = p-4, m-4, gap-4
- 24px = p-6, m-6, gap-6
- 32px = p-8, m-8, gap-8

## Color (Tailwind)
- Define in tailwind.config: primary, secondary, accent
- Use semantic tokens: bg-primary, text-secondary, border-accent

## Typography (Tailwind)
- Use font-sans/font-serif/font-mono utility classes
- Type scale via text-sm, text-base, text-lg, text-xl

## Motion (Framer Motion)
- Enter: <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} />
- Exit: <AnimatePresence> wrapper required
- Reduced motion: useReducedMotion() hook
```

### Pattern 4: Domain Boundary Enforcement
**What:** Each agent owns a specific domain and does not cross into other agents' territory.
**When to use:** All overlap areas between agents.
**Domain boundaries:**
| Area | UI Agent | UX Agent | Motion Agent |
|------|----------|----------|--------------|
| Button sizing | Visual dimensions, padding, border-radius | Fitts's Law (target size for usability) | Press feedback animation |
| Loading states | Skeleton shapes, spinner styling | Perceived performance, progress messaging | Enter/exit transitions for loading -> content |
| Empty states | Visual layout, illustration placement | Copy, CTA, emotional tone | Fade-in animation |
| Forms | Input sizing, label typography | Validation timing, error messaging, field count | Field focus transitions |

### Anti-Patterns to Avoid
- **Hardcoding frameworks:** Never mention React, Tailwind, Framer Motion in ui/ux/motion agent rules. That belongs in STACK.md via stack-conventions agent.
- **Cross-referencing agents:** No agent should say "see ui-design agent output." They are independent. Orchestrator merges.
- **Component-organized rules:** Don't structure as "Button rules, Card rules, Modal rules." Structure by dimension: spacing, color, typography, states.
- **Suggestion language:** Don't say "consider using" or "you might want." Say "Use X" or "Apply Y." Agents are opinionated specialists.
- **Exceeding token budget:** Each agent prompt should be ~1500 tokens. Reference DESIGN.md/STACK.md for context rather than embedding examples inline.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Framework-specific recipes | Inline framework code in each agent | STACK.md via stack-conventions agent | Single source of truth; agents stay stack-agnostic |
| Design principle validation | Custom validation logic | Self-verification checklists in agent output | Agents are prompts, not programs |
| Inter-agent conflict resolution | Complex merging in agents | Phase 3 orchestrator with UX > visual > motion hierarchy | Keeps agents simple and independent |
| Spacing/color/type scales | Custom scale definitions per project | Defaults in agent + overrides from DESIGN.md | Agents provide sane defaults; DESIGN.md customizes |

**Key insight:** These are prompt files, not programs. The "runtime" is Claude interpreting markdown instructions. Complexity belongs in the quality of the written rules, not in orchestration logic.

## Common Pitfalls

### Pitfall 1: Token Budget Explosion
**What goes wrong:** Agent prompts grow past 1500 tokens as edge cases and examples accumulate. Each token in the agent prompt consumes context window before any user content loads.
**Why it happens:** The upstream Design-workflow rules files are comprehensive (ui-design.mdc alone has 100+ rules). Temptation to port everything.
**How to avoid:** Ruthlessly prioritize. Include principles (8pt grid, 60-30-10) not exhaustive examples. Use "Read STACK.md for framework recipes" instead of inlining recipes. Target ~1200-1500 tokens per agent. Count tokens before finalizing.
**Warning signs:** Agent prompt exceeds 2000 tokens. Agent includes code examples for specific frameworks.

### Pitfall 2: Stack-Specific Leakage in Design Agents
**What goes wrong:** ui-design agent says "use Tailwind's p-4 for 16px spacing" or motion agent says "use Framer Motion's AnimatePresence." Now the agent is useless for Vue/CSS Modules/vanilla CSS projects.
**Why it happens:** Upstream source material is Next.js/Tailwind/Framer Motion specific. Easy to copy-paste without abstracting.
**How to avoid:** Design agents state principles: "16px spacing for related elements." STACK.md translates: "In Tailwind: p-4. In CSS Modules: padding: 16px. In styled-components: padding: ${spacing.md}." If a design agent mentions a specific framework or library name, it's wrong.
**Warning signs:** Framework names (React, Vue, Tailwind, Framer Motion) appear in ui-design.md, ux-design.md, or motion-design.md.

### Pitfall 3: Vague Conditional Recipes
**What goes wrong:** Conditional recipes are too broad: "If DESIGN.md says warm, use warm colors." This is useless -- the agent needs to produce specific guidance.
**Why it happens:** Trying to be stack-agnostic makes authors avoid concrete values.
**How to avoid:** Conditional recipes should produce concrete defaults: "If warm: primary hue 20-45 (orange-amber range), secondary hue 30-60 (earth tones), neutral warm gray (eg. #78716c base)." Abstract principle + concrete default values.
**Warning signs:** Agent output says "use appropriate colors" or "pick a suitable spacing."

### Pitfall 4: Missing Graceful Degradation for Absent DESIGN.md Fields
**What goes wrong:** Agent assumes DESIGN.md always has Color Mood, Typography Feel, Visual Density. Some projects skip Brand Identity or leave fields empty. Agent produces errors or empty output.
**Why it happens:** Agent prompt doesn't account for missing values.
**How to avoid:** Every conditional recipe needs a fallback: "Read Color Mood. If warm: [warm rules]. If cool: [cool rules]. If neutral or absent: default to neutral." The "absent" case MUST be handled.
**Warning signs:** Agent's conditional logic has no default/fallback branch.

### Pitfall 5: Stack-Conventions Agent Scope Creep
**What goes wrong:** Stack-conventions agent tries to be a full development conventions guide (linting rules, file structure, import patterns, testing conventions) instead of just the design-relevant stack translations.
**Why it happens:** Upstream stack.mdc covers full dev conventions (Biome, file structure, TypeScript patterns). Tempting to port all of it.
**How to avoid:** Stack-conventions agent scope is ONLY: framework translation recipes for spacing, color, typography, and motion. Not: linting, testing, file structure, TypeScript patterns, git conventions.
**Warning signs:** STACK.md contains sections about linting, testing, or code organization.

### Pitfall 6: Overlapping Domain Boundaries
**What goes wrong:** UI agent and UX agent both give button sizing guidance. Motion agent and UI agent both specify loading state design. Orchestrator receives contradictory recommendations.
**Why it happens:** Design disciplines genuinely overlap. Without clear domain boundaries, each agent covers everything.
**How to avoid:** Define explicit boundaries (see Pattern 4 above). UI = visual appearance. UX = cognitive/behavioral. Motion = temporal transitions. When in doubt, the agent whose domain is primary owns the recommendation; the other agent only references its own concern.
**Warning signs:** Same topic appears in two agent outputs with different recommendations.

## Code Examples

### Stack-Conventions Agent Prompt Structure
```markdown
<purpose>
You are the stack conventions agent. You run ONCE at project initialization to create
.planning/STACK.md -- a translation layer that maps abstract design concepts to
framework-specific implementation syntax.

You are a Rosetta Stone: spacing, color, typography, and motion principles are universal;
their implementation syntax varies by framework.
</purpose>

<context>
Read .planning/DESIGN.md > Solution Space > Tech Stack for:
- Framework (React, Vue, Svelte, vanilla, etc.)
- Styling approach (Tailwind, CSS Modules, styled-components, vanilla CSS, etc.)
- Key libraries (Framer Motion, GSAP, Radix UI, etc.)

If Tech Stack section is missing or incomplete, produce generic CSS translations.
</context>

<rules>
Generate translation recipes for ONLY these design dimensions:
1. Spacing: 8pt grid values -> framework syntax
2. Color: semantic color tokens -> framework syntax
3. Typography: type scale values -> framework syntax
4. Motion: animation patterns -> framework/library syntax

Do NOT include: linting, testing, file structure, import conventions, git rules.
</rules>

<output_format>
Write .planning/STACK.md with this structure:

---
generated_from: DESIGN.md
framework: {detected}
styling: {detected}
key_libraries: [{detected}]
---

# Stack Conventions

## Spacing
[8pt grid -> framework syntax mappings]

## Color
[Semantic tokens -> framework syntax]

## Typography
[Type scale -> framework syntax]

## Motion
[Animation patterns -> framework/library syntax]
</output_format>
```

### UI Design Agent Prompt Structure (distilled from upstream)
```markdown
<purpose>
You are the UI design agent. You produce visual design specifications for a phase's
UI components. You enforce concrete scales and rules -- not suggestions.
Your domain: spacing, color, typography, elevation, border-radius, component states.
</purpose>

<context>
Read:
1. .planning/DESIGN.md -- Brand Identity (color mood, typography feel, density)
   and Emotional Core (personality that constrains visual choices)
2. .planning/STACK.md -- Framework-specific syntax for your recommendations
3. Phase context provided by orchestrator (what's being built this phase)
</context>

<rules>
### Spacing (8pt Grid)
All spacing multiples of 8px. 4px for fine-tuning only.
Scale: 4, 8, 16, 24, 32, 48, 64px.
Rule: internal spacing <= external spacing.

Read DESIGN.md > Visual Density:
- Spacious: favor 24-48px between sections, 16-24px between elements
- Balanced: 16-32px between sections, 8-16px between elements
- Dense: 8-16px between sections, 4-8px between elements
- If absent: default to balanced

### Color (60-30-10)
60% dominant (background), 30% secondary (surfaces), 10% accent (interactive).
Max 3 hues + neutrals. No pure black (#000) or white (#FFF).
Contrast minimum: 4.5:1 (WCAG AA).

Read DESIGN.md > Color Mood:
- Warm: primary hue 20-45, warm neutrals
- Cool: primary hue 200-230, cool neutrals
- Neutral: achromatic primary, true neutrals
- If absent: default to neutral

### Typography
Max 2 typefaces. Ratio-based scale.
Read DESIGN.md > Typography Feel:
- Geometric: Inter, Helvetica Neue family. Scale ratio 1.200
- Humanist: Source Sans, Lato family. Scale ratio 1.250
- Monospace: JetBrains Mono, Fira family. Scale ratio 1.125
- If absent: default to geometric, ratio 1.200

### Component States
Every interactive element must have: default, hover, focus, active,
disabled (opacity 40%), loading, error, empty.
Focus: visible ring (never remove outline without replacement).
Buttons + inputs share height scale (32, 36, 40, 48px).

### Accessibility
4.5:1 contrast for body text, 3:1 for large text.
Color never sole meaning conveyor. Semantic HTML first.
aria-label on icon-only buttons.
</rules>

<output_format>
Return structured markdown sections:

## Visual Design Specifications

### Spacing System
[8pt grid values, density interpretation]

### Color System
[60-30-10 distribution, mood interpretation, semantic colors]

### Typography System
[Type scale, font selections, hierarchy rules]

### Component States
[State coverage requirements, shared height scale]

### Accessibility Requirements
[Contrast ratios, semantic HTML, ARIA needs]
</output_format>
```

### UX Design Agent Prompt Structure (distilled from upstream)
```markdown
<purpose>
You are the UX design agent. You enforce cognitive science principles and honest design
patterns. You produce actionable behavioral rules -- not visual specifications.
Your domain: information architecture, decision flow, cognitive load, feedback,
honest design, error/empty states, forms.
</purpose>

<context>
Read:
1. .planning/DESIGN.md -- Emotional Core (personality constraining UX tone),
   Problem Space (who the users are, what problems they face)
2. .planning/STACK.md -- Framework patterns for implementation guidance
3. Phase context from orchestrator
</context>

<rules>
### Cognitive Load
Max 5-7 options per choice point (Hick's Law).
If more needed: progressive disclosure or categorization.
Working memory: ~4 chunks. Group into 3-5 item sections.
Recognition over recall. Sensible defaults.

### Decision Architecture
One primary action per view. No competing CTAs.
Default bias: most common path pre-selected.
Commitment escalation: small yeses before big asks.
Value before sign-up. Explore before commitment.

### Feedback Rules
100ms feedback on every user action (minimum).
2+ seconds: show progress with context, not spinner alone.
Specific confirmations: "Draft saved" not "Success."
Success states are handoffs, not dead ends.

### Error & Empty States
Errors: what happened + why + what to do next (3-part).
Empty states: acknowledge + explain + one clear CTA.
Inline form errors on blur, below the field.
Preserve all input on failed submission.

### Honest Design (Non-Negotiable)
Pricing visible before commitment.
Cancellation as discoverable as sign-up.
No confirmshaming, fake scarcity, or hidden costs.
Free trial terms explicit with date and amount.
Toggles reflect actual state unambiguously.

### Forms
Labels always visible (never placeholder-only).
Validate on blur, not keystroke.
Button labels: verb + noun ("Create account" not "Submit").
Multi-step: progress indicator showing position.

### Accessibility
Focus order follows visual reading order.
All interactive elements keyboard-accessible.
Screen reader: semantic structure, ARIA landmarks.
Touch targets: minimum 44x44px.

### Peak-End Rule
Identify peak moment (maximum value/relief) per flow.
Design ending deliberately -- last interaction is remembered.
</rules>

<output_format>
## User Experience Specifications

### Information Architecture
[Choice limits, grouping, progressive disclosure needs]

### Interaction Patterns
[Feedback timing, confirmation UX, primary actions]

### Error & Empty States
[3-part error format, empty state CTAs]

### Form Design
[Validation rules, label/placeholder guidance, submit buttons]

### Honest Design Audit
[Checklist of honest design requirements for this phase]

### Accessibility (Behavioral)
[Focus management, keyboard nav, screen reader order]
</output_format>
```

### Motion Design Agent Prompt Structure (distilled from upstream)
```markdown
<purpose>
You are the motion design agent. You enforce purposeful animation with restraint.
Every animation must justify its existence functionally (direct attention, show continuity,
indicate state change). Decorative animation is an anti-pattern.
Reduced-motion-first: design without animation, then add purposeful motion.
</purpose>

<context>
Read:
1. .planning/DESIGN.md -- Emotional Core (personality constraining motion character),
   Brand Identity > Visual Density (density affects animation scale)
2. .planning/STACK.md -- Animation library syntax (Framer Motion, GSAP, CSS, etc.)
3. Phase context from orchestrator
</context>

<rules>
### Duration Defaults
Micro-interactions (press, hover): 100-150ms
Dropdowns/tooltips: 150-200ms
Panels/drawers/modals: 250-350ms
Page transitions: 300-500ms

Read DESIGN.md > Emotional Core:
- Calm/trustworthy: slower durations (+50ms), gentle easing
- Energetic/bold: faster durations (-30ms), snappier easing
- Precise/expert: standard durations, mechanical easing
- If absent: use standard defaults above

### Easing
Entrance: ease-out (fast start, gentle landing)
Exit: ease-in (slightly faster than entrance)
Never use linear except progress bars.
Springs: bounce: 0 in professional contexts.

### Safe to Animate
Only: opacity, transform (translate, scale, rotate), filter (blur).
Never: width, height, margin, padding, top/left/right/bottom.
Height changes: use layout animation or max-height technique.

### Enter/Exit Recipes
Standard enter: opacity 0->1, translateY 8->0px, blur 4->0px
Standard exit: opacity 1->0, translateY 0->4px, blur 0->2px (subtler)
Exit always subtler than enter. Scale from 0.9 minimum, never 0.

### Motion Gaps
Every conditional render needs enter/exit transitions.
Loading -> content transitions are mandatory.
Tab/accordion content changes need transitions.
Settings panels need transitions.

### Stagger
List items: stagger only first 4-6 items, 0.05s delay between.
Beyond 6: items appear together.

### Accessibility (Non-Negotiable)
ALWAYS respect prefers-reduced-motion.
Reduced motion: remove transform animations, keep opacity fades.
Never scale from near-zero in reduced motion mode.
Pause all auto-playing decorative animations.

### Restraint Principle
If removing an animation doesn't harm comprehension, remove it.
High-frequency interactions (typing, scrolling): minimal or no animation.
No animation for keyboard-initiated actions.
One accent animation per view maximum.
</rules>

<output_format>
## Motion Design Specifications

### Animation Inventory
[Which elements in this phase need animation, with justification]

### Duration & Easing Map
[Specific durations per interaction type, easing choices]

### Enter/Exit Specifications
[Transition recipes for components appearing/disappearing]

### Reduced Motion Fallbacks
[What each animation degrades to in prefers-reduced-motion]

### Performance Notes
[GPU-composited properties only, stagger limits]
</output_format>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Cursor .mdc rule files (passive, always-on) | GSD workflow agents (active, spawned on demand) | This project | Agents are phase-aware and context-specific vs. global rules |
| Hardcoded Next.js/Tailwind/Framer Motion | Stack-agnostic + STACK.md translation layer | This project | Supports any tech stack through DESIGN.md-driven adaptation |
| Single combined design rules file | Three parallel specialist agents | This project | Matches GSD parallel wave pattern; deeper expertise per domain |
| Design rules as suggestions ("consider...") | Design rules as specifications ("use X, apply Y") | This project | Agents are opinionated specialists, not advisors |
| Generic brand guidelines | Conditional recipes keyed to DESIGN.md | This project | Rules adapt to brand direction without manual configuration |

**Upstream content status (verified 2026-03-05):**
- `ui-design.mdc`: Comprehensive visual system rules (8pt grid, 60-30-10, typography scale, component states, motion timing, responsive, a11y). ~3000 tokens -- must distill to ~1500.
- `ux-design.mdc`: Full UX psychology framework (cognitive load, Hick's Law, Fitts's Law, Peak-End, honest design, vulnerability moments, form design, empty/error states). ~3500 tokens -- must distill to ~1500.
- `motion-design.mdc`: Three philosophies (restraint, polish, experimentation) with duration tables, easing rules, enter/exit recipes, AnimatePresence patterns, reduced motion, performance. ~3000 tokens -- must distill to ~1500.
- `stack.mdc`: Next.js App Router specific conventions (Bun, Biome, shadcn/ui, TypeScript patterns). Must be generalized to framework-agnostic stack detection.

## Open Questions

1. **Exact token count feasibility**
   - What we know: Target ~1500 tokens per agent. Upstream rules are 3000-3500 tokens each.
   - What's unclear: Whether 1500 tokens can capture enough specificity to produce quality output. May need 1200-1800 range.
   - Recommendation: Write at ~1500, measure, and adjust within discretion. Prioritize principles over examples. Use "read STACK.md" references to offload framework-specific content.

2. **STACK.md format for non-web stacks**
   - What we know: STACK.md translation recipes work well for web frameworks (React/Tailwind, Vue/CSS Modules).
   - What's unclear: How to handle non-web stacks (React Native, Flutter, CLI apps). CLI apps may have no relevant UI stack.
   - Recommendation: Stack-conventions agent should detect non-UI stacks and produce a minimal STACK.md with a note: "No UI framework detected. Design agents will use generic CSS/HTML conventions." This gracefully degrades.

3. **Whether stack-conventions agent needs allowed-tools**
   - What we know: It needs Write tool (to write STACK.md) and Read tool (to read DESIGN.md). It's a workflow file, not a command.
   - What's unclear: GSD workflows don't have frontmatter with allowed-tools (that's a command convention). Workflows get their tools from the spawning Task() call.
   - Recommendation: No frontmatter needed. The Phase 3 orchestrator that spawns this agent will configure tools in the Task() call.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual validation (prompt files, not executable code) |
| Config file | None -- markdown prompt files |
| Quick run command | Verify each file exists, is under ~1500 tokens, follows shared XML structure |
| Full suite command | Spawn each agent manually with test DESIGN.md, verify output structure |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| R2.1 | stack-conventions.md exists, reads DESIGN.md Tech Stack, writes STACK.md | manual-only | Verify file at `workflows/design/stack-conventions.md`, check for `<purpose>`, `<context>`, `<rules>`, `<output_format>` sections | No -- Wave 0 |
| R2.2 | ui-design.md exists, covers 8pt grid, 60-30-10, typography, states, <1500 tokens | manual-only | Verify file exists, grep for key terms (8pt, 60-30-10, type scale, component states), count tokens | No -- Wave 0 |
| R2.3 | ux-design.md exists, covers Hick's Law, Peak-end, honest design, <1500 tokens | manual-only | Verify file exists, grep for key terms (Hick, Peak-end, honest design, cognitive load), count tokens | No -- Wave 0 |
| R2.4 | motion-design.md exists, covers duration/easing, reduced-motion, <1500 tokens | manual-only | Verify file exists, grep for key terms (prefers-reduced-motion, ease-out, duration), count tokens | No -- Wave 0 |
| R2.5 | No framework names in ui/ux/motion agents; stack-conventions is the only agent that produces framework-specific output | manual-only | Grep ui-design.md, ux-design.md, motion-design.md for framework names (React, Vue, Tailwind, Framer Motion). Zero matches = pass | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Verify file exists, structure matches shared XML pattern, no framework names in design agents
- **Per wave merge:** Token count all four files. Spawn each agent with a test DESIGN.md and verify output structure
- **Phase gate:** All 5 requirements verified before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `workflows/design/stack-conventions.md` -- does not exist yet
- [ ] `workflows/design/ui-design.md` -- does not exist yet
- [ ] `workflows/design/ux-design.md` -- does not exist yet
- [ ] `workflows/design/motion-design.md` -- does not exist yet
- [ ] `workflows/design/` directory -- needs to be created

Note: This phase produces markdown prompt files, not executable code. Validation is by inspecting structure, token count, framework-name absence, and manual agent spawning with test data.

## Sources

### Primary (HIGH confidence)
- Upstream Design-workflow `ui-design.mdc` -- https://raw.githubusercontent.com/AI-by-design/Design-workflow/main/.cursor/rules/ui-design.mdc -- Full UI design rules (8pt grid, 60-30-10, typography, states, motion, responsive, a11y)
- Upstream Design-workflow `ux-design.mdc` -- https://raw.githubusercontent.com/AI-by-design/Design-workflow/main/.cursor/rules/ux-design.mdc -- Full UX psychology rules (cognitive load, Hick's Law, honest design, forms, errors)
- Upstream Design-workflow `motion-design.mdc` -- https://raw.githubusercontent.com/AI-by-design/Design-workflow/main/.cursor/rules/motion-design.mdc -- Full motion design rules (three philosophies, durations, easing, reduced motion)
- Upstream Design-workflow `stack.mdc` -- https://raw.githubusercontent.com/AI-by-design/Design-workflow/main/.cursor/rules/stack.mdc -- Next.js-specific stack conventions (reference for generalization)
- Phase 1 deliverable `.claude/commands/gsd/design-thinking.md` -- DESIGN.md schema that agents consume
- GSD workflow files at `~/.claude/get-shit-done/workflows/` -- `<purpose>/<context>/<output>` XML convention verified from discuss-phase.md, research-phase.md, execute-plan.md
- Phase 2 CONTEXT.md -- All locked decisions, agent structure, domain boundaries

### Secondary (MEDIUM confidence)
- `.planning/research/ARCHITECTURE.md` -- Agent lifecycle patterns, parallel wave spawning, inline synthesis
- `.planning/research/STACK.md` -- GSD file conventions, agent markdown structure, spawning patterns
- `.planning/research/PITFALLS.md` -- Token budget, stack leakage, domain overlap warnings
- `.planning/research/FEATURES.md` -- Design agent feature expectations, anti-features

### Tertiary (LOW confidence)
- None -- all findings verified against primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- GSD workflow conventions directly inspectable; agent output is markdown files
- Architecture: HIGH -- Shared XML structure verified from multiple GSD workflows; upstream source material fetched and analyzed
- Pitfalls: HIGH -- Token budget, stack leakage, and domain overlap are well-understood prompt engineering challenges; upstream source sizes measured
- Design principles: HIGH -- Upstream Design-workflow rules fetched and analyzed; well-established design principles (8pt grid, 60-30-10, Hick's Law, prefers-reduced-motion)

**Research date:** 2026-03-05
**Valid until:** 2026-04-05 (stable domain -- design principles and GSD conventions unlikely to change in 30 days)
