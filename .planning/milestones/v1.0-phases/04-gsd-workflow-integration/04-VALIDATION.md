---
phase: 4
slug: gsd-workflow-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification + grep smoke tests (prompt-based system) |
| **Config file** | none |
| **Quick run command** | `grep -c "GSD-DESIGN-START" <patched-file>` |
| **Full suite command** | Manual walkthrough of each patched command |
| **Estimated runtime** | ~5 seconds (smoke), ~10 minutes (manual) |

---

## Sampling Rate

- **After every task commit:** Run `grep -c "GSD-DESIGN-START" <file>` to verify markers present
- **After every plan wave:** Check all three patched files have markers and correct guard clauses
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds (smoke tests)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | R4.1 | smoke | `grep -c "GSD-DESIGN-START" workflows/new-project.md` | W0 | pending |
| 04-01-02 | 01 | 1 | R1.3 | smoke | `grep "design-thinking" workflows/new-project.md` | W0 | pending |
| 04-02-01 | 02 | 1 | R4.2 | smoke | `grep "GSD-DESIGN-START" workflows/discuss-phase.md` | W0 | pending |
| 04-02-02 | 02 | 1 | R4.2 | smoke | `grep "ui-detection" workflows/discuss-phase.md` | W0 | pending |
| 04-03-01 | 03 | 1 | R4.3 | smoke | `grep "GSD-DESIGN-START" workflows/plan-phase.md` | W0 | pending |
| 04-03-02 | 03 | 1 | R4.3 | smoke | `grep "DESIGN.md\|UI.md" workflows/plan-phase.md` | W0 | pending |
| 04-04-01 | all | 1 | R4.4 | smoke | `grep -A2 "GSD-DESIGN-START" workflows/*.md` shows DESIGN.md guard | W0 | pending |
| 04-05-01 | 02 | 1 | R4.5 | manual-only | Run discuss-phase on non-UI phase, verify no UI.md | N/A | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] Patched `workflows/new-project.md` with design thinking injection markers
- [ ] Patched `workflows/discuss-phase.md` with UI detection injection markers
- [ ] Patched `workflows/plan-phase.md` with design context loading markers

*All three files are created by the plans themselves — Wave 0 is the implementation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Design thinking offered after questioning in new-project | R1.3 | Interactive prompt flow | Run `/gsd:new-project`, verify design thinking offer appears after PROJECT.md creation |
| Non-UI phases skip design agents | R4.5 | Requires running discuss-phase on non-UI phase | Run `/gsd:discuss-phase` on a backend phase, verify no {phase}-UI.md |
| Auto mode skips design thinking | R4.1 | Requires auto mode execution | Run `/gsd:new-project --auto`, verify no design thinking prompt |
| Guard clause on all paths | R4.4 | Requires testing with/without DESIGN.md | Run commands with DESIGN.md absent, verify vanilla behavior |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
