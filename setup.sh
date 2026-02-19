#!/usr/bin/env bash
# setup.sh - clone the Slicer sources, extension index and discourse archive for local searches

set -euo pipefail

# locations may be overridden using environment variables
: "${SLICER_SRC_DIR:=slicer-source}"
: "${SLICER_EXT_DIR:=slicer-extensions}"
: "${SLICER_DISCOURSE_DIR:=slicer-discourse}"

# optional filter: space-separated list of extension names to fetch.  Leave empty to
# clone everything.
EXTENSION_FILTER=""

clone_or_pull() {
    local url="$1"
    local dest="$2"
    if [ -d "$dest/.git" ]; then
        echo "Updating $dest..."
        git -C "$dest" pull --ff-only
    else
        echo "Cloning $url -> $dest"
        git clone --depth 1 "$url" "$dest"
    fi
}

# 1. main Slicer source
clone_or_pull "https://github.com/Slicer/Slicer.git" "$SLICER_SRC_DIR"

# 2. extensions index
clone_or_pull "https://github.com/Slicer/ExtensionsIndex.git" "$SLICER_EXT_DIR"

# iterate over all index files and clone referenced repos
if [ -d "$SLICER_EXT_DIR" ]; then
    echo "Processing extensions index..."
    find "$SLICER_EXT_DIR" -name "*.json" | while read file; do
        repo=$(grep -Po '"git_repo"\s*:\s*"\K[^"]+' "$file" || true)
        if [ -n "$repo" ]; then
            name=$(basename "$repo" .git)
            if [ -n "$EXTENSION_FILTER" ] && ! [[ " $EXTENSION_FILTER " =~ " $name " ]]; then
                continue
            fi
            clone_or_pull "$repo" "$SLICER_EXT_DIR/$name"
        fi
    done
fi

# 3. discourse archive
clone_or_pull "https://github.com/pieper/slicer-discourse-archive.git" "$SLICER_DISCOURSE_DIR"

echo "Setup complete."
