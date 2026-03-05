# Domain Pitfalls

**Domain:** CLI tool fork / design layer integration for agent-based workflow system
**Researched:** 2026-03-05
**Confidence:** MEDIUM (based on established fork/extension patterns and agent system experience; no web verification available)

## Critical Pitfalls

Mistakes that cause rewrites, user abandonment, or upstream incompatibility.

---

### Pitfall 1: Superset Violation — Design Logic Leaking into Non-UI Paths

**What goes wrong:** The fork modifies shared code paths (e.g., `new-project`, `discuss-phase`, `plan-phase`) in ways that change behavior even when no design features are triggered. A non-design user runs vanilla GSD commands and gets unexpected prompts, slower execution, errors referencing DESIGN.md, or different output formatting.

**Why it happens:** The simplest implementation approach is to add design logic inline in existing commands. Conditional checks like `if (hasDesignPhase)` seem safe but introduce subtle differences: different error messages when DESIGN.md is missing, extra file reads that slow cold starts, changed prompt ordering, or new failure modes when design files don't exist.

**Consequences:** Users who want vanilla GSD behavior stop trusting the fork. The core value proposition ("clean superset") is destroyed. Every upstream GSD update becomes a merge conflict minefield.

**Prevention:**
- **Guard clause pattern:** All design integration points must early-return to vanilla behavior when DESIGN.md does not exist. The check is "does DESIGN.md exist?" not "is this a design project?" -- file presence is the single source of truth.
- **Golden path tests:** Create a test suite that runs every GSD command WITHOUT design files present and diffs output against vanilla GSD. Any difference is a regression.
- **Additive-only changes:** Design integration should append to existing command behavior, never modify existing steps. For `new-project`: run the full vanilla flow, THEN add design-thinking as an additional step. For `discuss-phase`: run the vanilla flow, THEN check for UI detection and spawn design agents.
- **Separate entry points:** Where possible, use hook/extension points rather than modifying command files. If GSD commands have no hook system, the modified commands should call the original logic as a function, then add design logic after.

**Detection:** Run vanilla GSD test suite against the fork with no design files present. Any failure = superset violation. Automated CI check: "does removing all files in `agents/design/` and `commands/gsd/design-*` produce identical behavior to upstream GSD?"

**Which phase should address it:** Phase 1 (foundation). Establish the guard clause pattern and golden path tests before writing any design integration code.

---

### Pitfall 2: Agent Context Bloat — DESIGN.md Loaded When Irrelevant

**What goes wrong:** PROJECT.md states "All GSD agents that load PROJECT.md also load DESIGN.md as context." This means EVERY agent -- including research agents, code agents, test agents, documentation agents -- receives the full DESIGN.md content (Problem Space, Emotional Core, Brand Identity). For a backend API phase or a database migration phase, this is pure noise that consumes context window tokens, reduces agent accuracy, and slows execution.

**Why it happens:** Blanket "always load DESIGN.md" is the simplest implementation. It feels safe ("more context is better"). But LLM agents have finite context windows and attention. Irrelevant context degrades output quality -- the agent tries to reconcile brand identity with database schema decisions.

**Consequences:** Non-UI phases run slower and produce lower-quality output. Agents may hallucinate design considerations into backend code ("I've added this color constant to align with the brand identity..."). Token costs increase for every phase, not just UI phases. Users notice degraded performance on phases that have nothing to do with design.

**Prevention:**
- **Conditional context loading:** DESIGN.md should only be loaded by agents when the current phase is detected as UI-relevant. Use the same UI detection logic that triggers design agent spawning.
- **Context tiers:** Tier 1 (always loaded): PROJECT.md. Tier 2 (UI phases only): DESIGN.md, `{phase}-UI.md`. Tier 3 (design agents only): full design craft rules.
- **Summary injection instead of full file:** For phases that are "UI-adjacent" (e.g., API endpoints that serve a UI), inject a 3-line summary of DESIGN.md rather than the full file. Example: "This project's emotional core is [X]. Brand colors: [Y]. See .planning/DESIGN.md for details."
- **Never load design agent output into non-design agents:** The `{phase}-UI.md` files should only be consumed by the implementation agent for that specific phase, not broadcast to all agents.

**Detection:** Monitor token usage per agent. If research agents or backend code agents are consuming significantly more tokens than vanilla GSD, context bloat is the cause. Review agent prompts -- if DESIGN.md appears in a database migration agent's context, that's bloat.

**Which phase should address it:** Phase 2 (agent integration). When implementing "agents load DESIGN.md," make it conditional from day one. Do NOT implement blanket loading and plan to "optimize later."

---

### Pitfall 3: Update Fragility — `gsd:update` Destroying Design Files

**What goes wrong:** When upstream GSD releases updates, the `gsd:update` command overwrites or deletes design-specific files. Users lose their `agents/design/` directory, `commands/gsd/design-*` files, or their DESIGN.md gets wiped. After updating, the fork silently reverts to vanilla GSD.

**Why it happens:** GSD's update mechanism likely does one of: (a) clones fresh and overwrites the install directory, (b) uses `rsync --delete` or equivalent that removes files not in the source, or (c) has a hardcoded file list that doesn't include design files. Any of these destroys fork additions.

**Consequences:** Users lose design configuration after every update. Trust in the update mechanism is destroyed. Users stop updating (missing security/bug fixes) or stop using design features (too fragile). This is the #1 user-facing reliability issue for fork projects.

**Prevention:**
- **Study the actual `gsd:update` mechanism first.** Before writing any code, read the upstream update command and understand exactly how it handles file replacement. This determines the entire preservation strategy.
- **Namespace isolation:** All design files must live in clearly separated directories (`agents/design/`, `commands/gsd/design-*`). Never put design logic inside files that upstream GSD also ships.
- **Update wrapper, not modification:** Override `gsd:update` in the fork to: (1) backup design files, (2) run vanilla update, (3) restore design files, (4) verify integrity. This is resilient to upstream update mechanism changes.
- **Manifest file:** Maintain a `.planning/design-manifest.json` listing all design-specific files and their checksums. Post-update, compare manifest to filesystem. Alert user if files are missing.
- **Pre-update hook:** If GSD supports hooks, add a pre-update hook that copies design files to a temp location. If not, the update wrapper is the hook.

**Detection:** After every update, run a health check: "Do all design files exist? Do their checksums match the manifest?" Alert the user immediately if files are missing rather than failing silently during the next command.

**Which phase should address it:** Phase 3 or 4 (update mechanism). But the NAMESPACE ISOLATION must be established in Phase 1 -- if files are in the wrong places, no update strategy can save them.

---

### Pitfall 4: Installer Cross-Platform Failures

**What goes wrong:** The combined installer (`install.sh` for Mac/Linux, `install.ps1` for Windows) works on the developer's machine but fails on users' machines due to: different shell versions (bash 3 on macOS vs bash 5 on Linux), missing tools (`curl` vs `wget`, `realpath` not available on macOS), path differences (`~/.claude/` expanding differently), permission issues (global install requiring sudo, Windows UAC), or PowerShell execution policy blocking `install.ps1`.

**Why it happens:** Installers are tested on one machine. macOS ships bash 3.2 (from 2007) due to GPL licensing -- bashisms from bash 4+ (associative arrays, `${var,,}`, `|&`) fail silently or with cryptic errors. Windows PowerShell has execution policy restrictions that prevent running unsigned scripts. Path handling differs between platforms (`/` vs `\`, symlink behavior, case sensitivity).

**Consequences:** Users can't install the fork. First impression is "broken." Support burden increases. Users find workarounds that put files in wrong locations, causing later failures.

**Prevention:**
- **POSIX sh, not bash:** Write `install.sh` in POSIX sh (`#!/bin/sh`), not bash. This eliminates bash version issues entirely. Avoid: `[[ ]]` (use `[ ]`), `$()` nesting (use temp vars), arrays, `{a,b}` brace expansion, `<<<` here-strings, `local` keyword (use function scoping carefully).
- **Detect before assume:** Check for `curl` vs `wget` before downloading. Check for `realpath` vs manual path resolution. Check for `mktemp` differences between macOS and Linux.
- **Test on macOS AND Linux AND WSL:** These three cover 95% of users. macOS is the most restrictive (old bash, missing GNU utils, SIP restrictions).
- **PowerShell: handle execution policy explicitly.** The install instructions should tell Windows users to run `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` or use `powershell -ExecutionPolicy Bypass -File install.ps1`. Don't assume the user's policy allows script execution.
- **Provide a one-liner:** `curl -fsSL https://... | sh` is the expected UX. Make sure it works. Test with `set -euo pipefail` to catch silent failures.
- **Global vs local install prompt:** When prompting the user for install location (`~/.claude/` vs `./.claude/`), default to global but support local. Validate the target directory exists and is writable BEFORE copying files. Don't create directories then fail halfway through, leaving a partial install.

**Detection:** CI matrix testing: macOS (Intel + Apple Silicon), Ubuntu LTS, Windows PowerShell 5 + PowerShell 7. If any fails, the installer is broken. Also test: fresh machine with no prior GSD install, upgrade from vanilla GSD, upgrade from previous fork version.

**Which phase should address it:** Late phase (installer is one of the last things to build). But ESTABLISH the file layout convention in Phase 1 so the installer knows what to copy where.

---

### Pitfall 5: Workflow Gate Conflicts — Design Gates Blocking Existing Flow

**What goes wrong:** The design-thinking phase is mandatory in `new-project`. If the design-thinking step fails, errors out, or the user wants to skip it, the entire `new-project` flow is blocked. Similarly, if UI detection false-positives on a non-UI phase, design agents are spawned unnecessarily, adding 30-60 seconds of latency and producing irrelevant `{phase}-UI.md` files that confuse the implementation agent.

**Why it happens:** "Mandatory" design thinking sounds right in theory but creates a hard gate. Users creating a CLI tool, a library, or a backend service don't need design thinking but can't skip it. UI detection heuristics (looking for keywords like "component," "layout," "form") will false-positive on backend concepts (React component testing framework, database layout, form validation logic).

**Consequences:** Users creating non-UI projects are frustrated by a mandatory step they don't need. False-positive UI detection wastes time and produces noise. Users learn to game the detection ("avoid using the word 'component' in phase names") rather than trust it. The fork becomes "that annoying GSD version that makes you do design stuff."

**Prevention:**
- **Mandatory but skippable:** Design thinking runs by default in `new-project`, but a simple "skip" response exits the design phase cleanly without producing DESIGN.md. Downstream, all design features check for DESIGN.md existence. No DESIGN.md = vanilla behavior. The user opted out, and the system respects it.
- **UI detection with confirmation:** When UI detection triggers, show the user: "This phase appears to involve UI work. Spawning design agents. [Proceed/Skip]." Don't silently spawn agents based on keyword heuristics alone.
- **Negative keyword list for UI detection:** Words that indicate NOT-UI even if they contain UI keywords: "unit test," "migration," "CLI," "API endpoint," "database schema," "backend service." Weight negative signals heavily.
- **UI detection tuning data:** Log every detection decision (true positive, false positive, false negative) as a comment in the phase file. After 10+ phases, tune the heuristics.
- **Graceful degradation:** If design agents fail (timeout, error, bad output), the phase continues without design artifacts. Log the failure. Never block the main workflow because a design agent crashed.

**Detection:** Track how often users skip design thinking (high skip rate = it shouldn't be mandatory for that project type). Track UI detection accuracy (false positive rate > 20% = heuristics need tuning). Monitor time-to-phase-completion -- if UI-detected phases take 2x longer than non-UI phases, the design agent overhead is too high.

**Which phase should address it:** Phase 1 (design thinking integration) must implement skip support. Phase 2 (agent integration) must implement UI detection with confirmation and graceful degradation.

---

### Pitfall 6: Over-Engineering the Design Agent System

**What goes wrong:** The three parallel design agents (ui-design, ux-design, motion-design) plus the stack-conventions agent plus the synthesizer that produces `{phase}-UI.md` becomes an elaborate multi-agent orchestration system with complex inter-agent communication, shared state management, conflict resolution between agents, and a sophisticated synthesis pipeline. The system becomes fragile, hard to debug, and impossible to modify.

**Why it happens:** GSD's existing parallel research agent pattern (4 researchers + synthesizer) creates a template that's tempting to replicate and extend. But design agents have different dynamics than research agents: they can genuinely contradict each other (ui-design wants visual density, ux-design wants whitespace, motion-design wants animation on everything). The temptation is to build a conflict resolution system, a priority framework, a voting mechanism. Each layer adds complexity.

**Consequences:** The design agent system becomes the hardest part of the codebase to maintain. Bugs in agent orchestration block all UI phases. The synthesis step becomes a bottleneck -- if it fails, there's no `{phase}-UI.md` and the implementation agent has no design guidance. Adding a fourth design agent (accessibility?) requires modifying the orchestration layer.

**Prevention:**
- **Dumb pipes, not smart orchestration.** Each design agent writes its output to a section in `{phase}-UI.md`. The "synthesizer" is just concatenation with headers, not an LLM call that tries to resolve conflicts. Let the implementation agent handle synthesis -- it has the full context of what it's actually building.
- **Independent agents, no inter-agent communication.** Each design agent reads DESIGN.md and the phase description. It produces recommendations. It never reads another design agent's output. No shared state.
- **Simple parallel execution:** Spawn three agents. Wait for all three. Concatenate outputs. Done. No retry logic, no partial results, no dependency ordering between agents.
- **Graceful partial results:** If one agent fails, the other two outputs are still useful. Don't require all three to succeed. `{phase}-UI.md` with only UX and motion sections is better than no `{phase}-UI.md` at all.
- **Agent prompts are the product.** The quality comes from well-written agent system prompts, not from orchestration sophistication. Spend time on the prompts, not on the plumbing.

**Detection:** If the orchestration code for design agents is more than ~50 lines, it's over-engineered. If adding a new design agent requires modifying more than 2 files, the system is too coupled. If debugging a design agent failure requires understanding the orchestration layer, the abstraction is wrong.

**Which phase should address it:** Phase 2 (agent integration). Implement the simplest possible version first. Concatenation, not synthesis. Independent, not communicating. Add sophistication only when real user feedback demands it.

---

## Moderate Pitfalls

---

### Pitfall 7: DESIGN.md Schema Drift

**What goes wrong:** DESIGN.md starts with a clear schema (Problem Space, Emotional Core, Brand Identity) but evolves organically as users add sections, agents reference fields that don't exist, or the design-thinking command produces different output than agents expect to consume.

**Prevention:**
- Define the DESIGN.md schema in a single source of truth (a template file or schema comment at the top of the design-thinking command).
- Agents should gracefully handle missing sections -- use defaults, not errors.
- Version the schema: include a `schema_version: 1` field in DESIGN.md so future changes can be detected.

**Detection:** If agents produce output referencing DESIGN.md fields that don't exist in the template, schema drift has occurred.

**Which phase should address it:** Phase 1 (design thinking). Lock the schema before agents consume it.

---

### Pitfall 8: Upstream Merge Conflict Accumulation

**What goes wrong:** The fork modifies GSD commands (`new-project`, `discuss-phase`, `plan-phase`, `update`). Every upstream GSD release that touches these files creates merge conflicts. Over time, the fork falls further behind upstream, and merging becomes a multi-day effort.

**Prevention:**
- **Minimize modifications to upstream files.** Prefer wrapper/decorator patterns: rename the upstream command, create a new command that calls the original then adds design logic.
- **Track upstream changes:** Set up a periodic check (weekly) that compares upstream GSD changes against fork modifications. Merge early and often -- small, frequent merges are easier than rare, large ones.
- **Isolate integration points:** The fewer lines changed in upstream files, the fewer conflicts. Aim for single-line additions (e.g., `source design-hook.sh`) rather than multi-line inline modifications.

**Detection:** Track the number of modified upstream files and the diff size against upstream. If either grows over time, merge debt is accumulating.

**Which phase should address it:** Phase 1 (foundation). The integration architecture determines merge pain for the project's lifetime.

---

### Pitfall 9: {phase}-UI.md Stale State

**What goes wrong:** A `{phase}-UI.md` is generated during `discuss-phase` but the phase scope changes during `plan-phase` or implementation. The design guidance is now stale -- it references components that were removed, ignores components that were added, or recommends patterns for a different scope.

**Prevention:**
- Regenerate `{phase}-UI.md` at the start of `plan-phase`, not just `discuss-phase`. The plan phase has the final scope.
- Include a staleness warning in `{phase}-UI.md`: "Generated for phase scope: [hash of phase description]. If scope has changed, re-run design agents."
- Make regeneration easy: a single command or automatic detection of scope changes.

**Detection:** Compare the phase description hash stored in `{phase}-UI.md` with the current phase description. Mismatch = stale.

**Which phase should address it:** Phase 2 (agent integration). Build regeneration into the plan-phase flow.

---

### Pitfall 10: Design Thinking Producing Unusable Output

**What goes wrong:** The design-thinking phase asks the user questions and produces DESIGN.md, but the output is either too vague to be actionable ("the emotional core is quality") or too prescriptive for the stack-agnostic goal ("use Tailwind with these specific classes"). Design agents then consume poor input and produce poor output.

**Prevention:**
- **Structured prompts with examples.** The design-thinking command should show examples of good emotional core statements ("Users should feel confident that their data is safe, like handing keys to a trusted friend") vs bad ones ("quality, speed, reliability").
- **Validation step:** After DESIGN.md is generated, show it to the user and ask for confirmation. "Does this capture your product's emotional direction? [Yes/Edit/Regenerate]."
- **Separate concerns:** Brand Identity (colors, typography, tone) is concrete and verifiable. Emotional Core is abstract and harder to validate. Focus validation effort on Emotional Core since it drives all downstream agent behavior.

**Detection:** If design agents produce generic output that could apply to any project, the DESIGN.md input is too vague. If agents produce framework-specific output for a generic project, DESIGN.md is too prescriptive.

**Which phase should address it:** Phase 1 (design thinking). The quality of DESIGN.md determines the quality of everything downstream.

---

## Minor Pitfalls

---

### Pitfall 11: Agent Prompt Size Explosion

**What goes wrong:** Design agent system prompts grow over time as edge cases are added. Each agent's prompt exceeds 2000 tokens, consuming significant context window before any user content is processed.

**Prevention:** Cap agent prompts at 1500 tokens. Use reference files instead of inline rules. "See `.planning/DESIGN.md` for brand direction" is better than embedding the brand direction in the prompt.

**Which phase should address it:** Phase 2 (agent creation). Set the budget before writing prompts.

---

### Pitfall 12: Motion Design Agent Over-Animating

**What goes wrong:** The motion-design agent recommends animations for everything. Page transitions, button hovers, list renders, form validation, loading states -- all animated. Implementation agent follows these recommendations and the resulting UI is distracting, slow on low-end devices, and inaccessible.

**Prevention:** The motion-design agent prompt must include a "restraint" principle: "Every animation must have a functional purpose (direct attention, show continuity, indicate state change). Decorative animation is an anti-pattern." Also: always include `prefers-reduced-motion` handling in every recommendation.

**Which phase should address it:** Phase 2 (agent prompts). Bake restraint into the prompt, not as an afterthought.

---

### Pitfall 13: Global vs Local Install Confusion

**What goes wrong:** User installs globally (`~/.claude/`), then also installs locally (`./.claude/`) in a project. The two installations have different versions, different design files, and different behavior. User can't figure out which one is active.

**Prevention:** The installer should detect existing installations and warn. "Found existing GSD-with-Design installation at ~/.claude/. Installing locally will override global settings for this project. Continue? [Y/n]." Document the precedence rules clearly.

**Which phase should address it:** Installer phase. Include detection logic from the start.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Design thinking integration | Superset violation (P1), workflow gate blocking (P5), unusable output (P10) | Guard clause pattern, skip support, structured prompts with validation |
| Agent creation & integration | Context bloat (P2), over-engineering (P6), prompt size explosion (P11) | Conditional loading, dumb pipes, token budgets |
| Update mechanism | File destruction (P3) | Backup-restore wrapper, manifest file, namespace isolation |
| Installer | Cross-platform failures (P4), install confusion (P13) | POSIX sh, CI matrix testing, conflict detection |
| UI detection | False positives blocking flow (P5), stale state (P9) | Confirmation prompt, negative keywords, scope hash tracking |
| Upstream sync | Merge conflicts (P8) | Minimal upstream file modifications, wrapper pattern |

## Pre-Implementation Checklist

Before writing any integration code, verify:

- [ ] You have read the upstream `gsd:update` command source and understand its file handling
- [ ] You have a vanilla GSD test suite that can run against the fork as a regression gate
- [ ] The DESIGN.md schema is defined and documented before any agent consumes it
- [ ] The guard clause pattern (DESIGN.md existence check) is established as a project convention
- [ ] Agent context loading is conditional, not blanket

## Sources

- Pattern analysis based on established software engineering practices for fork maintenance, agent system design, cross-platform installer development, and CLI tool extension patterns
- Project requirements from `.planning/PROJECT.md`
- Confidence: MEDIUM -- findings are based on well-established patterns but were not verified against current web sources (web search unavailable during this research session)
