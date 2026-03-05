---
phase: 1
slug: design-thinking-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual validation (prompt-based system, no automated test framework applies) |
| **Config file** | None — this is a markdown prompt file, not executable code |
| **Quick run command** | `/gsd:design-thinking` (invoke and verify behavior) |
| **Full suite command** | Run command through all paths: skip, full interview, re-run with existing DESIGN.md |
| **Estimated runtime** | ~5 minutes (manual walkthrough of all paths) |

---

## Sampling Rate

- **After every task commit:** Invoke `/gsd:design-thinking` and verify output manually
- **After every plan wave:** Run all paths (skip, full, re-run) and verify DESIGN.md schema compliance
- **Before `/gsd:verify-work`:** All 4 requirement paths verified
- **Max feedback latency:** ~60 seconds per path verification

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | R1.1 | manual-only | Verify `commands/gsd/design-thinking.md` exists with correct frontmatter | No — W0 | pending |
| 1-01-02 | 01 | 1 | R1.2 | manual-only | Run command, inspect `.planning/DESIGN.md` for all sections + `schema_version: 1` | No — W0 | pending |
| 1-01-03 | 01 | 1 | R1.4 | manual-only | Run command, select Skip, verify no `.planning/DESIGN.md` exists | No — W0 | pending |
| 1-01-04 | 01 | 1 | R1.5 | manual-only | Run command through each validation path (Yes/Edit/Regenerate) | No — W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `commands/gsd/design-thinking.md` — the primary deliverable (does not exist yet)
- [ ] Manual validation checklist for DESIGN.md schema compliance

*Note: This phase produces a markdown prompt file, not executable code. Traditional automated testing does not apply.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Command invocable as `/gsd:design-thinking` | R1.1 | Slash command execution is interactive | Run `/gsd:design-thinking`, verify interview starts |
| DESIGN.md matches schema with all sections | R1.2 | Output varies by user answers | Complete interview, inspect DESIGN.md for: Problem Space (4 sub-headings), Emotional Core (statement + attributes), Solution Space (capabilities + stack), Brand Identity (visual + personality + anti-patterns), `schema_version: 1` |
| Skip produces no DESIGN.md | R1.4 | Requires interactive skip selection | Run command, select Skip, verify `.planning/DESIGN.md` does not exist |
| Validation loop cycles correctly | R1.5 | Requires interactive Edit/Regenerate selection | Run command, at validation step select Edit (verify re-display), then Regenerate (verify fresh output), then Yes (verify commit) |

---

## Validation Sign-Off

- [ ] All tasks have manual verification instructions
- [ ] Sampling continuity: every task has a verification path
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s per path
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
