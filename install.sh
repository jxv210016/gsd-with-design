#!/bin/sh
set -eu

# GSD with Design -- Overlay Installer v1.0.0
# Installs design-layer files on top of an existing GSD installation.
# POSIX sh compliant (no bashisms) for macOS/Linux compatibility.

DESIGN_VERSION="1.0.0"
SCHEMA_VERSION=1
REPO_URL="https://github.com/jxv210016/gsd-with-design"

##############################################################################
# Banner
##############################################################################

printf "\n"
printf "============================================\n"
printf "  GSD with Design -- Overlay Installer v%s\n" "$DESIGN_VERSION"
printf "============================================\n"
printf "\n"

##############################################################################
# Checksum function
##############################################################################

compute_checksum() {
  _cc_file="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$_cc_file" | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$_cc_file" | cut -d' ' -f1
  else
    printf "ERROR: No SHA-256 tool found (need shasum or sha256sum)\n" >&2
    exit 1
  fi
}

##############################################################################
# Source directory detection
# If run from repo root, use local files. Otherwise download from GitHub.
##############################################################################

CLEANUP_TMPDIR=""

cleanup() {
  if [ -n "$CLEANUP_TMPDIR" ] && [ -d "$CLEANUP_TMPDIR" ]; then
    rm -rf "$CLEANUP_TMPDIR"
  fi
}
trap cleanup EXIT

if [ -f "./.claude/commands/gsd/design-thinking.md" ] && [ -f "./workflows/design/ui-design.md" ]; then
  SCRIPT_DIR="$(pwd)"
  printf "Source: %s (local)\n" "$SCRIPT_DIR"
else
  printf "Downloading from %s...\n" "$REPO_URL"
  CLEANUP_TMPDIR="$(mktemp -d)"
  TARBALL_URL="${REPO_URL}/archive/refs/heads/main.tar.gz"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$TARBALL_URL" | tar xz -C "$CLEANUP_TMPDIR"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$TARBALL_URL" | tar xz -C "$CLEANUP_TMPDIR"
  else
    printf "ERROR: Need curl or wget to download files.\n" >&2
    exit 1
  fi

  # tar extracts to a directory named {repo}-{branch}
  SCRIPT_DIR="$CLEANUP_TMPDIR/gsd-with-design-main"

  if [ ! -f "$SCRIPT_DIR/.claude/commands/gsd/design-thinking.md" ]; then
    printf "ERROR: Download succeeded but expected files not found.\n" >&2
    exit 1
  fi

  printf "Source: downloaded from GitHub\n"
fi

##############################################################################
# GSD installation detection (R6.5)
##############################################################################

FOUND_INSTALLS=""
FOUND_COUNT=0

# Check local dirs
for _gid_dir in .claude .config/opencode .opencode .gemini; do
  if [ -f "./$_gid_dir/get-shit-done/VERSION" ]; then
    FOUND_INSTALLS="${FOUND_INSTALLS}local:./$_gid_dir
"
    FOUND_COUNT=$((FOUND_COUNT + 1))
  fi
done

# Check global dirs
for _gid_dir in .claude .config/opencode .opencode .gemini; do
  if [ -f "$HOME/$_gid_dir/get-shit-done/VERSION" ]; then
    # Avoid double-counting if local and global point to same dir
    _gid_resolved_home="$(cd "$HOME/$_gid_dir" 2>/dev/null && pwd)"
    _gid_skip=0
    _gid_oldifs="$IFS"
    IFS='
'
    for _gid_entry in $FOUND_INSTALLS; do
      _gid_path="${_gid_entry#*:}"
      if [ -d "$_gid_path" ]; then
        _gid_resolved_path="$(cd "$_gid_path" 2>/dev/null && pwd)"
        if [ "$_gid_resolved_home" = "$_gid_resolved_path" ]; then
          _gid_skip=1
          break
        fi
      fi
    done
    IFS="$_gid_oldifs"
    if [ "$_gid_skip" -eq 0 ]; then
      FOUND_INSTALLS="${FOUND_INSTALLS}global:$HOME/$_gid_dir
"
      FOUND_COUNT=$((FOUND_COUNT + 1))
    fi
  fi
done

if [ "$FOUND_COUNT" -eq 0 ]; then
  printf "ERROR: No GSD installation found.\n" >&2
  printf "Install GSD first: npx get-shit-done-cc@latest\n" >&2
  exit 1
fi

INSTALL_DIR=""

if [ "$FOUND_COUNT" -eq 1 ]; then
  # Single installation found -- use it
  _si_entry="$(printf "%s" "$FOUND_INSTALLS" | head -1)"
  _si_type="${_si_entry%%:*}"
  _si_path="${_si_entry#*:}"
  INSTALL_DIR="$_si_path"
  printf "Found %s GSD installation: %s\n" "$_si_type" "$INSTALL_DIR"
else
  # Multiple installations found -- prompt user
  printf "Multiple GSD installations found:\n\n"
  _mi_index=0
  _mi_oldifs="$IFS"
  IFS='
'
  for _mi_entry in $FOUND_INSTALLS; do
    if [ -z "$_mi_entry" ]; then
      continue
    fi
    _mi_index=$((_mi_index + 1))
    _mi_type="${_mi_entry%%:*}"
    _mi_path="${_mi_entry#*:}"
    _mi_ver="$(cat "$_mi_path/get-shit-done/VERSION" 2>/dev/null || echo "unknown")"
    printf "  %d) [%s] %s (GSD v%s)\n" "$_mi_index" "$_mi_type" "$_mi_path" "$_mi_ver"
  done
  IFS="$_mi_oldifs"

  printf "\nChoose installation target [1]: "
  read -r _mi_choice
  if [ -z "$_mi_choice" ]; then
    _mi_choice=1
  fi

  _mi_current=0
  _mi_oldifs2="$IFS"
  IFS='
'
  for _mi_entry in $FOUND_INSTALLS; do
    if [ -z "$_mi_entry" ]; then
      continue
    fi
    _mi_current=$((_mi_current + 1))
    if [ "$_mi_current" -eq "$_mi_choice" ]; then
      INSTALL_DIR="${_mi_entry#*:}"
      break
    fi
  done
  IFS="$_mi_oldifs2"

  if [ -z "$INSTALL_DIR" ]; then
    printf "ERROR: Invalid selection.\n" >&2
    exit 1
  fi
  printf "Selected: %s\n" "$INSTALL_DIR"
fi

printf "\n"

##############################################################################
# Existing design installation check
##############################################################################

VERSION_JSON="$INSTALL_DIR/get-shit-done/design-version.json"

if [ -f "$VERSION_JSON" ]; then
  printf "Existing design installation detected.\n"
  _ec_has_customized=0

  # Check each installed file against stored checksums
  # Parse checksums from JSON (simple grep/sed since structure is flat)
  # Use temp file to track customized status (while-read runs in subshell)
  _ec_customized_list="$(mktemp)"
  grep '"sha256:' "$VERSION_JSON" 2>/dev/null | while IFS= read -r _ec_line; do
    _ec_rel_path="$(printf "%s" "$_ec_line" | sed 's/.*"\([^"]*\)"[[:space:]]*:[[:space:]]*"sha256:.*/\1/')"
    _ec_stored_hash="$(printf "%s" "$_ec_line" | sed 's/.*"sha256:\([a-f0-9]*\)".*/\1/')"
    _ec_full_path="$INSTALL_DIR/$_ec_rel_path"

    if [ -f "$_ec_full_path" ] && [ -n "$_ec_stored_hash" ]; then
      _ec_current_hash="$(compute_checksum "$_ec_full_path")"
      if [ "$_ec_current_hash" != "$_ec_stored_hash" ]; then
        printf "%s\n" "$_ec_rel_path" >> "$_ec_customized_list"
      fi
    fi
  done

  if [ -s "$_ec_customized_list" ]; then
    _ec_has_customized=1
    printf "Customized design files detected:\n"
    while IFS= read -r _ec_custom_path; do
      printf "  - %s\n" "$_ec_custom_path"
    done < "$_ec_customized_list"
  fi
  rm -f "$_ec_customized_list"

  if [ "$_ec_has_customized" -eq 1 ]; then
    printf "\nBack up customized files? [Y/n] "
    read -r _ec_backup_choice
    case "$_ec_backup_choice" in
      [nN]*)
        printf "Skipping backup.\n"
        ;;
      *)
        _ec_timestamp="$(date +%Y%m%d-%H%M%S)"
        _ec_backup_dir="$INSTALL_DIR/get-shit-done/design-backup-$_ec_timestamp"
        mkdir -p "$_ec_backup_dir"
        printf "Backing up to: %s\n" "$_ec_backup_dir"

        grep '"sha256:' "$VERSION_JSON" 2>/dev/null | while IFS= read -r _ec_line; do
          _ec_rel_path="$(printf "%s" "$_ec_line" | sed 's/.*"\([^"]*\)"[[:space:]]*:[[:space:]]*"sha256:.*/\1/')"
          _ec_full_path="$INSTALL_DIR/$_ec_rel_path"
          if [ -f "$_ec_full_path" ]; then
            _ec_backup_file="$_ec_backup_dir/$_ec_rel_path"
            mkdir -p "$(dirname "$_ec_backup_file")"
            cp -p "$_ec_full_path" "$_ec_backup_file"
          fi
        done
        printf "Backup complete.\n"
        ;;
    esac
  else
    printf "No customizations detected -- safe to overwrite.\n"
  fi
  printf "\n"
fi

##############################################################################
# File copy
##############################################################################

printf "Installing design files...\n\n"

INSTALLED_COUNT=0

# Ensure target directories exist
mkdir -p "$INSTALL_DIR/commands/gsd"
mkdir -p "$INSTALL_DIR/get-shit-done/workflows/design"

# Design-only command shims (no path rewriting needed)
DESIGN_ONLY_CMDS="design-thinking.md design-ui.md design-stack.md"
for _fc_file in $DESIGN_ONLY_CMDS; do
  _fc_src="$SCRIPT_DIR/.claude/commands/gsd/$_fc_file"
  _fc_dst="$INSTALL_DIR/commands/gsd/$_fc_file"
  if [ -f "$_fc_src" ]; then
    cp -p "$_fc_src" "$_fc_dst"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    printf "  [copied]   commands/gsd/%s\n" "$_fc_file"
  else
    printf "  [skipped]  commands/gsd/%s (not found in source)\n" "$_fc_file"
  fi
done

# Patched command shims (need path rewriting)
PATCHED_CMDS="new-project.md discuss-phase.md plan-phase.md update.md"
for _fc_file in $PATCHED_CMDS; do
  _fc_src="$SCRIPT_DIR/.claude/commands/gsd/$_fc_file"
  _fc_dst="$INSTALL_DIR/commands/gsd/$_fc_file"
  if [ -f "$_fc_src" ]; then
    sed "s|@~/.claude/|@${INSTALL_DIR}/|g" "$_fc_src" > "$_fc_dst"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    printf "  [patched]  commands/gsd/%s\n" "$_fc_file"
  else
    printf "  [skipped]  commands/gsd/%s (not found in source)\n" "$_fc_file"
  fi
done

# Design workflow files (no path rewriting needed)
DESIGN_WORKFLOWS="motion-design.md orchestrate-design.md stack-conventions.md ui-design.md ui-detection.md ux-design.md"
for _fc_file in $DESIGN_WORKFLOWS; do
  _fc_src="$SCRIPT_DIR/workflows/design/$_fc_file"
  _fc_dst="$INSTALL_DIR/get-shit-done/workflows/design/$_fc_file"
  if [ -f "$_fc_src" ]; then
    cp -p "$_fc_src" "$_fc_dst"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    printf "  [copied]   get-shit-done/workflows/design/%s\n" "$_fc_file"
  else
    printf "  [skipped]  get-shit-done/workflows/design/%s (not found in source)\n" "$_fc_file"
  fi
done

# Copied workflow files (no path rewriting needed)
COPIED_WORKFLOWS="quick.md"
for _fc_file in $COPIED_WORKFLOWS; do
  _fc_src="$SCRIPT_DIR/workflows/$_fc_file"
  _fc_dst="$INSTALL_DIR/get-shit-done/workflows/$_fc_file"
  if [ -f "$_fc_src" ]; then
    cp -p "$_fc_src" "$_fc_dst"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    printf "  [copied]   get-shit-done/workflows/%s\n" "$_fc_file"
  else
    printf "  [skipped]  get-shit-done/workflows/%s (not found in source)\n" "$_fc_file"
  fi
done

# Patched workflow files (need path rewriting)
PATCHED_WORKFLOWS="new-project.md discuss-phase.md plan-phase.md"
for _fc_file in $PATCHED_WORKFLOWS; do
  _fc_src="$SCRIPT_DIR/workflows/$_fc_file"
  _fc_dst="$INSTALL_DIR/get-shit-done/workflows/$_fc_file"
  if [ -f "$_fc_src" ]; then
    sed "s|@~/.claude/|@${INSTALL_DIR}/|g" "$_fc_src" > "$_fc_dst"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    printf "  [patched]  get-shit-done/workflows/%s\n" "$_fc_file"
  else
    printf "  [skipped]  get-shit-done/workflows/%s (not found in source)\n" "$_fc_file"
  fi
done

printf "\n"

##############################################################################
# design-version.json generation
##############################################################################

printf "Generating design-version.json...\n"

GSD_BASE_VERSION="$(cat "$INSTALL_DIR/get-shit-done/VERSION" 2>/dev/null || echo "unknown")"
INSTALL_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# All 16 relative paths for the design layer files
ALL_DESIGN_FILES="commands/gsd/design-thinking.md
commands/gsd/design-ui.md
commands/gsd/design-stack.md
commands/gsd/new-project.md
commands/gsd/discuss-phase.md
commands/gsd/plan-phase.md
commands/gsd/update.md
get-shit-done/workflows/design/motion-design.md
get-shit-done/workflows/design/orchestrate-design.md
get-shit-done/workflows/design/stack-conventions.md
get-shit-done/workflows/design/ui-design.md
get-shit-done/workflows/design/ui-detection.md
get-shit-done/workflows/design/ux-design.md
get-shit-done/workflows/quick.md
get-shit-done/workflows/new-project.md
get-shit-done/workflows/discuss-phase.md
get-shit-done/workflows/plan-phase.md"

# Build JSON using printf
_gv_json_file="$INSTALL_DIR/get-shit-done/design-version.json"
{
  printf '{\n'
  printf '  "version": "%s",\n' "$DESIGN_VERSION"
  printf '  "schema_version": %d,\n' "$SCHEMA_VERSION"
  printf '  "installed_at": "%s",\n' "$INSTALL_TIMESTAMP"
  printf '  "gsd_base_version": "%s",\n' "$GSD_BASE_VERSION"
  printf '  "files": {\n'

  _gv_first=true
  _gv_oldifs="$IFS"
  IFS='
'
  for _gv_rel_path in $ALL_DESIGN_FILES; do
    _gv_full_path="$INSTALL_DIR/$_gv_rel_path"
    if [ -f "$_gv_full_path" ]; then
      _gv_hash="$(compute_checksum "$_gv_full_path")"
      if [ "$_gv_first" = "true" ]; then
        _gv_first=false
      else
        printf ',\n'
      fi
      printf '    "%s": "sha256:%s"' "$_gv_rel_path" "$_gv_hash"
    else
      # File not installed -- write empty checksum
      if [ "$_gv_first" = "true" ]; then
        _gv_first=false
      else
        printf ',\n'
      fi
      printf '    "%s": ""' "$_gv_rel_path"
    fi
  done
  IFS="$_gv_oldifs"

  printf '\n  }\n'
  printf '}\n'
} > "$_gv_json_file"

printf "  Written: %s\n\n" "$_gv_json_file"

##############################################################################
# Verification
##############################################################################

VERIFIED_COUNT=0
_v_oldifs="$IFS"
IFS='
'
for _v_rel_path in $ALL_DESIGN_FILES; do
  if [ -f "$INSTALL_DIR/$_v_rel_path" ]; then
    VERIFIED_COUNT=$((VERIFIED_COUNT + 1))
  fi
done
IFS="$_v_oldifs"

printf "============================================\n"
printf "  Installation Summary\n"
printf "============================================\n"
printf "  Files installed:    %d\n" "$INSTALLED_COUNT"
printf "  Files verified:     %d / 17\n" "$VERIFIED_COUNT"
printf "  Install location:   %s\n" "$INSTALL_DIR"
printf "  GSD base version:   %s\n" "$GSD_BASE_VERSION"
printf "  Design version:     %s\n" "$DESIGN_VERSION"
printf "============================================\n"
printf "\n"

if [ "$VERIFIED_COUNT" -lt "$INSTALLED_COUNT" ]; then
  printf "WARNING: Some files could not be verified after installation.\n" >&2
fi

printf "GSD with Design installed successfully!\n"
printf "Restart Claude Code to use design commands.\n\n"
