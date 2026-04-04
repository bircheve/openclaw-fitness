#!/usr/bin/env bash
set -euo pipefail

# Pre-publish PII audit for openclaw-fitness
# Exits non-zero if any personal data patterns are found
#
# CUSTOMIZE: Replace the example patterns below with your own
# personal data to catch before publishing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== PII Audit ==="
echo "Scanning: $REPO_DIR"
echo ""

FOUND=0

check_pattern() {
    local label="$1"
    local pattern="$2"
    local results
    results=$(grep -ri --include='*.md' --include='*.ts' --include='*.js' --include='*.json' --include='*.swift' --include='*.plist' --include='*.sh' -l "$pattern" "$REPO_DIR" 2>/dev/null | grep -v 'audit-pii.sh' | grep -v '.git/' || true)
    if [ -n "$results" ]; then
        echo "FAIL: $label"
        echo "$results" | while read -r f; do
            echo "  - $f"
            grep -ni "$pattern" "$f" 2>/dev/null | head -3 | sed 's/^/      /'
        done
        echo ""
        FOUND=1
    else
        echo "PASS: $label"
    fi
}

# Add your own personal data patterns here.
# These are examples — replace with values specific to you.
check_pattern "Phone number" "REPLACE_WITH_YOUR_PHONE"
check_pattern "Personal name" "REPLACE_WITH_YOUR_NAME"
check_pattern "Email username" "REPLACE_WITH_YOUR_EMAIL"
check_pattern "Gym name" "REPLACE_WITH_YOUR_GYM"
check_pattern "Location" "REPLACE_WITH_YOUR_LOCATION"
check_pattern "Private IP" "REPLACE_WITH_YOUR_IP"
check_pattern "Channel name" "REPLACE_WITH_YOUR_CHANNEL"
check_pattern "Machine name" "REPLACE_WITH_YOUR_HOSTNAME"

echo ""
if [ "$FOUND" -eq 0 ]; then
    echo "=== ALL CHECKS PASSED ==="
    exit 0
else
    echo "=== FAILURES DETECTED — fix before publishing ==="
    exit 1
fi
