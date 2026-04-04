#!/usr/bin/env bash
set -euo pipefail

# openclaw-fitness installer
# Copies plugin files to the correct ~/.openclaw/ locations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="${HOME}/.openclaw"
WORKSPACE_DIR="${OPENCLAW_DIR}/workspace"
FITNESS_DIR="${WORKSPACE_DIR}/fitness"
MANIFEST="${OPENCLAW_DIR}/fitness-plugin-manifest.txt"

echo "=== openclaw-fitness installer ==="
echo ""

# Check OpenClaw exists
if [ ! -d "$OPENCLAW_DIR" ]; then
    echo "ERROR: ~/.openclaw/ not found. Install OpenClaw first."
    exit 1
fi

# Conflict detection
CONFLICTS=()
[ -d "${FITNESS_DIR}" ] && CONFLICTS+=("${FITNESS_DIR}")
[ -d "${OPENCLAW_DIR}/hooks/workout-coach" ] && CONFLICTS+=("${OPENCLAW_DIR}/hooks/workout-coach")
[ -d "${OPENCLAW_DIR}/hooks/workout-streak-tracker" ] && CONFLICTS+=("${OPENCLAW_DIR}/hooks/workout-streak-tracker")
[ -d "${OPENCLAW_DIR}/hooks/post-workout-digest" ] && CONFLICTS+=("${OPENCLAW_DIR}/hooks/post-workout-digest")
[ -d "${OPENCLAW_DIR}/extensions/openclaw-fitness" ] && CONFLICTS+=("${OPENCLAW_DIR}/extensions/openclaw-fitness")
[ -d "${WORKSPACE_DIR}/skills/fitness" ] && CONFLICTS+=("${WORKSPACE_DIR}/skills/fitness")
[ -d "${WORKSPACE_DIR}/skills/fitness-onboarding" ] && CONFLICTS+=("${WORKSPACE_DIR}/skills/fitness-onboarding")

if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo "WARNING: The following destinations already exist:"
    for c in "${CONFLICTS[@]}"; do
        echo "  - $c"
    done
    echo ""
    read -p "Overwrite? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Start manifest
echo "# openclaw-fitness installed files - $(date -Iseconds)" > "$MANIFEST"

# Helper: copy and record in manifest
install_file() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "$dest" >> "$MANIFEST"
}

install_dir() {
    local src="$1"
    local dest="$2"
    mkdir -p "$dest"
    cp -R "$src"/* "$dest"/
    find "$dest" -type f >> "$MANIFEST"
}

echo "Installing training content..."
install_dir "${SCRIPT_DIR}/training" "${FITNESS_DIR}"

# Copy template as the active athlete profile (if no profile exists yet)
if [ ! -f "${FITNESS_DIR}/athlete-profile.md" ] || [ -f "${FITNESS_DIR}/athlete-profile.template.md" ]; then
    cp "${FITNESS_DIR}/athlete-profile.template.md" "${FITNESS_DIR}/athlete-profile.md"
    echo "${FITNESS_DIR}/athlete-profile.md" >> "$MANIFEST"
fi

echo "Creating logs directory..."
mkdir -p "${FITNESS_DIR}/logs"
echo "${FITNESS_DIR}/logs" >> "$MANIFEST"

echo "Installing skills..."
install_dir "${SCRIPT_DIR}/skills/fitness" "${WORKSPACE_DIR}/skills/fitness"
install_dir "${SCRIPT_DIR}/skills/fitness-onboarding" "${WORKSPACE_DIR}/skills/fitness-onboarding"

echo "Installing hooks..."
install_dir "${SCRIPT_DIR}/hooks/workout-coach" "${OPENCLAW_DIR}/hooks/workout-coach"
install_dir "${SCRIPT_DIR}/hooks/workout-streak-tracker" "${OPENCLAW_DIR}/hooks/workout-streak-tracker"
install_dir "${SCRIPT_DIR}/hooks/post-workout-digest" "${OPENCLAW_DIR}/hooks/post-workout-digest"

echo "Installing extension..."
install_dir "${SCRIPT_DIR}/extension" "${OPENCLAW_DIR}/extensions/openclaw-fitness"

echo ""
echo "=== Installation complete ==="
echo ""
echo "Manifest written to: $MANIFEST"
echo ""
echo "--- MANUAL STEPS REQUIRED ---"
echo ""
echo "1. Register the extension in ~/.openclaw/openclaw.json:"
echo '   Add "openclaw-fitness" to plugins.allow array'
echo '   Add to plugins.entries: { "openclaw-fitness": { "enabled": true } }'
echo '   Add to plugins.installs:'
echo '     "openclaw-fitness": {'
echo '       "source": "path",'
echo "       \"spec\": \"${OPENCLAW_DIR}/extensions/openclaw-fitness\","
echo "       \"sourcePath\": \"${OPENCLAW_DIR}/extensions/openclaw-fitness/index.ts\","
echo "       \"installPath\": \"${OPENCLAW_DIR}/extensions/openclaw-fitness\""
echo '     }'
echo ""
echo "2. Set up the bridge server:"
echo "   cd ${SCRIPT_DIR}/bridge"
echo "   cp .env.example .env  # Edit with your settings"
echo "   node server.js        # Test it works"
echo "   # See bridge/launchd/ for auto-start on macOS"
echo ""
echo "3. Start a conversation and say: 'set up fitness'"
echo "   The onboarding skill will walk you through configuring your profile."
echo ""
