#!/usr/bin/env bash
# setup.sh — clone Slicer source and ExtensionsIndex for local search
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
STAMP_FILE="$SKILL_DIR/.setup-stamp.json"
MAX_AGE=86400  # 24 hours

# Skip if stamp is fresh (pass --force to bypass)
if [ "${1:-}" != "--force" ] && [ -f "$STAMP_FILE" ]; then
    stamp=$(perl -ne 'print $1 if /"epoch"\s*:\s*(\d+)/' "$STAMP_FILE" 2>/dev/null || echo 0)
    age=$(( $(date +%s) - stamp ))
    if [ "$age" -lt "$MAX_AGE" ]; then
        echo "Setup ran $(( age / 3600 ))h$(( (age % 3600) / 60 ))m ago (< 24h). Skipping. Use --force to override."
        exit 0
    fi
fi

clone_or_pull() {
    local url="$1" dest="$SKILL_DIR/$2"
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
echo "Setup complete."
