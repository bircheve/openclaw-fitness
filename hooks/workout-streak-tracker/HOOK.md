---
name: workout-streak-tracker
description: "Track training consistency streaks and weekly session counts"
metadata:
  {
    "openclaw":
      {
        "events": ["agent:bootstrap"],
        "requires": { "config": ["workspace.dir"] },
        "install": [{ "id": "managed", "kind": "managed", "label": "Managed hook" }],
      },
  }
---

# Workout Streak Tracker Hook

On every session bootstrap, reads workout log filenames to compute consistency metrics: sessions this week, sessions last week, current streak (consecutive weeks with 4+ sessions), and monthly comparison. Injects factual context for the coach's awareness.

## Design Principle

Counts and reports. Does not judge, nudge, or suggest. The coach decides coaching tone based on the data.

## State

Persists streak data to `~/.openclaw/logs/fitness-streak.json`.
