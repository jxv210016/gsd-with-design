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

<objective>
Run a conversational design thinking interview that produces `.planning/DESIGN.md` -- the foundation for all downstream design agents and UI-phase guidance.

**What it does:**
1. Guides the user through four design thinking sections: Problem Space, Emotional Core, Solution Space, and Brand Identity
2. Produces a structured `.planning/DESIGN.md` with `schema_version: 1`
3. Validates the output with the user in an unlimited edit/regenerate loop until approved

**How it fits:**
- Standalone: invoke as `/gsd:design-thinking` at any time
- Embedded: Phase 4 integrates this into `/gsd:new-project` (after questioning, before research)
- Downstream: Phase 2+ design agents consume DESIGN.md for UI/UX/motion guidance

**Output:** `.planning/DESIGN.md` -- a structured design brief that all design agents read as their primary context
</objective>

<process>

## Step 0: Check for existing DESIGN.md

Read `.planning/DESIGN.md`.

**If it exists:**

Use AskUserQuestion:
- header: "DESIGN.md"
- question: "You already have a DESIGN.md. What would you like to do?"
- options:
  - "Update -- revise specific parts"
  - "View -- show me what's there"
  - "Replace -- start fresh"

Handle each choice:

- **Update:** Display the current DESIGN.md content to the user. Then ask in plain text: "What would you like to change?" The user describes changes in natural language. Update only the relevant sections of DESIGN.md. Then jump to Step 7 (validation loop).

- **View:** Display the full DESIGN.md content. Then use AskUserQuestion:
  - header: "Next"
  - question: "What would you like to do with this DESIGN.md?"
  - options:
    - "Update -- revise specific parts"
    - "Replace -- start fresh"
  Handle "Update" as above. Handle "Replace" by continuing to Step 1.

- **Replace:** Continue to Step 1 for a full re-interview from scratch.

**If it does not exist:** Continue to Step 1.

---

## Step 1: Skip offer (first interaction for new interviews)

Use AskUserQuestion:
- header: "Design"
- question: "Design thinking helps ground your project in user needs and emotional direction. Skip to use vanilla GSD, or continue?"
- options:
  - "Continue -- let's think about design"
  - "Skip -- I'll use vanilla GSD"

**If "Skip":** Output a brief message: "Design thinking skipped. No DESIGN.md created -- downstream behavior will be identical to vanilla GSD." Exit the command. Do NOT write any file. Done.

**If "Continue":** Proceed to Step 2.

---

## Step 2: Load PROJECT.md context

Read `.planning/PROJECT.md` if it exists. Extract:
- Project name and description
- Tech stack (framework, styling, libraries)
- Target users / audience
- Constraints

Store these as context to inform interview questions:
- If PROJECT.md specifies target users, don't re-ask -- weave them into Problem Space questions as pre-filled context
- If PROJECT.md specifies tech stack, don't re-ask -- pre-fill in Solution Space and let user confirm or adjust
- If PROJECT.md doesn't exist, proceed with all questions open

---

## Step 3: Design thinking interview -- Problem Space

Guide the user through Problem Space. Each question should build on prior answers -- this is a conversation with a thinking partner, not a form.

**Question 1: Target Users**

Use AskUserQuestion:
- header: "Users"
- question: If PROJECT.md has target users: "Your project targets [extracted users]. What specific problem are they facing?" Otherwise: "Who experiences the problem your product solves?"
- options: Pre-fill from PROJECT.md if available, or use generic persona categories like:
  - "Developers / engineers"
  - "End users / consumers"
  - "Teams / organizations"

When the user selects "Other", follow up in plain text -- do NOT use another AskUserQuestion.

**Question 2: Core Problem**

Use AskUserQuestion:
- header: "Problem"
- question: "What specific problem does your product solve?\n\nGood: 'Developers waste 30 min per PR reviewing inconsistent UI decisions'\nBad: 'Bad design'"
- options: Build on the user's target users answer. Offer 2-3 problem framings relevant to their audience, e.g.:
  - "A workflow problem -- something takes too long"
  - "A quality problem -- output is inconsistent"
  - "A knowledge problem -- people don't know what to do"

Follow up in plain text to get the specific problem statement if the user selects a broad category.

**Question 3: Pain Points**

Use AskUserQuestion:
- header: "Pain Points"
- question: "What's broken about how people solve this problem today? What are the current alternatives and why do they fall short?"
- options: Derive from the user's problem statement. Offer 2-3 specific pain point directions, e.g.:
  - "Too slow / manual"
  - "Too expensive / complex"
  - "Poor quality / inconsistent results"

Follow up in plain text for specifics. Capture both current alternatives and their shortcomings.

---

## Step 4: Design thinking interview -- Emotional Core

This is the most critical section. Users default to vague adjectives without guidance. The inline examples are essential.

**Question 1: Primary Emotional Statement**

Use AskUserQuestion:
- header: "Emotion"
- question: "How should using your product FEEL? Not what it does -- how it makes people feel.\n\nExamples of what we're looking for:\n- Bad: 'modern and clean' (too vague -- every product claims this)\n- Good: 'calm confidence -- like a trusted advisor who never rushes you'\n- Good: 'playful momentum -- like a pinball machine that rewards curiosity'\n\nThink about the emotional experience, not features."
- options:
  - "Calm and trustworthy"
  - "Energetic and bold"
  - "Precise and expert"

When the user selects any option (including "Other"), follow up in plain text to refine their answer into a specific feeling-statement with a simile or metaphor.

**Question 2: Supporting Attributes**

Use AskUserQuestion:
- header: "Attributes"
- question: "What 3-4 words describe the personality behind that feeling? These become the guardrails for every design decision."
- options: Curate based on their emotional statement. For example:
  - "Trustworthy, patient, expert, approachable"
  - "Bold, playful, surprising, confident"
  - "Minimal, precise, quiet, focused"

If the user selects "Other", follow up in plain text to collect their custom attributes.

---

## Step 5: Design thinking interview -- Solution Space

**Question 1: Key Capabilities**

Use AskUserQuestion:
- header: "Capabilities"
- question: "What are the 2-3 most important things v1 must do? Focus on capabilities, not features."
- options: Derive from the problem and pain points discussed earlier. Offer 2-3 capability directions relevant to their specific problem.

Follow up in plain text for details on each capability.

**Question 2: Tech Stack**

If PROJECT.md has tech stack information:

Use AskUserQuestion:
- header: "Stack"
- question: "PROJECT.md says [extracted tech stack]. Keep this, or change?"
- options:
  - "Keep -- that's right"
  - "Change -- I want different tech"

If "Keep", use PROJECT.md stack. If "Change", follow up in plain text to ask about framework, styling approach, and key libraries.

If PROJECT.md does NOT have tech stack:

Use AskUserQuestion:
- header: "Stack"
- question: "What tech stack are you building with? Framework, styling approach, and any key libraries."
- options: Common stacks like:
  - "React + Tailwind"
  - "Next.js + CSS Modules"
  - "Vue + UnoCSS"

Follow up in plain text for any details not covered by their selection.

---

## Step 6: Design thinking interview -- Brand Identity

**Question 1: Color Mood**

Use AskUserQuestion:
- header: "Color Mood"
- question: "What color temperature fits your product's emotional direction?"
- options:
  - "Warm (oranges, reds, earth tones) -- inviting, human"
  - "Cool (blues, greens, grays) -- professional, calm"
  - "Neutral (black, white, silver) -- minimal, modern"

**Question 2: Typography Feel**

Use AskUserQuestion:
- header: "Typography"
- question: "What typographic feel matches your brand?"
- options:
  - "Geometric (Inter, Helvetica) -- modern, clean"
  - "Humanist (Source Sans, Lato) -- friendly, approachable"
  - "Monospace (JetBrains Mono, Fira) -- technical, precise"

**Question 3: Visual Density**

Use AskUserQuestion:
- header: "Density"
- question: "How dense should the interface feel?"
- options:
  - "Spacious -- lots of breathing room"
  - "Balanced -- moderate whitespace"
  - "Dense -- information-rich, compact"

**Question 4: Brand Personality**

Ask in plain text (not AskUserQuestion -- this needs freeform response):

"Two final questions about your brand's voice:
1. How does this brand speak? (e.g., confident but not arrogant? friendly but not casual? direct but not cold?)
2. What must it NEVER feel like? (e.g., never corporate, never condescending, never chaotic)"

---

## Step 7: Generate DESIGN.md and validate

Assemble the complete DESIGN.md from interview answers using this exact schema:

```markdown
---
schema_version: 1
generated: {today's date}
---

# DESIGN.md

## Problem Space

### Target Users
- {from interview}

### Core Problem
- {from interview}

### Current Alternatives
- {from interview}

### Pain Points
- {from interview}

## Emotional Core

### Primary Emotional Statement
{One sentence -- the feeling-statement from interview}

### Supporting Attributes
- {Attribute 1}
- {Attribute 2}
- {Attribute 3}
- {Attribute 4}

## Solution Space

### Key Capabilities
- {Capability 1}
- {Capability 2}
- {Capability 3}

### Tech Stack
- **Framework:** {from interview or PROJECT.md}
- **Styling:** {from interview or PROJECT.md}
- **Key Libraries:** {from interview or PROJECT.md}

## Brand Identity

### Visual Direction
- **Color Mood:** {warm / cool / neutral}
- **Typography Feel:** {geometric / humanist / monospace}
- **Visual Density:** {spacious / balanced / dense}

### Brand Personality
- {How the brand speaks}
- {Tone description}

### Anti-Patterns
- {What this brand must NEVER feel like}
```

Display the complete DESIGN.md to the user. Then enter the validation loop:

Use AskUserQuestion:
- header: "Direction"
- question: "Does this capture your direction?"
- options:
  - "Yes -- looks good"
  - "Edit -- I want to change something"
  - "Regenerate -- rewrite from my answers"

Handle each choice:

- **Yes:** Write the DESIGN.md to `.planning/DESIGN.md` using the Write tool. Done.

- **Edit:** Ask in plain text: "What would you like to change?" The user describes changes in natural language. Update only the relevant sections. Re-display the full updated DESIGN.md. Loop back to the validation AskUserQuestion. This loop is unlimited -- continue until the user selects "Yes".

- **Regenerate:** Keep all interview answers but produce a fresh interpretation of the DESIGN.md -- different phrasing, different emphasis, possibly different structure within the schema. Re-display the full regenerated DESIGN.md. Loop back to the validation AskUserQuestion. This loop is unlimited -- continue until the user selects "Yes".

</process>

<success_criteria>
- `.planning/DESIGN.md` exists with `schema_version: 1` in frontmatter
- All 4 top-level sections present: Problem Space, Emotional Core, Solution Space, Brand Identity
- All sub-headings present: Target Users, Core Problem, Current Alternatives, Pain Points, Primary Emotional Statement, Supporting Attributes, Key Capabilities, Tech Stack, Visual Direction, Brand Personality, Anti-Patterns
- User explicitly approved the DESIGN.md via "Yes" in the validation loop
- Skip path produces no file (absence of DESIGN.md = skip state)
- Re-run path offers Update/View/Replace when DESIGN.md already exists
- Validation loop supports unlimited Edit/Regenerate cycles
</success_criteria>
