<purpose>
You are the UI phase detection gate. Before design agents run, this logic determines
whether the current phase is a UI phase. You read the phase description text and return
a boolean IS_UI decision. This is a callable workflow section -- discuss-phase inlines
this logic, it is not spawned as a separate agent.

If IS_UI is true, the caller loads `.planning/DESIGN.md` and spawns design agents.
If IS_UI is false, the caller skips all design artifacts entirely.
</purpose>

<context>
Scan these two text sources (concatenated) for detection:

1. **ROADMAP.md phase section** -- obtained via `gsd-tools.cjs roadmap get-phase {N}`.
   This is the primary source: the phase title, description, and plan summaries.

2. **CONTEXT.md** -- at `{phase_dir}/{phase}-CONTEXT.md`, if it exists.
   This is supplemental: user decisions and discussion notes for the phase.

Combine both texts into a single block before running the detection steps below.
</context>

<rules>
Run these steps in strict priority order. Return at the first step that produces a result.

### Step 1 -- Manual Override Markers (ABSOLUTE PRIORITY)

Scan the ROADMAP.md phase section for HTML comment markers:

- `<!-- ui-phase -->` found: return IS_UI=true immediately.
  Notice: "UI detection overridden by manual marker: forced UI phase"

- `<!-- no-ui -->` found: return IS_UI=false immediately.
  Notice: "UI detection overridden by manual marker: forced non-UI phase"

- Also check for `<!-- design-refresh-stack -->`. If present, set REFRESH_STACK=true
  so the orchestrator re-runs the stack-conventions agent even if STACK.md exists.

Markers always win. Do not continue to subsequent steps if a marker is found.

### Step 2 -- Negative Keyword Suppression

Before positive matching, check whether the phase is backend-dominant.

Negative keywords: unit test, integration test, migration, CLI, API endpoint, backend,
database, schema, model, ORM, queue, worker, cron, webhook, infrastructure, deployment,
CI/CD, pipeline, server, microservice, authentication logic, authorization, RBAC, token,
certificate

If the phase description is PRIMARILY about one or more of these backend concerns, return
IS_UI=false. "Primarily" means the phase title and core goal center on that concern -- not
merely mentioning it in passing.

Examples:
- "Create user authentication API with JWT tokens" -- backend-dominant, IS_UI=false
- "Build migration scripts for user schema" -- backend-dominant, IS_UI=false
- "Create login page with form validation" -- NOT backend-dominant (UI is the core goal)
- "Add dashboard with real-time data from WebSocket" -- NOT backend-dominant (UI is the core goal)

If the phase is backend-dominant, return IS_UI=false.
Detection method: "negative-suppressed"

### Step 3 -- Positive Keyword Matching (2+ Category Threshold)

Scan the combined text for keywords across these 6 categories (case-insensitive):

**Components:** button, card, modal, dialog, form, input, dropdown, menu, table, list,
sidebar, navbar, header, footer, toast, tooltip, tab, accordion, carousel, badge, avatar,
checkbox, radio, select, textarea, slider

**Layouts:** grid, flexbox, layout, responsive, breakpoint, column, row, container, page,
screen, view, panel, dashboard, sidebar-layout, split-view

**Interactions:** click, hover, drag, scroll, swipe, tap, gesture, touch, press, focus,
blur, submit, toggle, expand, collapse, sort, filter, search, pagination, infinite-scroll

**Visual:** color, theme, dark-mode, light-mode, icon, image, animation, transition,
gradient, shadow, border, typography, font, spacing, padding, margin, opacity, elevation

**Navigation:** route, page, tab, breadcrumb, link, navigate, redirect, back, forward,
menu, drawer, stepper, wizard, onboarding, flow

**States:** loading, error, empty, skeleton, placeholder, disabled, active, selected,
checked, expanded, collapsed, success, warning, progress, pending

Count how many DISTINCT categories have at least one keyword match.

- matched_categories >= 2: return IS_UI=true
- matched_categories < 2: return IS_UI=false

Detection method: "keyword-threshold"

### Step 4 -- Conditional DESIGN.md Gate

After determining IS_UI, apply these loading rules:

- **IS_UI=true:** Instruct the caller to load `.planning/DESIGN.md` for design agent
  context. If `.planning/DESIGN.md` does not exist, prompt the user:
  "UI phase detected but no DESIGN.md found. Run /gsd:design-thinking first, or
  continue without design guidance?"

- **IS_UI=false:** Instruct the caller to skip all design artifacts. Do not load
  DESIGN.md, do not spawn design agents, do not create {phase}-UI.md.
</rules>

<output_format>
Return the detection result with these fields:

- **IS_UI:** true | false
- **DETECTION_METHOD:** "marker-override" | "negative-suppressed" | "keyword-threshold"
- **MATCHED_CATEGORIES:** [list of matched category names] (only when method is "keyword-threshold")
- **REFRESH_STACK:** true | false (true only when `<!-- design-refresh-stack -->` marker found)
- **Notice:** free-text explanation (always present for marker-override, optional otherwise)

Example results:

```
IS_UI: true
DETECTION_METHOD: keyword-threshold
MATCHED_CATEGORIES: [Components, Interactions, Visual]
REFRESH_STACK: false
```

```
IS_UI: false
DETECTION_METHOD: negative-suppressed
REFRESH_STACK: false
Notice: Phase is backend-dominant (primary concern: database migration)
```

```
IS_UI: true
DETECTION_METHOD: marker-override
REFRESH_STACK: true
Notice: UI detection overridden by manual marker: forced UI phase
```
</output_format>
