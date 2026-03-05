---
name: gsd:update
description: Update GSD to latest version with design-layer preservation
allowed-tools:
  - Bash
  - AskUserQuestion
  - Read
  - Write
---

<!-- GSD-DESIGN-START: Patched update command with design-layer backup/restore -->

<objective>
Check for GSD updates, install if available, and display what changed.
Preserves all design-layer files (design commands, design workflows, patched GSD files, and design-version.json) through the GSD clean wipe-and-replace cycle.

Routes to the update workflow which handles:
- Version detection (local vs global installation)
- npm version checking
- Changelog fetching and display
- User confirmation with clean install warning
- Update execution and cache clearing
- Restart reminder

Additionally handles design-layer preservation:
- Pre-update backup of all 16 design files + design-version.json + this command
- Post-update restore of all backed-up files
- Checksum regeneration in design-version.json
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/update.md
</execution_context>

<process>

## Phase 1: BACKUP (before GSD update)

Before running any update, back up all design-layer files so they survive the clean wipe.

### Step 1.1: Detect install directory

```bash
# Detect install directory by checking for get-shit-done/VERSION
INSTALL_DIR=""
INSTALL_TYPE=""

# Check local directories first (takes priority)
for dir in .claude .config/opencode .opencode .gemini; do
  if [ -f "./$dir/get-shit-done/VERSION" ]; then
    INSTALL_DIR="$(cd "./$dir" 2>/dev/null && pwd)"
    INSTALL_TYPE="LOCAL"
    break
  fi
done

# If no local, check global directories
if [ -z "$INSTALL_DIR" ]; then
  for dir in .claude .config/opencode .opencode .gemini; do
    if [ -f "$HOME/$dir/get-shit-done/VERSION" ]; then
      INSTALL_DIR="$(cd "$HOME/$dir" 2>/dev/null && pwd)"
      INSTALL_TYPE="GLOBAL"
      break
    fi
  done
fi

if [ -z "$INSTALL_DIR" ]; then
  echo "ERROR: Could not find GSD installation directory."
  echo "Cannot proceed with design-safe update."
  exit 1
fi

echo "Install dir: $INSTALL_DIR ($INSTALL_TYPE)"
```

### Step 1.2: Create temp backup and copy design files

```bash
BACKUP_DIR=$(mktemp -d)
echo "Backup dir: $BACKUP_DIR"

# All 16 design-layer files (relative to install dir)
DESIGN_FILES=(
  "commands/gsd/design-thinking.md"
  "commands/gsd/design-ui.md"
  "commands/gsd/design-stack.md"
  "commands/gsd/new-project.md"
  "commands/gsd/discuss-phase.md"
  "commands/gsd/plan-phase.md"
  "commands/gsd/update.md"
  "get-shit-done/workflows/design/motion-design.md"
  "get-shit-done/workflows/design/orchestrate-design.md"
  "get-shit-done/workflows/design/stack-conventions.md"
  "get-shit-done/workflows/design/ui-design.md"
  "get-shit-done/workflows/design/ui-detection.md"
  "get-shit-done/workflows/design/ux-design.md"
  "get-shit-done/workflows/new-project.md"
  "get-shit-done/workflows/discuss-phase.md"
  "get-shit-done/workflows/plan-phase.md"
)

# Copy each file, preserving directory structure
BACKED_UP=0
for f in "${DESIGN_FILES[@]}"; do
  SRC="$INSTALL_DIR/$f"
  if [ -f "$SRC" ]; then
    DEST_DIR="$BACKUP_DIR/$(dirname "$f")"
    mkdir -p "$DEST_DIR"
    cp "$SRC" "$DEST_DIR/"
    BACKED_UP=$((BACKED_UP + 1))
  else
    echo "WARN: Design file not found, skipping: $f"
  fi
done

# Also back up design-version.json if it exists
if [ -f "$INSTALL_DIR/get-shit-done/design-version.json" ]; then
  mkdir -p "$BACKUP_DIR/get-shit-done"
  cp "$INSTALL_DIR/get-shit-done/design-version.json" "$BACKUP_DIR/get-shit-done/"
  echo "Backed up design-version.json"
fi

echo "Backed up $BACKED_UP design files to $BACKUP_DIR"
```

### Step 1.3: Verify backup

```bash
# Count backed-up files (should be at least 16)
BACKUP_COUNT=$(find "$BACKUP_DIR" -type f | wc -l | tr -d ' ')
echo "Backup file count: $BACKUP_COUNT"
if [ "$BACKUP_COUNT" -lt 16 ]; then
  echo "WARNING: Expected at least 16 files, found $BACKUP_COUNT."
  echo "Some design files may be missing from the installation."
fi
```

---

## Phase 2: UPDATE (vanilla GSD)

Now follow the standard update workflow from `@~/.claude/get-shit-done/workflows/update.md` end-to-end.

This includes:
1. Installed version detection (local/global)
2. Latest version checking via npm
3. Version comparison
4. Changelog fetching and extraction
5. Clean install warning display
6. User confirmation
7. Update execution via `npx -y get-shit-done-cc@latest --local` or `--global`
8. Cache clearing

**Follow every step of the update workflow exactly.** The design-layer backup has already been made; the update can proceed normally.

**Important:** If the user cancels the update at the confirmation step, skip Phase 3 and clean up the backup directory:
```bash
rm -rf "$BACKUP_DIR"
echo "Update cancelled. Backup cleaned up."
```

---

## Phase 3: RESTORE (after GSD update)

After the vanilla GSD update completes successfully, restore all design-layer files.

### Step 3.1: Recreate design directories

```bash
# Ensure design workflow directory exists (it was wiped by clean install)
mkdir -p "$INSTALL_DIR/get-shit-done/workflows/design"
echo "Created design directories"
```

### Step 3.2: Restore all design files from backup

```bash
# Restore each file from backup to its original location
RESTORED=0
for f in "${DESIGN_FILES[@]}"; do
  SRC="$BACKUP_DIR/$f"
  if [ -f "$SRC" ]; then
    DEST_DIR="$INSTALL_DIR/$(dirname "$f")"
    mkdir -p "$DEST_DIR"
    cp "$SRC" "$DEST_DIR/"
    RESTORED=$((RESTORED + 1))
  fi
done

echo "Restored $RESTORED design files"
```

### Step 3.3: Self-restore the patched update.md

This is critical: the vanilla GSD update just overwrote `commands/gsd/update.md` with the vanilla version. We must restore the patched version (this file) from backup.

```bash
# Restore patched update.md (this file itself)
if [ -f "$BACKUP_DIR/commands/gsd/update.md" ]; then
  cp "$BACKUP_DIR/commands/gsd/update.md" "$INSTALL_DIR/commands/gsd/update.md"
  echo "Restored patched update.md (self-restore)"
else
  echo "ERROR: Patched update.md not found in backup! Design update safety may be compromised."
fi
```

### Step 3.4: Regenerate design-version.json with fresh checksums

```bash
# Compute SHA-256 checksum function (macOS uses shasum, Linux uses sha256sum)
compute_sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "NO_CHECKSUM_TOOL"
  fi
}

# Read new GSD base version
NEW_BASE_VERSION=""
if [ -f "$INSTALL_DIR/get-shit-done/VERSION" ]; then
  NEW_BASE_VERSION=$(cat "$INSTALL_DIR/get-shit-done/VERSION" | head -1 | tr -d '[:space:]')
fi

# Build JSON with fresh checksums
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Start building the files JSON object
FILES_JSON="{"
FIRST=true
for f in "${DESIGN_FILES[@]}"; do
  FILEPATH="$INSTALL_DIR/$f"
  if [ -f "$FILEPATH" ]; then
    HASH=$(compute_sha256 "$FILEPATH")
    CHECKSUM="sha256:$HASH"
  else
    CHECKSUM=""
  fi

  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    FILES_JSON="$FILES_JSON,"
  fi
  FILES_JSON="$FILES_JSON
    \"$f\": \"$CHECKSUM\""
done
FILES_JSON="$FILES_JSON
  }"

# Write complete design-version.json
cat > "$INSTALL_DIR/get-shit-done/design-version.json" << DVEOF
{
  "version": "1.0.0",
  "schema_version": 1,
  "installed_at": "$TIMESTAMP",
  "gsd_base_version": "$NEW_BASE_VERSION",
  "files": $FILES_JSON
}
DVEOF

echo "Regenerated design-version.json with fresh checksums"
echo "  GSD base version: $NEW_BASE_VERSION"
echo "  Timestamp: $TIMESTAMP"
```

### Step 3.5: Verify restoration

```bash
# Verify all 16 design files exist
MISSING=0
for f in "${DESIGN_FILES[@]}"; do
  if [ ! -f "$INSTALL_DIR/$f" ]; then
    echo "MISSING: $f"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$MISSING" -eq 0 ]; then
  echo "All 16 design files verified."
else
  echo "WARNING: $MISSING design file(s) missing after restore!"
fi

# Verify design-version.json
if [ -f "$INSTALL_DIR/get-shit-done/design-version.json" ]; then
  echo "design-version.json verified."
else
  echo "WARNING: design-version.json missing after restore!"
fi
```

### Step 3.6: Clean up

```bash
rm -rf "$BACKUP_DIR"
echo "Backup directory cleaned up."
echo ""
echo "Design layer preserved through GSD update."
```

### Step 3.7: Display completion

Display the following completion banner:

---

## UPDATE COMPLETE

GSD updated successfully. Design layer preserved through update (all 16 design files restored).

**Important:** Restart your Claude Code session to pick up the new version.

---

## Next Up

- `/gsd:progress` -- see where you left off
- `/gsd:discuss-phase N` -- continue with next phase

<sub>`/clear` first -- fresh context window (required after update)</sub>

---

</process>

<!-- GSD-DESIGN-END -->
