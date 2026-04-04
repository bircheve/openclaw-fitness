#!/usr/bin/env bash
set -euo pipefail

# openclaw-fitness uninstaller
# Removes files listed in the install manifest

OPENCLAW_DIR="${HOME}/.openclaw"
MANIFEST="${OPENCLAW_DIR}/fitness-plugin-manifest.txt"

echo "=== openclaw-fitness uninstaller ==="
echo ""

if [ ! -f "$MANIFEST" ]; then
    echo "ERROR: Manifest not found at $MANIFEST"
    echo "Cannot determine which files were installed."
    echo ""
    echo "Manual removal:"
    echo "  rm -rf ~/.openclaw/workspace/fitness"
    echo "  rm -rf ~/.openclaw/workspace/skills/fitness"
    echo "  rm -rf ~/.openclaw/workspace/skills/fitness-onboarding"
    echo "  rm -rf ~/.openclaw/hooks/workout-coach"
    echo "  rm -rf ~/.openclaw/hooks/workout-streak-tracker"
    echo "  rm -rf ~/.openclaw/hooks/post-workout-digest"
    echo "  rm -rf ~/.openclaw/extensions/openclaw-fitness"
    exit 1
fi

echo "The following files will be removed:"
echo ""

FILE_COUNT=0
while IFS= read -r line; do
    # Skip comments
    [[ "$line" =~ ^# ]] && continue
    [ -z "$line" ] && continue
    if [ -e "$line" ]; then
        echo "  $line"
        FILE_COUNT=$((FILE_COUNT + 1))
    fi
done < "$MANIFEST"

echo ""
echo "$FILE_COUNT files found."
echo ""
read -p "Remove all? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Remove files
while IFS= read -r line; do
    [[ "$line" =~ ^# ]] && continue
    [ -z "$line" ] && continue
    if [ -f "$line" ]; then
        rm "$line"
    fi
done < "$MANIFEST"

# Clean up empty directories
rmdir "${OPENCLAW_DIR}/workspace/fitness/logs" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness/exercises/chest" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness/exercises/back" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness/exercises/shoulders" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness/exercises/arms" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness/exercises/legs" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness/exercises/cardio" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness/exercises" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness/routines/split" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness/routines/ppl" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness/routines" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/fitness" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/skills/fitness" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/workspace/skills/fitness-onboarding" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/hooks/workout-coach" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/hooks/workout-streak-tracker" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/hooks/post-workout-digest" 2>/dev/null || true
rmdir "${OPENCLAW_DIR}/extensions/openclaw-fitness" 2>/dev/null || true

# Remove manifest
rm "$MANIFEST"

echo ""
echo "=== Uninstall complete ==="
echo ""
echo "MANUAL STEPS:"
echo "  Remove 'openclaw-fitness' from ~/.openclaw/openclaw.json plugins section"
echo "  Remove fitness cron jobs from ~/.openclaw/cron/jobs.json (if added)"
echo ""
