# iOS App — Dynamic Training Phases 1 & 4

Specifies the iOS-side work required to activate the server-side changes already landed on the workout bridge (see `BRIDGE-API.md`).

**Core design constraint: zero gym bookkeeping.** The iOS app must never ask Birch to enter per-set weight, reps, or RIR. Winston's prescription is the ledger. The only new UX cost in this spec is **one tap at session end** (Phase 1).

---

## Phase 1 — One-Tap Vibe at Session End

### The Problem

Today, the AI coach receives rich prescriptions but gets almost nothing back from the app after a workout completes. It gets `completedSets` indexes, an optional 1–5 star rating, and freeform notes. That's not enough signal to calibrate the next session without nagging Birch for numbers.

### The Solution

Add a single three-button vibe prompt on the session-complete screen. That's it. No sliders, no per-set editing, no rep counters.

### UX Spec

After the user finishes a workout and taps "Complete" / "End Session" (whatever the existing flow is):

1. **Existing behavior stays**: the current rating + notes UI can remain or be retired, developer's choice. Not load-bearing.
2. **Add three buttons, large, tappable**:

```
   How'd that feel?

   ┌─────────────────┐
   │  😐  Light      │   prescription was too easy
   └─────────────────┘
   ┌─────────────────┐
   │  💪  Right      │   prescription dialed
   └─────────────────┘
   ┌─────────────────┐
   │  🔥  Grinding   │   prescription at ceiling
   └─────────────────┘

   [ Skip ]
```

3. **Tap selects and submits**. No confirm, no follow-up prompts. Skip button is OK — skipping just sends no vibe.
4. **Optional freeform text field** below the buttons, collapsed by default behind a "Add a note" chevron. Never required.

### API Change — Extend `POST /workout/:id/complete`

Add one optional field to the existing `feedback` object. Everything else stays:

```json
{
  "feedback": {
    "rating": 4,
    "notes": "felt strong on incline",
    "vibe": "right"
  },
  "completion": {
    "completedSets": { ... },
    "completedTimed": [ ... ],
    "removedExercises": [ ... ]
  }
}
```

- `vibe`: `"light" | "right" | "grinding" | null`. Omit entirely if the user skipped the vibe prompt — the backend treats missing as "no signal, carry the prescription forward as-is."
- Backward-compatible: old builds that don't send `vibe` continue to work.

### What happens on the server side (context only, no iOS work)

On vibe submission, the bridge writes `last-completion.json` with the full entry (vibe included). When Birch next talks to Winston about a workout, the `workout-coach` hook:
- Pulls `GET /last-completion`
- Dedupes by `workout_id` against `fitness-progress.jsonl`
- Computes completion rate from `completedSets`
- Injects `[Last Session Vibe]` into Winston's context
- Winston's generation rules (see `skills/fitness/SKILL.md` → Prescription Continuity & Vibe Interpretation) translate the vibe into a weight/volume adjustment on the next workout

### What NOT to Build

- No rep counter per set
- No weight editor per set
- No RIR / RPE slider
- No post-workout form asking about sleep, nutrition, or mood
- No streak ceremony — streaks are Winston's to surface, not the app's

### Testing

Simulator smoke test:

```bash
# Simulate the new payload shape
curl -X POST "http://localhost:18792/workout/<active-id>/complete" \
  -H "Content-Type: application/json" \
  -d '{
    "feedback": { "vibe": "light", "notes": "way too easy today" },
    "completion": {
      "completedSets": { "<ex-id>": [0,1,2,3] }
    }
  }'

# Verify last-completion.json reflects vibe
curl http://localhost:18792/last-completion | jq .feedback.vibe
# Expected: "light"
```

---

## Phase 4 — Apple Health Sync Extension

### The Problem

The coach already receives a `/health-sync` payload on app launch with today's sleep, RHR, bodyweight, and recent workouts. What's missing to enable recovery-aware session gating:
- **HRV** (heart rate variability, last-night average, ms)
- **7-day rolling baselines** for sleep, HRV, and RHR

Baselines let the hook compare "today vs. your normal" rather than "today vs. a hard-coded threshold" (which is both noisy and wrong as Birch's fitness changes).

### API Change — Extend `POST /health-sync`

Add five optional fields to the existing payload. Everything else stays:

```json
{
  "bodyweight_lbs": 213.0,
  "today_steps": 8420,
  "today_active_calories": 412,
  "last_night_sleep_hours": 6.15,
  "resting_heart_rate": 62,
  "recent_workouts": [ ... ],

  "hrv_last_night_ms": 42,
  "sleep_baseline_7d_hours": 7.2,
  "hrv_baseline_7d_ms": 55,
  "rhr_baseline_7d": 60
}
```

All five new fields are **computed on the iOS side** from HealthKit:

| Field | HealthKit type | Computation |
|-------|---------------|-------------|
| `hrv_last_night_ms` | `HKQuantityTypeIdentifierHeartRateVariabilitySDNN` | Most recent sample during last night's sleep window, converted to ms |
| `sleep_baseline_7d_hours` | `HKCategoryTypeIdentifierSleepAnalysis` | Rolling 7-day mean of nightly sleep duration |
| `hrv_baseline_7d_ms` | HRV samples | Rolling 7-day mean during sleep windows |
| `rhr_baseline_7d` | `HKQuantityTypeIdentifierRestingHeartRate` | Rolling 7-day mean |

### Permissions

If the app doesn't already request HRV read permission, add it:
- `NSHealthShareUsageDescription` should mention HRV and recovery tracking.
- Request the `heartRateVariabilitySDNN` identifier alongside existing read scopes.

### What happens on the server side

A new `recovery-gate` hook (to be built in Phase 4 server-side work) reads the extended health data on each workout-related message, scores recovery 0–3 based on sleep/HRV/RHR vs. their baselines, and injects a `[Recovery]` brief like:

```
[Recovery] Score 2/3 (push).
Sleep 7.8h vs 7.2h baseline (+). HRV 58/55ms (+). RHR 62/60 (=).
```

Winston combines that with the mesocycle phase to decide whether today is a push, normal, or hold session. Recovery only adjusts *downward* from the mesocycle ceiling — it never permits exceeding the planned peak volume.

### What NOT to Build

- No UI surfacing HRV trends, recovery scores, or "readiness" dashboards in the app. Recovery is an input to Winston's coaching, not a metric the user tracks themselves. Scoreboards lead to gamification, which leads to bookkeeping — the exact failure mode this whole system avoids.
- No push notifications based on HRV. Winston handles all user-facing recovery messaging in iMessage when it affects the session.

### Testing

```bash
# Simulate extended health sync
curl -X POST http://localhost:18792/health-sync \
  -H "Content-Type: application/json" \
  -d '{
    "bodyweight_lbs": 213,
    "last_night_sleep_hours": 5.0,
    "sleep_baseline_7d_hours": 7.5,
    "hrv_last_night_ms": 30,
    "hrv_baseline_7d_ms": 55,
    "resting_heart_rate": 72,
    "rhr_baseline_7d": 62
  }'

# Retrieve and confirm
curl http://localhost:18792/health-data | jq
```

---

## Shipping Order & Dependencies

- **Phase 1 iOS (vibe button)** is standalone. Ship anytime — the server already accepts the field. No blockers.
- **Phase 4 iOS (health sync extension)** depends on the server-side recovery-gate hook, which is planned but not yet built. Landing the iOS payload extension early is fine — the new fields just sit unused on the server until the hook arrives.

### Suggested sequence

1. **iOS Phase 1** — vibe button. One screen, ~100 LOC including the network payload change. Half a day of work.
2. **Server Phase 4** — recovery-gate hook. Can proceed in parallel with (1).
3. **iOS Phase 4** — health sync extension. Larger: HRV permissions, 7-day baseline computation, UI polish around the new HealthKit request. ~1–2 days.

---

## Why this spec is short

Because the principle is: **Winston owns the numbers, Birch owns the effort.** That keeps the iOS surface area small forever. If a future phase of this project feels like it requires a form, a rep counter, or a scale widget in the app, something has gone wrong at the design layer, not the spec. Escalate before building.

## References

- Server API reference: `../ios/BRIDGE-API.md` (update vibe field in `POST /workout/:id/complete` section when this ships)
- Coaching logic (Prescription Continuity + Vibe Interpretation + Mesocycle-Aware Generation): `../skills/fitness/SKILL.md`
- Architectural plan: `~/.claude/plans/how-can-we-make-binary-riddle.md`
