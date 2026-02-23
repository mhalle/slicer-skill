#!/usr/bin/env bash
# setup.sh — clone Slicer source and ExtensionsIndex for local search
#
# Usage: setup.sh [--force] [CACHE_DIR]
#
# CACHE_DIR defaults to ~/.cache/slicer-skill but can be overridden via the
# first non-flag argument or the SLICER_SKILL_CACHE_DIR environment variable.
# Use a custom directory when ~/.cache is not writable (e.g. sandboxed
# environments):
#
#   setup.sh /tmp/slicer-skill-${USER}
#
set -euo pipefail

FORCE=0
CUSTOM_DIR=""
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        *)       CUSTOM_DIR="$arg" ;;
    esac
done

CACHE_DIR="${CUSTOM_DIR:-${SLICER_SKILL_CACHE_DIR:-${HOME}/.cache/slicer-skill}}"
REPO_DIR="${CACHE_DIR}/repositories"
STAMP_FILE="${CACHE_DIR}/.setup-stamp.json"
MAX_AGE=86400  # 24 hours

# Skip if stamp is fresh (pass --force to bypass)
if [ "$FORCE" -eq 0 ] && [ -f "$STAMP_FILE" ]; then
    stamp=$(perl -ne 'print $1 if /"epoch"\s*:\s*(\d+)/' "$STAMP_FILE" 2>/dev/null || echo 0)
    age=$(( $(date +%s) - stamp ))
    if [ "$age" -lt "$MAX_AGE" ]; then
        echo "Setup ran $(( age / 3600 ))h$(( (age % 3600) / 60 ))m ago (< 24h). Skipping. Use --force to override."
        exit 0
    fi
fi

mkdir -p "$REPO_DIR"

clone_or_pull() {
    local url="$1" dest="$REPO_DIR/$2"
    if [ -d "$dest/.git" ]; then
        echo "Updating $dest..."
        git -C "$dest" pull --ff-only 2>/dev/null || true
    else
        echo "Cloning $url -> $dest"
        git clone --depth 1 "$url" "$dest"
    fi
}

clone_or_pull "https://github.com/Slicer/Slicer.git"          slicer-source
clone_or_pull "https://github.com/Slicer/ExtensionsIndex.git"  slicer-extensions

printf '{"epoch": %d, "iso": "%s"}\n' "$(date +%s)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$STAMP_FILE"
echo "Setup complete. Repositories in: $REPO_DIR"
