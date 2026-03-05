---
phase: 6
slug: update-safety-installation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification + shell script linting (shellcheck) |
| **Config file** | none |
| **Quick run command** | `sh -n install.sh` |
| **Full suite command** | `shellcheck --shell=sh install.sh && sh -n install.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `sh -n install.sh`
- **After every plan wave:** Run `shellcheck --shell=sh install.sh && sh -n install.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 6-01-01 | 01 | 1 | R6.2 | smoke | `cat design-version.json \| grep sha256` | ❌ W0 | ⬜ pending |
| 6-01-02 | 01 | 1 | R6.1 | smoke | `grep "design" .claude/commands/gsd/update.md` | ❌ W0 | ⬜ pending |
| 6-02-01 | 02 | 1 | R6.3 | unit | `shellcheck --shell=sh install.sh` | ❌ W0 | ⬜ pending |
| 6-02-02 | 02 | 1 | R6.6 | unit | `sh -n install.sh` | ❌ W0 | ⬜ pending |
| 6-03-01 | 03 | 1 | R6.4 | smoke | `pwsh -Command "& { . ./install.ps1 -WhatIf }" 2>/dev/null` | ❌ W0 | ⬜ pending |
| 6-04-01 | 04 | 2 | R6.5 | manual-only | Run installer with both global and local GSD present | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `install.sh` — POSIX sh overlay installer (R6.3, R6.6)
- [ ] `install.ps1` — PowerShell overlay installer (R6.4)
- [ ] `design-version.json` schema and generation logic (R6.2)
- [ ] Patched `update.md` with design preservation (R6.1)

*These files are created as part of the phase itself — Wave 0 is the first wave.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GSD update preserves design files | R6.1 | Requires running actual GSD update cycle | 1. Install design fork 2. Run `/gsd:update` 3. Verify all 15+ design files survive |
| Global vs local install prompt | R6.5 | Requires interactive terminal with both install types present | 1. Set up both global and local GSD 2. Run installer 3. Verify prompt appears and both options work |
| PowerShell execution policy handling | R6.4 | Requires Windows with restricted policy | 1. On Windows with restricted policy 2. Run `install.ps1` 3. Verify it handles the policy or shows clear instructions |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
