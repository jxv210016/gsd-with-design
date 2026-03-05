---
phase: 2
slug: design-agent-prompts
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual validation (markdown prompt files, not executable code) |
| **Config file** | None — prompt files are markdown |
| **Quick run command** | `ls workflows/design/*.md && wc -w workflows/design/*.md` |
| **Full suite command** | `bash -c 'for f in workflows/design/ui-design.md workflows/design/ux-design.md workflows/design/motion-design.md; do grep -qE "React|Vue|Tailwind|Framer Motion|Angular|Svelte" "$f" && echo "FAIL: framework name in $f" || echo "PASS: $f"; done'` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `ls workflows/design/*.md && wc -w workflows/design/*.md`
- **After every plan wave:** Run full suite command (framework name check)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | R2.1 | manual-only | `test -f workflows/design/stack-conventions.md && grep -q '<purpose>' workflows/design/stack-conventions.md` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | R2.2 | manual-only | `test -f workflows/design/ui-design.md && grep -q '8pt\|60-30-10' workflows/design/ui-design.md` | ❌ W0 | ⬜ pending |
| 02-01-03 | 01 | 1 | R2.3 | manual-only | `test -f workflows/design/ux-design.md && grep -q 'Hick\|honest design' workflows/design/ux-design.md` | ❌ W0 | ⬜ pending |
| 02-01-04 | 01 | 1 | R2.4 | manual-only | `test -f workflows/design/motion-design.md && grep -q 'prefers-reduced-motion\|ease-out' workflows/design/motion-design.md` | ❌ W0 | ⬜ pending |
| 02-01-05 | 01 | 1 | R2.5 | manual-only | `grep -lE 'React\|Vue\|Tailwind\|Framer Motion' workflows/design/ui-design.md workflows/design/ux-design.md workflows/design/motion-design.md; test $? -ne 0` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `workflows/design/` directory — needs to be created
- [ ] `workflows/design/stack-conventions.md` — stub for R2.1
- [ ] `workflows/design/ui-design.md` — stub for R2.2
- [ ] `workflows/design/ux-design.md` — stub for R2.3
- [ ] `workflows/design/motion-design.md` — stub for R2.4

*Note: This phase produces markdown prompt files, not executable code. Wave 0 creates the directory; actual content is Wave 1.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stack-conventions reads DESIGN.md Tech Stack | R2.1 | Agent prompt logic not executable without spawning | Read file, verify `<context>` references DESIGN.md Tech Stack section |
| UI agent covers 8pt grid, 60-30-10, typography, states | R2.2 | Content quality requires human review | Read file, verify all four topics present in `<rules>` |
| UX agent covers Hick's Law, Peak-end, honest design | R2.3 | Content quality requires human review | Read file, verify cognitive science principles in `<rules>` |
| Motion agent covers duration/easing, reduced-motion | R2.4 | Content quality requires human review | Read file, verify duration table and reduced-motion rules in `<rules>` |
| No framework names in design agents | R2.5 | Grep-verifiable but needs context judgment | Run framework name grep; verify no false positives from principle descriptions |
| Token budget ~1500 per agent | R2.2-R2.4 | Word count proxy only; exact tokens vary | `wc -w` each file; target ~800-1000 words (~1200-1500 tokens) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
