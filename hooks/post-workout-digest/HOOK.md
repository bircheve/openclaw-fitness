---
name: post-workout-digest
description: "Compute progress signals after workout logs are sent"
metadata:
  {
    "openclaw":
      {
        "events": ["message:sent"],
        "requires": { "config": ["workspace.dir"] },
        "install": [{ "id": "managed", "kind": "managed", "label": "Managed hook" }],
      },
  }
---

# Post-Workout Digest Hook

After the coach sends a message containing workout log data, compares exercises against the athlete profile and recent logs to compute factual progress signals: PRs, stalls, and threshold crossings.

## Design Principle

Observe, don't prescribe. Surfaces raw facts ("Incline barbell: 175 lbs, session 3 at this weight"). The coach applies TRAINING.md coaching logic.

## Output

- `~/.openclaw/logs/fitness-progress.jsonl` — Append-only signal log
- `~/.openclaw/logs/fitness-signals-latest.json` — Latest signals for next session bootstrap
