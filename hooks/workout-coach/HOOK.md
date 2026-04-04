---
name: workout-coach
description: "Inject pre-session training brief when workout-related messages arrive"
metadata:
  {
    "openclaw":
      {
        "events": ["message:received"],
        "requires": { "config": ["workspace.dir"] },
        "install": [{ "id": "managed", "kind": "managed", "label": "Managed hook" }],
      },
  }
---

# Workout Coach Hook

On inbound messages containing workout-related keywords, reads the latest workout log, determines the current cycle day, pulls routine template and athlete profile, and injects a structured training brief into the session context.

## What It Does

1. Detects workout intent via keyword matching (gym, workout, training, lift, etc.)
2. Reads the most recent log from `fitness/logs/`
3. Calculates current day in the rolling 7-day cycle
4. Reads the routine template for that day
5. Reads athlete-profile.md for working weights and progression status
6. Injects a structured brief via `event.messages.push()`

## Design Principle

Observe, don't prescribe. The brief surfaces facts (cycle day, weights, statuses, gap length). The coach reads TRAINING.md and decides how to coach.
