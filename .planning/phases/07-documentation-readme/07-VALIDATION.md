---
phase: 7
slug: documentation-readme
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual review (documentation-only phase) |
| **Config file** | none |
| **Quick run command** | `test -f README.md && echo "exists"` |
| **Full suite command** | Manual: verify Mermaid rendering, link resolution, file reference accuracy |
| **Estimated runtime** | ~5 seconds (file existence); manual review ~10 min |

---

## Sampling Rate

- **After every task commit:** Run `test -f README.md && echo "exists"`
- **After every plan wave:** Visual inspection of rendered Markdown
- **Before `/gsd:verify-work`:** Full review of rendered README against R7.1 checklist
- **Max feedback latency:** 5 seconds (automated); manual review at wave boundaries

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | R7.1 | manual | Visual: hero + install section present | N/A | ⬜ pending |
| 07-01-02 | 01 | 1 | R7.1 | manual | Visual: Mermaid diagrams render | N/A | ⬜ pending |
| 07-01-03 | 01 | 1 | R7.1 | manual | Visual: commands table complete | N/A | ⬜ pending |
| 07-01-04 | 01 | 1 | R7.1, R7.2 | smoke | `git diff --name-only HEAD~1 | grep -v -E 'README|LICENSE|\.planning' | wc -l` should be 0 | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework needed for a documentation-only phase.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mermaid diagrams render on GitHub | R7.1 | GitHub-specific rendering | Push to branch, view on github.com, verify all 4 diagrams render as flowcharts |
| All file references accurate | R7.1 | Content accuracy | Cross-check every file path mentioned in README against actual repo files |
| Commands table matches frontmatter | R7.1 | Content accuracy | Verify each command name matches its YAML `name:` field |
| No new runtime dependencies | R7.2 | Negative assertion | Confirm only .md and doc files changed in phase commits |
| Uninstall instructions complete | R7.1 | Content accuracy | Verify listed files match actual design layer files |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
