---
phase: 5
slug: auxiliary-commands-quick-reference
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (markdown prompt files — not executable code) |
| **Config file** | none |
| **Quick run command** | Invoke `/gsd:design-ui` and `/gsd:design-stack` in Claude Code |
| **Full suite command** | N/A |
| **Estimated runtime** | ~30 seconds (manual invocation) |

---

## Sampling Rate

- **After every task commit:** Visual review of command file structure and content
- **After every plan wave:** Manual invocation of both commands
- **Before `/gsd:verify-work`:** Both commands invoke without error, output includes expected sections
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 5-01-01 | 01 | 1 | R5.1 | manual-only | Invoke `/gsd:design-ui` | W0 | pending |
| 5-01-02 | 01 | 1 | R5.2 | manual-only | Invoke `/gsd:design-stack` | W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. No test framework needed for markdown prompt files.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| design-ui outputs UI/UX/motion reference | R5.1 | Slash commands are markdown prompts — no test framework for prompt correctness | 1. Invoke `/gsd:design-ui` 2. Verify output includes brand identity, UI patterns, motion specs 3. Verify graceful fallback if DESIGN.md missing |
| design-stack outputs stack conventions | R5.2 | Slash commands are markdown prompts — no test framework for prompt correctness | 1. Invoke `/gsd:design-stack` 2. Verify output includes tech stack, git conventions, framework recipes 3. Verify graceful fallback if STACK.md missing |

---

## Validation Sign-Off

- [ ] All tasks have manual verification instructions
- [ ] Sampling continuity: manual review after each task commit
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
