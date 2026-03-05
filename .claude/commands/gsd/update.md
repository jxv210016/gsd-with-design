---
name: gsd:update
description: Update GSD to latest version with design-layer preservation
allowed-tools:
  - Bash
  - AskUserQuestion
  - Read
  - Write
---

<!-- GSD-DESIGN-START: Patched update command — pulls latest design layer from GitHub after GSD update -->

<objective>
Check for GSD updates, install if available, then pull the latest design-layer files from GitHub.

Flow:
1. Run the vanilla GSD update workflow (version check, changelog, install)
2. After GSD update completes, run the design-layer install script from GitHub to overlay the latest design files

The install script handles everything: customization detection, backup prompts, file copy, path rewriting, and checksum generation.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/update.md
</execution_context>

<process>

## Phase 1: UPDATE (vanilla GSD)

Follow the standard update workflow from `@~/.claude/get-shit-done/workflows/update.md` end-to-end.

This includes:
1. Installed version detection (local/global)
2. Latest version checking via npm
3. Version comparison
4. Changelog fetching and extraction
5. Clean install warning display
6. User confirmation
7. Update execution via `npx -y get-shit-done-cc@latest --local` or `--global`
8. Cache clearing

**Follow every step of the update workflow exactly.**

**Important:** If the user is already on the latest GSD version, still proceed to Phase 2 (the design layer may have updates even when GSD core doesn't).

**Important:** If the user cancels the GSD update at the confirmation step, still ask if they want to update the design layer:

```
AskUserQuestion(
  header: "Design Layer",
  question: "GSD update skipped. Still update the design layer from GitHub?",
  options: [
    { label: "Yes", description: "Pull latest design files from GitHub" },
    { label: "No", description: "Keep current design files" }
  ]
)
```

If "No", stop here.

---

## Phase 2: UPDATE DESIGN LAYER (from GitHub)

After GSD update completes (or is skipped), pull the latest design-layer files.

### Step 2.1: Run the install script

```bash
curl -fsSL https://raw.githubusercontent.com/jxv210016/gsd-with-design/main/install.sh | bash
```

The install script automatically:
- Detects the GSD installation directory
- Checks for local customizations (offers backup if found)
- Copies/patches all design files (commands, workflows, design workflows)
- Generates fresh `design-version.json` with checksums
- Verifies all files installed correctly

### Step 2.2: Display completion

Display the following completion banner:

---

## UPDATE COMPLETE

GSD + design layer updated successfully.

**Important:** Restart your Claude Code session to pick up the new version.

---

## Next Up

- `/gsd:progress` -- see where you left off
- `/gsd:discuss-phase N` -- continue with next phase

<sub>`/clear` first -- fresh context window (required after update)</sub>

---

</process>

<!-- GSD-DESIGN-END -->
