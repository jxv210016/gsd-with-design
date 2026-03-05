# Feature Landscape

**Domain:** Design-system-integrated AI coding tools / Design thinking in developer workflows
**Researched:** 2026-03-05
**Confidence:** MEDIUM (based on PROJECT.md context, upstream repo descriptions, and training data on the AI-assisted design-to-code ecosystem through early 2025; web verification unavailable)

## Table Stakes

Features users expect from a design-integrated AI coding fork. Missing any of these makes the fork feel incomplete or not worth switching to.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Design thinking phase in project init** | The entire value proposition -- design before code. Without this, it's just GSD with extra files | Medium | Must produce DESIGN.md with Problem Space, Emotional Core, Solution Space, Brand Identity. Mandatory in `new-project`, not opt-in |
| **DESIGN.md as persistent context** | Design decisions are useless if agents don't read them. Every GSD agent that loads PROJECT.md must also load DESIGN.md | Low | Simple file-loading addition to agent prompts. Low effort, high leverage |
| **UI phase auto-detection** | Manual flags defeat the purpose. If a phase involves components, layouts, screens, forms, navigation, etc., design agents should fire automatically | Medium | Pattern matching on phase descriptions. False negatives are worse than false positives -- better to spawn design agents unnecessarily than to miss a UI phase |
| **Parallel design agent spawning** | GSD already uses parallel agent waves for research. Design agents (ui-design, ux-design, motion-design) must follow the same pattern -- not sequential, not single-agent | Medium | Three parallel agents is the right number. UI craft, UX psychology, and motion are genuinely distinct expertise areas. Combining them into one agent produces shallow output |
| **{phase}-UI.md synthesis artifact** | Raw output from three agents is noise. The orchestrator must synthesize into one actionable document per phase | Medium | This is where the real value lands. Synthesis means conflict resolution (when ui-design wants visual density but ux-design wants breathing room), not just concatenation |
| **Clean superset behavior** | Non-UI phases must produce zero design artifacts. Someone who never does UI work must have identical GSD behavior | Low | Gate everything behind UI phase detection. No new files, no extra agent runs, no behavioral changes for backend/infra/data phases |
| **Standalone design-thinking command** | Users need to re-run design thinking on existing projects (pivot, rebrand, new understanding of users) without starting over | Low | `gsd:design-thinking` as a standalone command that regenerates DESIGN.md |
| **Quick reference commands** | Design rules are useless if developers can't quickly check them mid-implementation | Low | `gsd:design-ui` for craft standards, `gsd:design-stack` for conventions. These are read-only reference surfaces |
| **Update safety for design files** | If `gsd:update` destroys design agents or commands, the fork is unusable in practice | Low | Clear namespace separation (`commands/gsd/design-*`, `agents/design/`) and explicit preservation logic |
| **Stack-agnostic design agents** | The fork must work for React, Vue, Svelte, vanilla HTML, mobile, etc. -- not just Next.js | Medium | Stack conventions agent discovers stack from design-thinking answers rather than hardcoding. Design rules (8pt grid, color ratios) are framework-independent; only implementation recipes need stack awareness |

## Differentiators

Features that set this fork apart from both vanilla GSD and from other design-code bridge tools. Not expected, but these are what make it worth using.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Emotional Core as architectural constraint** | Most design systems enforce visual rules but not emotional intent. Mapping every UI decision back to the product's emotional promise ("this should feel calm and trustworthy" constrains color palette, animation speed, information density) produces more coherent products | Low | This is a prompt engineering win, not a code complexity win. The Emotional Core section of DESIGN.md becomes a persistent filter for all design agent output |
| **UX psychology rules enforcement** | Hick's Law (fewer choices = faster decisions), Peak-end rule (last impressions matter most), Fitts's Law (target size vs distance), cognitive load limits -- these are rarely codified in design system tooling | Medium | The ux-design agent applies these as constraints, not suggestions. "This form has 14 fields -- Hick's Law says split into 3 steps" is more useful than "consider reducing field count" |
| **Motion design as first-class concern** | Animation is usually an afterthought. Having a dedicated motion-design agent that enforces principles (purposeful not decorative, respect reduced-motion, duration/easing consistency, entrance/exit choreography) produces noticeably better UIs | Medium | Framer Motion recipes are a good default, but the agent should also produce CSS animation guidance for non-React stacks |
| **Honest design pattern enforcement** | Dark patterns are a deliberate anti-goal. The ux-design agent should flag manipulative patterns (confirmshaming, hidden costs, forced continuity, roach motels) and suggest ethical alternatives | Low | This is a differentiator because most tools are amoral about patterns. Taking a stance on honest design is both ethical and practical (reduces churn, improves trust) |
| **Phase-scoped design artifacts** | Design guidance that's scoped to exactly what you're building right now (this phase's components) rather than a monolithic design system document. Each phase gets its own `{phase}-UI.md` with relevant rules, not the entire design system | Medium | This is the GSD integration advantage -- phase decomposition means design guidance is contextual, not overwhelming |
| **Cross-agent conflict resolution** | When the ui-design agent says "use a modal" but the ux-design agent says "modals break flow, use inline expansion" and the motion-design agent says "if modal, here's the animation" -- the synthesizer makes the call, documenting the tradeoff | High | This is where most multi-agent systems fail. Naive concatenation produces contradictory guidance. The orchestrator synthesis step must detect conflicts and resolve them with rationale |
| **60-30-10 color rule enforcement** | Concrete, measurable color distribution rule (60% dominant, 30% secondary, 10% accent) that design agents can verify against component implementations | Low | Simple but effective. Most codebases drift into color chaos because there's no enforcement mechanism |
| **8pt grid enforcement** | Spacing, sizing, and layout based on multiples of 8px. Catches arbitrary values (padding: 13px) and suggests grid-aligned alternatives | Low | Easy to implement, immediately improves visual consistency. The ui-design agent can flag non-compliant values |
| **Component state completeness checking** | For every interactive component, verify that all states are addressed: default, hover, focus, active, disabled, loading, error, empty, skeleton | Medium | Developers routinely forget edge states. A design agent that systematically checks "what happens when this is loading? empty? errored?" catches gaps before they reach production |
| **Design-to-implementation traceability** | Each design decision in `{phase}-UI.md` traces back to a principle in DESIGN.md. "Use soft shadows because Emotional Core says 'approachable'" -- not just "use soft shadows" | Low | Prompt engineering, not code complexity. Makes design decisions reviewable and debatable rather than arbitrary |

## Anti-Features

Features to explicitly NOT build. These are tempting but wrong for this project.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Visual design tool / canvas / WYSIWYG** | This is a prompt-engineering layer, not a design tool. Building visual editing is a completely different product with massive scope | Stay in the text/markdown artifact world. Design agents produce written guidance, not visual mockups |
| **Figma/Sketch import/export** | Integration with design tools creates a dependency chain and maintenance burden that dwarfs the core project. Also implies pixel-perfect translation which is a fundamentally different problem | Design agents produce implementation-ready guidance in prose and code snippets. Designers use their tools; this fork helps developers build well |
| **Component library / pre-built UI kit** | Shipping components couples the fork to a specific framework and creates a maintenance nightmare. Also conflicts with stack-agnostic goal | Agents recommend component patterns and produce code recipes inline. The developer builds the components; agents ensure they're well-built |
| **Design token management system** | Token systems (Style Dictionary, design tokens spec) are valuable but are their own ecosystem. Adding token management to GSD creates scope creep | Design agents can reference and recommend token patterns in their guidance, but token infrastructure is the project's concern, not the fork's |
| **Automated accessibility testing** | a11y testing tools already exist (axe, lighthouse, pa11y). Reimplementing them poorly would be worse than not having them | UX design agent should include accessibility guidance in its output (semantic HTML, ARIA, keyboard nav, contrast ratios) as design rules, not as a testing framework |
| **Design system documentation generator** | Storybook, Docusaurus, etc. already do this well. GSD is not a documentation platform | {phase}-UI.md is the documentation -- it's phase-scoped, contextual, and generated fresh each time |
| **Image/icon generation** | AI image generation is a separate domain with different models and infrastructure | Design agents can recommend icon libraries, image treatment rules, and visual direction in prose |
| **Persistent design system database** | Storing design decisions in a database or config system adds infrastructure complexity for marginal benefit | DESIGN.md and {phase}-UI.md are the persistence layer. Markdown files in `.planning/` are the right level of infrastructure |
| **Real-time collaboration features** | Multi-user editing, commenting, approval workflows -- these are product management features, not design guidance features | GSD is a single-developer productivity tool. Design artifacts are git-tracked markdown files that work with existing collaboration tools (PRs, code review) |
| **Design linting CI/CD pipeline** | Tempting to add automated design rule checking to CI, but this creates a hard dependency and maintenance burden | Design rules are enforced at generation time by the agents. The developer is the enforcement mechanism during implementation. Keep it human-in-the-loop |

## Feature Dependencies

```
Design Thinking Phase (DESIGN.md generation)
  --> DESIGN.md as persistent context (agents must load it)
  --> All downstream design agent features depend on DESIGN.md existing

UI Phase Auto-Detection
  --> Parallel Design Agent Spawning (detection triggers spawning)
    --> {phase}-UI.md Synthesis (agents produce output, orchestrator synthesizes)
      --> Plan Phase Integration (plan-phase loads {phase}-UI.md)

Stack Conventions Agent
  --> Stack-Agnostic Design Agents (conventions agent discovers stack, informs other agents)

Quick Reference Commands (gsd:design-ui, gsd:design-stack)
  --> Independent, no dependencies. Can ship at any time.

Update Safety
  --> Must ship with initial release. Not a "later" feature.

Standalone design-thinking command
  --> Depends on Design Thinking Phase implementation existing
```

## MVP Recommendation

### Must ship in v1 (without these, the fork has no reason to exist):

1. **Design thinking phase in `new-project`** -- the foundational value proposition
2. **DESIGN.md generation and loading** -- design decisions must persist and inform all agents
3. **UI phase auto-detection** -- seamless integration, no manual flags
4. **Three parallel design agents** (ui-design, ux-design, motion-design) -- the craft enforcement core
5. **{phase}-UI.md synthesis** -- actionable per-phase design guidance
6. **Clean superset behavior** -- non-UI phases unchanged
7. **Update safety** -- users must be able to update GSD without losing design files

### Ship soon after v1 (high value, low risk):

8. **Quick reference commands** (`gsd:design-ui`, `gsd:design-stack`) -- developer convenience
9. **Standalone `gsd:design-thinking` command** -- re-run design phase on existing projects
10. **Emotional Core as architectural constraint** -- prompt engineering refinement
11. **Honest design pattern enforcement** -- ethical differentiator

### Defer (valuable but complex, ship when core is solid):

12. **Cross-agent conflict resolution** -- requires iterating on real synthesis output to get right
13. **Component state completeness checking** -- needs real-world testing to calibrate sensitivity
14. **UX psychology rules enforcement** -- needs tuning to avoid being preachy or overly prescriptive

## Domain Landscape: What Exists Today

### Design-to-Code Tools (adjacent, not competitors)

The landscape of design-integrated coding tools falls into several categories, none of which do what this fork does:

**Figma-to-Code generators** (Locofy, Anima, TeleportHQ): Convert visual designs to code. Different problem entirely -- they start from visual artifacts, this fork starts from problem understanding. These tools produce code; this fork produces design guidance that informs code.

**AI code generators with UI focus** (v0 by Vercel, bolt.new, Lovable): Generate entire UIs from prompts. They produce output fast but without design thinking -- no emotional core, no UX psychology, no systematic craft rules. The result looks good on first glance but lacks coherence across a product.

**Design system tools** (Storybook, Chromatic, Style Dictionary): Manage and document existing design systems. They assume the design system already exists. This fork helps generate the design direction that a design system would then codify.

**Cursor/Claude rules for design** (Design-workflow, various .cursorrules collections): The closest analog. Static rule files that guide AI coding assistants. Design-workflow is specifically the upstream for this fork. The gap: these are passive rules, not active agents. They inform but don't orchestrate.

### What This Fork Uniquely Does

The gap in the market is: **no tool combines design thinking (problem space, emotional core) with active multi-agent design enforcement during implementation phases.** Existing tools either:
- Generate UI without design thinking (v0, bolt.new)
- Apply design rules passively without phase awareness (Cursor rules)
- Manage existing design systems without generating design direction (Storybook)
- Convert visual designs without understanding intent (Figma-to-code)

This fork occupies the space between "understand the problem" and "build the solution" with active, phase-scoped, multi-agent design guidance.

## Sources

- PROJECT.md (primary source for project requirements and architecture decisions)
- Design-workflow repository description and structure (referenced in PROJECT.md)
- GSD repository description and agent patterns (referenced in PROJECT.md)
- Training data on design system tooling ecosystem (Figma-to-code, v0, Storybook, design tokens, Cursor rules) -- MEDIUM confidence, not independently verified for this research session
- Training data on UX psychology principles (Hick's Law, Fitts's Law, Peak-end rule) -- HIGH confidence, well-established academic domain
- Training data on visual design rules (8pt grid, 60-30-10, component states) -- HIGH confidence, industry-standard practices
