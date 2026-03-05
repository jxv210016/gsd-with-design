# Phase 6: Update Safety & Installation - Research

**Researched:** 2026-03-05
**Domain:** Shell scripting (POSIX sh / PowerShell), overlay installation, GSD update lifecycle
**Confidence:** HIGH

## Summary

Phase 6 creates the infrastructure that lets the design fork survive GSD upstream updates and be installed fresh on any machine. The GSD update process (`/gsd:update`) performs a **clean wipe-and-replace** of `commands/gsd/` and `get-shit-done/` directories. Without intervention, this destroys all design-layer files: the three `design-*` commands, the six `workflows/design/` files, and the three patched command shims and workflow files. The fork must (1) patch the update command to back up and restore design files around the wipe, (2) provide a version tracking mechanism with checksums so user customizations can be detected, and (3) provide cross-platform installers that overlay design files onto an existing GSD installation.

The project repo already contains all 15 design-layer files in their correct relative paths. The installer's job is to copy these files to the user's GSD installation directory (`~/.claude/` for global, `./.claude/` for local), creating directories as needed. The patched workflow files overwrite their vanilla GSD counterparts. The `design-version.json` file tracks which version of the design fork is installed and SHA-256 checksums of every design file, enabling detection of user customizations before overwriting.

**Primary recommendation:** Create a patched `update.md` command shim that wraps the vanilla GSD update with design-file backup/restore. Write `install.sh` in strict POSIX sh (no bashisms) using `shasum -a 256` for checksums (available on macOS and Linux). Write `install.ps1` for PowerShell with `Get-FileHash -Algorithm SHA256` and process-scoped execution policy bypass.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| R6.1 | `/gsd:update` modified to preserve `commands/gsd/design-*` and `workflows/design/` | GSD update wipes `commands/gsd/` and `get-shit-done/` -- patched update.md must back up design files before `npx` install, then restore after |
| R6.2 | `design-version.json` tracks fork version + file checksums for user customization detection | Use SHA-256 via `shasum -a 256` (POSIX) / `Get-FileHash` (PowerShell); JSON structure with version, files map, and per-file checksums |
| R6.3 | `install.sh` (Mac/Linux) -- overlay installer: verify base GSD, copy design layer, patch commands via markers | POSIX sh script; verify GSD VERSION file exists; copy 15 files to correct locations; generate design-version.json |
| R6.4 | `install.ps1` (Windows/PowerShell) -- same overlay logic, handle execution policy | PowerShell script with process-scoped `Set-ExecutionPolicy Bypass`; same file copy logic; `Get-FileHash` for checksums |
| R6.5 | Installer supports global (`~/.claude/`) and local (`./.claude/`) with user prompt | Detect existing installations by checking VERSION file in both locations; prompt user to choose if both exist |
| R6.6 | POSIX sh for `install.sh` (not bash) -- macOS bash 3.2 compatibility | macOS ships bash 3.2 (2007); POSIX sh avoids array syntax, `[[ ]]`, `local` in functions, process substitution, etc. |
</phase_requirements>

## Standard Stack

### Core

This phase creates shell scripts and a JSON metadata file. No libraries or npm packages are involved.

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| POSIX sh | N/A | `install.sh` interpreter | Universal on macOS/Linux; avoids bash 3.2 limitations |
| PowerShell | 5.1+ / 7.x | `install.ps1` interpreter | Built into Windows; 5.1 ships with Windows 10/11 |
| `shasum` | 6.x | SHA-256 checksums on Mac/Linux | Ships with macOS (via Perl); available on most Linux distros |
| `sha256sum` | GNU coreutils | SHA-256 checksums on Linux fallback | Standard on Linux if `shasum` unavailable |
| `Get-FileHash` | PowerShell built-in | SHA-256 checksums on Windows | No external dependency |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `node` + `gsd-tools.cjs` | GSD init, commit, config operations | Only for the patched update.md command (not in installers) |
| `npx` | GSD upstream update execution | Called by the patched update.md (same as vanilla) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `shasum -a 256` | `md5` / `md5sum` | SHA-256 is more standard for integrity checking; MD5 is deprecated for security use. `shasum` is available on macOS and most Linux. |
| POSIX sh | bash | macOS ships bash 3.2 (2007 vintage); bashisms would break. POSIX sh is the safe choice. |
| PowerShell script | Batch (.bat/.cmd) | PowerShell has hash utilities built in, proper string handling, and is the modern Windows scripting standard. Batch would require external tools for checksums. |

## Architecture Patterns

### Design-Layer File Inventory

The complete set of files the installer must manage:

```
DESIGN-ONLY FILES (9 files -- new, not in vanilla GSD):
  .claude/commands/gsd/design-thinking.md
  .claude/commands/gsd/design-ui.md
  .claude/commands/gsd/design-stack.md
  workflows/design/motion-design.md
  workflows/design/orchestrate-design.md
  workflows/design/stack-conventions.md
  workflows/design/ui-design.md
  workflows/design/ui-detection.md
  workflows/design/ux-design.md

PATCHED GSD FILES (6 files -- modified vanilla GSD files):
  .claude/commands/gsd/new-project.md      (command shim with design execution_context)
  .claude/commands/gsd/discuss-phase.md    (command shim with design execution_context)
  .claude/commands/gsd/plan-phase.md       (command shim -- unchanged from vanilla?)
  workflows/new-project.md                 (workflow with GSD-DESIGN-START/END block)
  workflows/discuss-phase.md               (workflow with GSD-DESIGN-START/END block)
  workflows/plan-phase.md                  (workflow with GSD-DESIGN-START/END block)

UPDATE COMMAND (1 file -- patched to preserve design files):
  .claude/commands/gsd/update.md           (command shim wrapping vanilla update)
```

### Installation Target Mapping

```
Source (repo)                           -> Target (install dir)
.claude/commands/gsd/design-*.md        -> {INSTALL_DIR}/commands/gsd/design-*.md
.claude/commands/gsd/new-project.md     -> {INSTALL_DIR}/commands/gsd/new-project.md (overwrites vanilla)
.claude/commands/gsd/discuss-phase.md   -> {INSTALL_DIR}/commands/gsd/discuss-phase.md (overwrites vanilla)
.claude/commands/gsd/plan-phase.md      -> {INSTALL_DIR}/commands/gsd/plan-phase.md (overwrites vanilla)
.claude/commands/gsd/update.md          -> {INSTALL_DIR}/commands/gsd/update.md (overwrites vanilla)
workflows/design/*.md                   -> {INSTALL_DIR}/get-shit-done/workflows/design/*.md (new dir)
workflows/new-project.md               -> {INSTALL_DIR}/get-shit-done/workflows/new-project.md (overwrites vanilla)
workflows/discuss-phase.md             -> {INSTALL_DIR}/get-shit-done/workflows/discuss-phase.md (overwrites vanilla)
workflows/plan-phase.md                -> {INSTALL_DIR}/get-shit-done/workflows/plan-phase.md (overwrites vanilla)
design-version.json                    -> {INSTALL_DIR}/get-shit-done/design-version.json (new file)

Where INSTALL_DIR = ~/.claude (global) or ./.claude (local)
```

### Pattern 1: Overlay Installation

**What:** Copy design files on top of an existing GSD installation without touching non-design files.
**When to use:** Always -- this is the core installation pattern.

**Steps:**
1. Verify base GSD exists (check `{INSTALL_DIR}/get-shit-done/VERSION`)
2. Check for existing design installation (`design-version.json`)
3. If upgrading: compare checksums to detect user customizations
4. Copy design-only files (create `workflows/design/` dir if needed)
5. Copy patched GSD files (overwrite vanilla versions)
6. Generate `design-version.json` with current checksums
7. Report success

### Pattern 2: Update-Safe Backup/Restore

**What:** The patched `update.md` backs up design files before GSD's clean install, then restores them after.
**When to use:** Every time `/gsd:update` runs.

**Flow:**
1. Back up all design files to a temp directory
2. Run vanilla GSD update (`npx get-shit-done-cc@latest`)
3. Restore design-only files from backup
4. Re-apply patched command shims and workflow files from backup
5. Verify restoration with checksum comparison
6. Clean up temp directory

**Critical detail:** The GSD update wipes `commands/gsd/` entirely. The design fork's `update.md` command shim itself lives in `commands/gsd/`. After the wipe, the design `update.md` is gone -- replaced by vanilla. This means the backup/restore logic must complete within a single command execution. The patched `update.md` should:
- Store all backup/restore logic inline (not in a separate script that could be wiped)
- Perform the backup BEFORE calling `npx` install
- Perform the restore AFTER `npx` install completes
- Re-copy the patched `update.md` itself as part of restoration

### Pattern 3: design-version.json Schema

**What:** JSON file tracking fork version and per-file SHA-256 checksums.

```json
{
  "version": "1.0.0",
  "installed_at": "2026-03-05T12:00:00Z",
  "gsd_base_version": "1.22.4",
  "files": {
    "commands/gsd/design-thinking.md": "sha256:abc123...",
    "commands/gsd/design-ui.md": "sha256:def456...",
    "commands/gsd/design-stack.md": "sha256:ghi789...",
    "commands/gsd/new-project.md": "sha256:jkl012...",
    "commands/gsd/discuss-phase.md": "sha256:mno345...",
    "commands/gsd/plan-phase.md": "sha256:pqr678...",
    "commands/gsd/update.md": "sha256:stu901...",
    "get-shit-done/workflows/design/motion-design.md": "sha256:...",
    "get-shit-done/workflows/design/orchestrate-design.md": "sha256:...",
    "get-shit-done/workflows/design/stack-conventions.md": "sha256:...",
    "get-shit-done/workflows/design/ui-design.md": "sha256:...",
    "get-shit-done/workflows/design/ui-detection.md": "sha256:...",
    "get-shit-done/workflows/design/ux-design.md": "sha256:...",
    "get-shit-done/workflows/new-project.md": "sha256:...",
    "get-shit-done/workflows/discuss-phase.md": "sha256:...",
    "get-shit-done/workflows/plan-phase.md": "sha256:..."
  }
}
```

**Purpose:**
- `version`: Design fork version (semantic versioning)
- `installed_at`: Timestamp of last install
- `gsd_base_version`: Which GSD version this was installed over
- `files`: Map of relative paths to SHA-256 checksums. Used to detect if user has customized any design files before an upgrade overwrites them.

### Pattern 4: User Customization Detection

**What:** Before overwriting, compare installed file checksums against `design-version.json`. If they differ, the user has customized the file.

**Flow:**
1. Read `design-version.json` from existing installation
2. For each file to overwrite: compute current checksum, compare to stored checksum
3. If match: safe to overwrite (user hasn't modified)
4. If mismatch: warn user, offer to back up their customized version

### Anti-Patterns to Avoid

- **Relying on the GSD `gsd-local-patches` system:** The GSD backup system detects modifications to GSD files, but it doesn't know about design-layer files. The design fork needs its own preservation mechanism.
- **Using bash arrays or `[[ ]]` in install.sh:** These are bashisms that break on POSIX sh.
- **Hardcoding `~/.claude/` without checking other runtime dirs:** GSD supports `.config/opencode`, `.opencode`, `.gemini` in addition to `.claude`. The installer should follow GSD's multi-runtime detection pattern.
- **Forgetting to restore the patched `update.md` after a GSD update:** If only design-only files are restored but the patched update.md is not, the next update will lose everything.
- **Running `set -e` without understanding traps:** POSIX sh `set -e` interacts poorly with command substitution in some shells. Use explicit error checking instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SHA-256 checksums | Custom hash function | `shasum -a 256` (macOS/Linux) / `Get-FileHash` (PowerShell) | Standard tools, already available |
| JSON parsing in sh | `sed`/`awk` JSON parser | Simple `grep`/`sed` for the flat key-value structure OR generate JSON with `printf` | Full JSON parsing in POSIX sh is fragile; design-version.json is flat enough for line-based extraction |
| GSD version detection | Custom VERSION file reader | Copy GSD's own detection pattern from `update.md` | GSD already handles local vs global, multi-runtime detection |
| File copying with permissions | Custom permission handling | `cp -p` (preserves permissions) | Standard POSIX flag |

**Key insight:** The installers are simple file copiers with verification. The complexity is in the update.md patching (backup/restore lifecycle) and the POSIX sh constraints, not in sophisticated algorithms.

## Common Pitfalls

### Pitfall 1: Update.md Self-Destruction
**What goes wrong:** The GSD update wipes `commands/gsd/`, which includes the patched `update.md` itself. After the wipe, the design-aware update behavior is gone.
**Why it happens:** The design fork's `update.md` lives in the same directory that GSD's clean install wipes.
**How to avoid:** The patched `update.md` must perform ALL backup/restore in a single execution pass. It backs up design files (including itself) to a temp dir BEFORE calling `npx`, then restores everything (including itself) AFTER `npx` completes. The workflow file backing the update command (`get-shit-done/workflows/update.md`) is also wiped -- the patched `update.md` must carry the full design-preservation logic inline or reference a workflow file that's backed up and restored.
**Warning signs:** After a GSD update, design commands are missing and the update command reverts to vanilla behavior.

### Pitfall 2: POSIX sh Bashisms
**What goes wrong:** `install.sh` fails on macOS default sh or dash (common on Ubuntu).
**Why it happens:** Common bashisms slip in: `[[ ]]` instead of `[ ]`, arrays, `local` keyword (not POSIX), `$(< file)` instead of `$(cat file)`, `{start..end}` brace expansion.
**How to avoid:** Use `#!/bin/sh` shebang. Test with `dash` or `shellcheck --shell=sh`. Use `[ ]` for tests, no arrays, `cat` for file reading.
**Warning signs:** "syntax error" on macOS or Ubuntu with dash.

### Pitfall 3: Checksum Tool Availability
**What goes wrong:** `shasum` is missing on some minimal Linux distributions. `sha256sum` is missing on macOS.
**Why it happens:** Different systems ship different tools.
**How to avoid:** Try `shasum -a 256` first; fall back to `sha256sum`; error if neither found. Both produce the same hash, just different output format (shasum: `hash  filename`, sha256sum: `hash  filename`).
**Warning signs:** "command not found" error during install.

### Pitfall 4: PowerShell Execution Policy Blocking install.ps1
**What goes wrong:** Windows users can't run `install.ps1` because execution policy is set to Restricted (the default).
**Why it happens:** Windows PowerShell default blocks script execution.
**How to avoid:** Document the recommended invocation: `powershell -ExecutionPolicy Bypass -File install.ps1`. Alternatively, have the script self-invoke with bypass if it detects it's blocked. Include clear error message with instructions.
**Warning signs:** "cannot be loaded because running scripts is disabled" error.

### Pitfall 5: Local vs Global Path Confusion
**What goes wrong:** Design files installed to wrong location. User has global GSD but installer writes to local, or vice versa.
**Why it happens:** GSD supports both `~/.claude/` (global) and `./.claude/` (local) installations. The installer needs to match.
**How to avoid:** Follow GSD's own detection pattern (check local first, then global). If both exist, prompt user. Default to global if no existing installation detected.
**Warning signs:** Design commands not found after installation. Or design files end up in a project-local `.claude/` when user expected global.

### Pitfall 6: Patched Workflow Files Contain Hardcoded Paths
**What goes wrong:** The patched command shims (e.g., `new-project.md`) contain absolute paths like `@/Users/jayvanam/.claude/...` that only work on the developer's machine.
**Why it happens:** Phase 4 created the patched files with the developer's actual paths in execution_context references.
**How to avoid:** The installer must post-process patched command shims to replace the developer's home directory path with the installing user's actual home directory. OR the command shims should use relative `@` references. Check existing patched files for hardcoded paths.
**Warning signs:** Design commands fail on other users' machines because `@` references point to a non-existent path.

### Pitfall 7: Forgetting the Workflow Files
**What goes wrong:** Only command shims are installed, but workflow files (the actual logic) are not. Commands reference workflow files that don't exist.
**Why it happens:** The split between `commands/gsd/` (shims) and `get-shit-done/workflows/` (logic) is easy to miss.
**How to avoid:** The installer must copy BOTH command shims AND workflow files. The file inventory has 16 files across two directory trees.
**Warning signs:** Commands load but fail with "file not found" for workflow references.

## Code Examples

### POSIX sh Checksum Function

```sh
# Source: standard POSIX sh pattern
compute_checksum() {
  file="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | cut -d' ' -f1
  else
    echo "ERROR: No SHA-256 tool found (need shasum or sha256sum)" >&2
    exit 1
  fi
}
```

### POSIX sh Installation Detection

```sh
# Source: adapted from GSD update.md detection pattern
detect_gsd_install() {
  # Check local first
  for dir in .claude .config/opencode .opencode .gemini; do
    if [ -f "./$dir/get-shit-done/VERSION" ]; then
      echo "local:./$dir"
      return 0
    fi
  done
  # Check global
  for dir in .claude .config/opencode .opencode .gemini; do
    if [ -f "$HOME/$dir/get-shit-done/VERSION" ]; then
      echo "global:$HOME/$dir"
      return 0
    fi
  done
  echo "none"
  return 1
}
```

### PowerShell Execution Policy Handling

```powershell
# Source: Microsoft docs on execution policies
# Self-elevate execution policy for this process only
if ((Get-ExecutionPolicy -Scope Process) -eq 'Restricted') {
    Write-Host "Setting execution policy for this session..."
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}

# Checksum function
function Get-DesignFileHash {
    param([string]$FilePath)
    (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLower()
}
```

### design-version.json Generation (POSIX sh)

```sh
# Source: custom pattern for this project
generate_version_json() {
  install_dir="$1"
  version="$2"
  gsd_version=$(cat "$install_dir/get-shit-done/VERSION" 2>/dev/null || echo "unknown")
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  printf '{\n'
  printf '  "version": "%s",\n' "$version"
  printf '  "installed_at": "%s",\n' "$timestamp"
  printf '  "gsd_base_version": "%s",\n' "$gsd_version"
  printf '  "files": {\n'

  first=true
  for file in $DESIGN_FILES; do
    full_path="$install_dir/$file"
    if [ -f "$full_path" ]; then
      hash=$(compute_checksum "$full_path")
      if [ "$first" = true ]; then
        first=false
      else
        printf ',\n'
      fi
      printf '    "%s": "sha256:%s"' "$file" "$hash"
    fi
  done

  printf '\n  }\n'
  printf '}\n'
}
```

### Update.md Backup/Restore Pattern

```markdown
<!-- In the patched update.md command -->

## Design-Layer Preservation

**Before running the GSD update:**

1. Create temp backup directory
2. Back up all design files:
   - commands/gsd/design-*.md
   - commands/gsd/update.md (the patched version -- this file)
   - commands/gsd/new-project.md (patched shim)
   - commands/gsd/discuss-phase.md (patched shim)
   - commands/gsd/plan-phase.md (patched shim)
   - get-shit-done/workflows/design/*.md
   - get-shit-done/workflows/new-project.md (patched workflow)
   - get-shit-done/workflows/discuss-phase.md (patched workflow)
   - get-shit-done/workflows/plan-phase.md (patched workflow)
   - get-shit-done/design-version.json
3. Read design-version.json for metadata preservation

**After GSD update completes:**

4. Restore all backed-up files to their original locations
5. Re-create workflows/design/ directory if wiped
6. Verify restoration by checking file existence
7. Clean up temp directory
8. Log: "Design layer preserved through update"
```

## State of the Art

| Aspect | Current State | Impact on Phase 6 |
|--------|---------------|-------------------|
| GSD update mechanism | Clean wipe of `commands/gsd/` and `get-shit-done/` via `npx` reinstall | Design files in these dirs WILL be destroyed without intervention |
| GSD `gsd-local-patches` backup | Backs up modified GSD files before update, offers `/gsd:reapply-patches` after | Design-ONLY files are NOT detected by this system (it only backs up modified GSD files). Patched GSD files would be backed up, but the restore is manual. |
| GSD multi-runtime support | Detects `.claude`, `.config/opencode`, `.opencode`, `.gemini` directories | Installer must follow same pattern for cross-runtime compatibility |
| macOS bash version | 3.2.57 (2007) -- missing associative arrays, `[[ ]]` in strict mode, mapfile, etc. | POSIX sh is mandatory for macOS compatibility |
| PowerShell default policy | Restricted on Windows 10/11 consumer editions | Installer must handle or document bypass |

## Open Questions

1. **Should the update.md be a full workflow or a command shim?**
   - What we know: Vanilla GSD `update.md` is a command shim that references `workflows/update.md`. But the design fork's update logic must survive the wipe of `get-shit-done/workflows/`.
   - What's unclear: Can the backup/restore logic live in the command shim alone (it's just a prompt, not executable code), or does it need a companion workflow file that's also backed up?
   - Recommendation: The patched `update.md` command shim should contain ALL design-preservation instructions inline. Since the command shim is a prompt file (not executable code), the backup/restore is performed by Claude reading the prompt and executing bash commands. The command shim survives as long as it's backed up and restored. Include the backup/restore bash snippets directly in the command's `<process>` section.

2. **Hardcoded paths in patched command shims**
   - What we know: The existing patched shims (new-project.md, discuss-phase.md, plan-phase.md) contain absolute paths like `@/Users/jayvanam/.claude/get-shit-done/workflows/...`.
   - What's unclear: Whether these need to be rewritten per-user, or if the `@` reference system resolves relative paths.
   - Recommendation: The installer should use `sed` to replace the developer's home directory with the installing user's `$HOME` in all patched command shims. Alternatively, investigate whether `@$HOME/.claude/...` or environment variable references work in GSD's `@` reference system.

3. **Where does design-version.json live?**
   - What we know: It needs to survive GSD updates.
   - What's unclear: If placed in `get-shit-done/`, it gets wiped. If placed elsewhere, it may be orphaned.
   - Recommendation: Place it in `get-shit-done/design-version.json` (logical location alongside `VERSION`). The backup/restore cycle in the patched update.md will preserve it. The installer regenerates it fresh on each install anyway.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual verification + shell script linting |
| Config file | N/A |
| Quick run command | `sh -n install.sh` (syntax check) + `shellcheck --shell=sh install.sh` |
| Full suite command | Manual: run install.sh on fresh GSD install, run update, verify design files survive |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| R6.1 | update.md preserves design files through GSD update | manual-only | `grep "design" .claude/commands/gsd/update.md` (verify design-preservation section exists) | Wave 0 |
| R6.2 | design-version.json created with checksums | smoke | `cat design-version.json \| grep sha256` (verify checksum entries) | Wave 0 |
| R6.3 | install.sh works on Mac/Linux | smoke | `sh -n install.sh && echo "syntax OK"` | Wave 0 |
| R6.4 | install.ps1 works on Windows/PowerShell | smoke | `pwsh -Command "& { . ./install.ps1 -WhatIf }" 2>/dev/null` (if pwsh available) | Wave 0 |
| R6.5 | Global vs local install prompt | manual-only | Run installer with both global and local GSD present, verify prompt appears | N/A |
| R6.6 | POSIX sh compliance | unit | `shellcheck --shell=sh install.sh` returns 0 errors | Wave 0 |

### Sampling Rate
- **Per task commit:** `sh -n install.sh` syntax check
- **Per wave merge:** Full shellcheck pass + manual walkthrough
- **Phase gate:** Install on fresh GSD, update GSD, verify design files survive

### Wave 0 Gaps
- [ ] `install.sh` -- POSIX sh overlay installer
- [ ] `install.ps1` -- PowerShell overlay installer
- [ ] `design-version.json` schema and generation logic
- [ ] Patched `.claude/commands/gsd/update.md` with design preservation

## Sources

### Primary (HIGH confidence)
- `~/.claude/get-shit-done/workflows/update.md` -- GSD update workflow (read directly, 241 lines). Documents clean wipe behavior.
- `~/.claude/commands/gsd/update.md` -- GSD update command shim (read directly, 38 lines). Shows thin shim pattern.
- `~/.claude/commands/gsd/reapply-patches.md` -- GSD patch reapply mechanism (read directly, 124 lines). Shows backup/restore pattern.
- Project file inventory -- all 15+ design-layer files identified by scanning repo (HIGH confidence).
- GSD npm package info -- `get-shit-done-cc@1.22.4`, no dependencies, clean install behavior confirmed.
- macOS bash 3.2.57 -- confirmed by direct `bash --version` check.
- `shasum` 6.02 available on macOS -- confirmed by direct check.

### Secondary (MEDIUM confidence)
- [Microsoft PowerShell Execution Policy docs](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies) -- process-scoped bypass pattern
- [shasum man page](https://ss64.com/mac/shasum.html) -- `--portable` flag, `-a 256` usage

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools verified by direct inspection on the target platform
- Architecture: HIGH -- GSD update mechanism read directly; file inventory enumerated from repo; installation mapping derived from GSD's actual directory structure
- Pitfalls: HIGH -- derived from direct analysis of GSD's wipe-and-replace behavior and POSIX sh constraints

**Research date:** 2026-03-05
**Valid until:** 2026-04-05 (stable -- GSD update mechanism and POSIX sh are not fast-moving)
