---
name: gsd:design-ui
description: Quick reference for UI/UX/motion craft standards
argument-hint: ""
allowed-tools:
  - Read
---

<objective>
This is a read-only reference command. Output ONLY the reference content. Do NOT add project-specific analysis, next-step suggestions, or commentary beyond the reference.

Display a consolidated UI/UX/motion quick-reference card -- scannable tables and checklists covering spacing, color, typography, component states, UX rules, motion defaults, and accessibility.
</objective>

<process>

## Step 1: Load project context

Read `.planning/DESIGN.md`.

**If it exists:** Extract:
- Brand Identity > Visual Direction: Color Mood, Typography Feel, Visual Density
- Emotional Core: Primary Emotional Statement, Supporting Attributes

**If it does not exist:** Use this note wherever project-specific values would appear:
> No DESIGN.md found. Showing generic defaults. Run `/gsd:design-thinking` to personalize these standards.

Read these three design agent workflow files for the authoritative rules:
- `workflows/design/ui-design.md`
- `workflows/design/ux-design.md`
- `workflows/design/motion-design.md`

---

## Step 2: Output the reference card

Output the following sections using tables and checklists only. No prose paragraphs.

---

### Your Project

| Property              | Value                                              |
| --------------------- | -------------------------------------------------- |
| Color Mood            | {from DESIGN.md or "not set (default)"}            |
| Typography Feel       | {from DESIGN.md or "not set (default)"}            |
| Visual Density        | {from DESIGN.md or "not set (default)"}            |
| Primary Emotion       | {from DESIGN.md or "not set (default)"}            |
| Supporting Attributes | {from DESIGN.md or "not set (default)"}            |

---

### Spacing (8pt Grid)

| Token  | Value | Use                          |
| ------ | ----- | ---------------------------- |
| `xs`   | 4px   | Inline icon gaps             |
| `sm`   | 8px   | Tight component padding      |
| `md`   | 16px  | Standard component padding   |
| `lg`   | 24px  | Section gaps                 |
| `xl`   | 32px  | Card padding                 |
| `2xl`  | 48px  | Section margins              |
| `3xl`  | 64px  | Page-level spacing           |

> **Density interpretation:** If Visual Density is "dense", bias toward smaller tokens. If "spacious", bias toward larger tokens. If "balanced" or not set, use values as listed.

---

### Color (60-30-10)

**Distribution:**

| Share | Role        | Applied To                     |
| ----- | ----------- | ------------------------------ |
| 60%   | Dominant    | Backgrounds, large surfaces    |
| 30%   | Secondary   | Cards, surfaces, containers    |
| 10%   | Accent      | Interactive elements, CTAs     |

**Constraints:**
- [ ] Max 3 hues
- [ ] No pure black (#000) or pure white (#fff)
- [ ] 4.5:1 contrast minimum for body text
- [ ] 3:1 contrast minimum for large text (18px+ or 14px+ bold)

---

### Typography Scale

| Property          | Rule                                                        |
| ----------------- | ----------------------------------------------------------- |
| Max typefaces     | 2 (one heading, one body)                                   |
| Scale ratio       | Geometric=1.200, Humanist=1.250, Monospace=1.125            |
| Body line-height  | 1.5                                                         |
| Heading line-height | 1.2 - 1.3                                                |
| Body weight       | 400                                                         |
| Heading weight    | 600                                                         |

> Use the ratio matching your Typography Feel from DESIGN.md. If not set, default to 1.250.

---

### Component States Checklist

Every interactive component must handle:

- [ ] Default
- [ ] Hover
- [ ] Focus (visible focus ring)
- [ ] Active
- [ ] Disabled
- [ ] Loading
- [ ] Error
- [ ] Empty

**Height scale:** 32px (small) | 36px (compact) | 40px (default) | 48px (large)

---

### UX Rules

| Rule                    | Specification                                                  |
| ----------------------- | -------------------------------------------------------------- |
| Hick's Law              | Max 5-7 options per choice, ~4 chunks working memory           |
| Primary action          | One primary action per view                                    |
| Feedback timing         | 100ms minimum response; 2s+ needs progress indicator           |
| Error format            | What happened + Why + What to do next                          |
| Touch targets           | 44x44px minimum                                                |

**Honest Design Checklist (non-negotiable):**
- [ ] Pricing visible before commitment
- [ ] Cancellation path discoverable
- [ ] No confirmshaming
- [ ] No fake scarcity or urgency
- [ ] Toggles unambiguous (on/off clearly distinguishable)

---

### Motion Defaults

| Interaction Type | Duration    | Easing   |
| ---------------- | ----------- | -------- |
| Micro            | 100-150ms   | ease-out |
| Dropdowns        | 150-200ms   | ease-out |
| Panels           | 250-350ms   | ease-out |
| Pages            | 300-500ms   | ease-out |

| Rule                     | Value                                    |
| ------------------------ | ---------------------------------------- |
| Enter easing             | ease-out                                 |
| Exit easing              | ease-in                                  |
| Safe to animate          | opacity, transform, filter ONLY          |
| Stagger                  | First 4-6 items, 0.05s delay             |
| Linear easing            | ONLY for progress bars                   |

> **prefers-reduced-motion: ALWAYS respect (non-negotiable).** Remove all motion or replace with opacity-only crossfade.

---

### Accessibility

- [ ] 4.5:1 contrast ratio for body text
- [ ] 3:1 contrast ratio for large text
- [ ] 44x44px minimum touch targets
- [ ] Visible focus rings on all interactive elements
- [ ] `prefers-reduced-motion` ALWAYS respected
- [ ] No information conveyed by color alone

</process>
