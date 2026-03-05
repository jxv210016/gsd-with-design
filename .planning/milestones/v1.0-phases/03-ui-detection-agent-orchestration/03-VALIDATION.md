---
phase: 3
slug: ui-detection-agent-orchestration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification + grep (markdown prompt files, not executable code) |
| **Config file** | none — no test runner for prompt files |
| **Quick run command** | `grep -c "keyword_pattern" workflows/design/*.md` |
| **Full suite command** | Manual review of all workflow files + structural grep checks |
| **Estimated runtime** | ~5 seconds (grep checks) |

---

## Sampling Rate

- **After every task commit:** Run `grep` verification of key terms in created files
- **After every plan wave:** Full manual review of workflow logic
- **Before `/gsd:verify-work`:** All workflow files exist with correct structure and cross-references
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | R3.1 | grep | `grep -c "categories" workflows/design/ui-detection.md` | ❌ W0 | ⬜ pending |
| 3-01-02 | 01 | 1 | R3.2 | grep | `grep -c "negative" workflows/design/ui-detection.md` | ❌ W0 | ⬜ pending |
| 3-01-03 | 01 | 1 | R3.3 | grep | `grep -c "ui-phase\|no-ui" workflows/design/ui-detection.md` | ❌ W0 | ⬜ pending |
| 3-02-01 | 02 | 1 | R3.4 | grep | `grep -c "run_in_background" workflows/design/orchestrate-design.md` | ❌ W0 | ⬜ pending |
| 3-02-02 | 02 | 1 | R3.5 | grep | `grep -c "conflict\|resolution\|hierarchy" workflows/design/orchestrate-design.md` | ❌ W0 | ⬜ pending |
| 3-02-03 | 02 | 1 | R3.6 | grep | `grep -c "fail\|partial\|retry" workflows/design/orchestrate-design.md` | ❌ W0 | ⬜ pending |
| 3-02-04 | 02 | 1 | R3.7 | grep | `grep -c "DESIGN.md" workflows/design/orchestrate-design.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `workflows/design/ui-detection.md` — detection logic covering R3.1, R3.2, R3.3
- [ ] `workflows/design/orchestrate-design.md` — orchestration covering R3.4, R3.5, R3.6, R3.7

*No framework install needed — pure markdown prompt files.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Detection threshold accuracy | R3.1 | Keyword matching embedded in prompt logic, not executable | Review ui-detection.md for 6 categories + threshold logic |
| Conflict resolution hierarchy | R3.5 | Synthesis logic in prompt, not testable code | Review orchestrate-design.md for UX > visual, a11y > motion hierarchy |
| Agent failure retry behavior | R3.6 | Task() retry handled by orchestrator prompt logic | Review retry instructions in orchestrate-design.md |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
