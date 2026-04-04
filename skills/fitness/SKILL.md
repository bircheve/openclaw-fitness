---
name: fitness
description: Fitness coaching and workout management
---

# Fitness — Workout Coaching & Logging

## Trigger

Any request about workouts, training, gym, "what's my workout", logging a session, fitness check-in, or program review.

## Paths

```
FITNESS_DIR = ~/.openclaw/workspace/fitness
```

| Purpose | Path |
|---------|------|
| Training philosophy | `$FITNESS_DIR/training-philosophy.md` |
| Double progression | `$FITNESS_DIR/double-progression.md` |
| Warmup protocol | `$FITNESS_DIR/warmup-protocol.md` |
| Split routines | `$FITNESS_DIR/routines/split/day-{N}-*.md` |
| Exercise library | `$FITNESS_DIR/exercises/{group}/*.md` |
| Athlete profile | `$FITNESS_DIR/athlete-profile.md` |
| Coaching playbook | `$FITNESS_DIR/TRAINING.md` |
| Training protocol | `$FITNESS_DIR/training-protocol.md` |
| Workout logs | `$FITNESS_DIR/logs/` |

## Version Control (Optional)

If your fitness data directory is a git repo, you can pull before reading and commit after writing. This is optional — the plugin works without git.

```bash
# Optional: before any read
cd ~/.openclaw/workspace/fitness && git pull --ff-only

# Optional: after any write
cd ~/.openclaw/workspace/fitness && git add -A && git commit -m "descriptive message" && git push
```

Commit messages: lowercase, descriptive. Examples:
- `log workout: day 3 back + triceps (2026-02-14)`
- `update day-1 routine: swap flat press category`
- `bi-weekly check-in: adjust day 5 volume`

## Coaching Directives

Before generating any workout, read `$FITNESS_DIR/TRAINING.md`. Key principles:

- **Push proactively.** When progression notes show `progressing` for 2+ sessions, suggest bumping weight next session. Don't wait for `ready-to-increase`.
- **Set targets high.** Top of the rep range, not the bottom. Let gravity pull them down.
- **Call out coasting.** Low RPE, skipped finishers, shortened cardio — address it directly next session.
- **Read stall signals.** Same weight + same reps for 3+ sessions = stalled. Rotate the exercise or add an intensity technique.
- **Track deload timing.** At 5 weeks, watch for stalls. At 6 weeks, suggest deload proactively.
- **Be direct.** "You're doing incline dumbbell press at 80 lbs today" — not "Maybe try 80?"
- **Never generate an easier workout** than the last one for the same muscle group (unless deload or adapting to illness/recovery).

## Adaptive Context

Before generating any workout, check the athlete profile's current status and recent logs for signals that require adaptation. Be proactive — don't wait for the user to tell you to go easy.

**Signals to act on:**
- `rebuilding-after-illness` status → Cap intensity at 80-85%. Hold current weights, focus on volume and form. No weight increases for 3-4 sessions back. Say "rebuilding week" once, don't belabor it.
- Gap of 2+ weeks since last session for a muscle group → Treat as a re-introduction. Drop to 85-90% of last logged weight. Build back over 2 sessions.
- Multiple exercises marked `deload` or stalled → Suggest a deload week proactively.
- Low energy/sleep reported in recent logs → Reduce volume (fewer sets, not fewer exercises). Keep the session moving.
- First session back after any break → Prioritize movement quality over load. The workout should feel achievable, not punishing.

**Don't over-explain the adaptation.** The user doesn't need a paragraph about why the workout is lighter — just build the right workout and mention the context in one line if relevant (e.g., "First back day since Feb — holding weight, pushing reps").

## Generate Workout — Three-Phase Flow

Workouts are delivered in three phases: overview, block-by-block, then logging. This gives the user flexibility to swap exercises, adjust on the fly, and log naturally.

### Phase 1 — Overview

When the user asks "what's my workout today?" or similar:

1. **Read athlete profile** (`athlete-profile.md`) for current working weights, PRs, and coaching notes.
2. **Determine day in cycle.** Scan `logs/` for the most recent log whose `routine_id` matches the pattern `fitness-split-day-*`. Extract `day_in_cycle` from that routine's template file. Next day = that number + 1 (wrap 7 back to 1). If no split logs exist, default to Day 1. Logs with other `routine_id` values (adaptive-cycle, ad-hoc, PPL) do NOT advance the split cycle.
3. **Load the routine template** from `routines/split/day-{N}-*.md`. Read the block structure — it defines exercise categories, not specific exercises.
4. **Select specific exercises.** For each category slot in the template:
   - Check the exercise library (`exercises/{group}/*.md`) for options.
   - Check the last 2-3 logs for the same split day to see what was used.
   - Rotate: never repeat the exact same exercise lineup for the same split day. Vary angle, grip, or equipment per training-philosophy.md.
5. **Check progression context.** Use the athlete profile's working weights table as the primary source. Cross-reference recent logs for additional context. Apply double-progression model from `double-progression.md`.
6. **Send the overview.** One message with every block summarized. Phone-friendly: no markdown bold, no blank lines between sections, single newlines only. Use em-dash section breaks.

```
Day {N} — {Focus}
—
Warmup: 5 min incline walk + stretches
—
Compounds
1. {Exercise} — {sets}x{reps} @ {weight}
2. {Exercise} — {sets}x{reps} @ {weight}
—
Hypertrophy
3. {Exercise} — {sets}x{reps} @ {weight}
4. {Exercise} — {sets}x{reps} @ {weight}
—
Finisher: {Exercise} — {reps}+ to failure
—
Cardio: {duration} min stairmaster
—
Say "let's go" when ready, or swap anything first.
```

7. **Push to Pixelated Fitness app.** After sending the overview, push the workout to the iOS app by calling `exec` to POST the JSON to the bridge server. Do NOT embed the JSON in the message — send it separately via exec.

   ```
   exec: curl -s -X POST http://localhost:18792/workout -H "Content-Type: application/json" -d '<JSON>'
   ```

   > **Note:** Replace `localhost:18792` with your configured bridge URL if different.

   The JSON must match this schema:

   ```json
   {
     "workout_id": "uuid-string",
     "muscle_groups": ["chest", "triceps"],
     "work": {
       "warmup": {
         "exercises": [
           { "id": "uuid", "position": 0, "duration": 600, "name": "Treadmill Walk", "instructions": "max 200 chars", "equipment": "Treadmill" }
         ]
       },
       "main": {
         "exercises": [
           { "id": "uuid", "position": 0, "name": "Bench Press", "instructions": "max 200 chars", "equipment": "Barbell", "muscle_groups": ["chest"], "sets": [{"reps": 10}, {"reps": 8}] }
         ]
       },
       "cardio": {
         "exercises": [
           { "id": "uuid", "position": 0, "duration": 2700, "name": "StairMaster", "instructions": "max 200 chars", "equipment": "StairMaster" }
         ]
       },
       "cooldown": {
         "exercises": [
           { "id": "uuid", "position": 0, "duration": 300, "name": "Stretch", "instructions": "max 200 chars", "equipment": "None" }
         ]
       }
     }
   }
   ```

   Rules for the JSON:
   - Generate UUIDs for `workout_id` and each exercise `id`
   - `position` is 0-indexed within each section
   - `instructions` must be 200 characters or less
   - `duration` is in seconds
   - `sets` array: one entry per set with `reps` as a number
   - Map warmup stretches/walks to `warmup`, all strength exercises (compounds + hypertrophy + finisher) to `main`, stairmaster/cardio to `cardio`, post-workout stretching to `cooldown`
   - If no exercises for a section, use an empty array
   - If the POST fails, retry once. If it still fails, tell the user the app delivery failed but the workout is in the message.

8. **Handle pre-start adjustments.** If the user wants to swap exercises before starting (machine taken, preference, etc.), suggest 2-3 alternatives from the same category and update the plan.
   - **Message-initiated swap** (user asks in chat): Suggest alternatives, update the plan, and POST the updated workout JSON to the bridge via exec (same curl command as step 7). The app picks up the change via its sync poll.
   - **App-initiated removal** (see "App-Initiated Modifications" below): The bridge notifies you via `[app-sync]` message. Acknowledge it. Do NOT re-post to the bridge — the app already has the updated version.

**Note:** After the exec POST, the workout is delivered to the Pixelated Fitness iOS app. The user tracks sets and exercises in the app at their own pace — Phase 2 block-by-block delivery over messaging is not needed. Skip straight to Phase 3 (post-workout logging) once the user signals they're done or pastes their workout summary from the app.

### App-Initiated Modifications

When a message arrives with `[app-sync]` prefix, the Pixelated Fitness app has modified the current workout. Examples:
- "[app-sync] User removed Cable Flyes from today's workout"
- "[app-sync] User removed Cable Flyes; User removed Diamond Push-Ups"

**Response behavior:**
1. Acknowledge briefly: "Got it, dropped Cable Flyes."
2. Do NOT re-emit a `[workout-bridge:{...}]` marker — the app already has the updated workout (it made the change).
3. Update your internal view of the workout for logging purposes. When Phase 3 logging happens, reflect the removal accurately.
4. If the removal seems concerning (e.g., removing all compound exercises), gently ask about it — but don't block.

### Phase 2 — Block-by-Block Delivery (Messaging-only fallback)

Only use this phase if the user explicitly asks for block-by-block delivery over messaging (e.g., doesn't have the app open). Otherwise skip to Phase 3.

When the user says "let's go" / "start" / "ready" or similar, begin delivering blocks one at a time.

**Block sequence:**
1. Warmup (stretches, incline walk, feeder sets)
2. Primary Compounds
3. Secondary Hypertrophy
4. Finisher
5. Cardio (if applicable for the day)

**Block format:**

```
{Block Name}
1. {Exercise} — {sets}x{reps} @ {weight} ({rest})
2. {Exercise} — {sets}x{reps} @ {weight} ({rest})
—
Cues: {brief form cue if relevant}
—
Say "next" when done, or swap anything.
```

Keep each block to 3-8 lines. Phone-friendly. No walls of text.

**Between blocks:**
- Wait for the user to say "done" / "next" / "finished" or similar before sending the next block.
- If the user goes quiet and comes back later, pick up where you left off. Don't restart.
- If context compacts mid-workout and you lose track of which block was last, ask the user where they are rather than restarting.

**Mid-block swaps:**
- If the user says "machine is taken" / "swap" / "what else can I do" / "alternative":
  - Suggest 2-3 alternatives from the same exercise category immediately. No delay, no judgment.
  - Pull from the exercise library first; use general training knowledge if the library is thin for that category.
  - Adjust weight recommendation if the alternative uses different equipment.
  - Let the user pick. Note the swap (planned X, doing Y instead).
- If the user adjusts weight or reps before or during a block, acknowledge and update. Track the change for logging.

**After the last block:**
- Transition to Phase 3.

### Phase 3 — Post-Workout Logging

After all blocks are delivered and completed:

1. **Prompt for feedback.** Something brief: "Good session. How'd it feel? Anything to note?" or "Nice work. Anything to log beyond what we covered?"
2. **Accept natural language.** The user might say "felt good, curls were easy" or just "solid." That's enough.
3. **Don't interrogate.** Do NOT ask for RPE, nutrition, sleep, session rating, or pump quality unless the user volunteers it. At most ONE clarifying question if something is genuinely ambiguous (e.g., "Did you end up doing the finisher?"). Otherwise, log as-is.
4. **Build the log from the conversation.** The block-by-block delivery + any swaps + the user's feedback IS the primary data source. Don't make the user repeat what already happened in the conversation.
5. **Create the log, update profile.** Follow the logging workflow below.

## Log a Workout

Whether logging from a block-by-block session or a standalone report (e.g., "just did chest and biceps, hit 185 on incline for 4x10"):

1. **Extract what was provided.** Don't interrogate for missing data. Log what the user gives, fill gaps from the session conversation or with reasonable defaults.
2. **If a block-by-block session happened**, use the conversation as the primary source: planned exercises, any swaps made, weight/rep adjustments, and post-session feedback. Don't ask the user to repeat information already in the conversation.
3. **Create log file** at `logs/YYYY-MM-DD-{routine-slug}.md`. The routine slug matches the split template filename (e.g., `day-1-chest-biceps`). For ad-hoc sessions, use a descriptive slug (e.g., `arm-pump`, `stairmaster-only`).
4. **Frontmatter:**

```yaml
---
title: "Day {N} — {Focus}"
type: log
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - workout
related:
  - routines/split/day-{N}-{slug}.md
routine_id: fitness-split-day-{N}-{slug}
---
```

For ad-hoc sessions, omit `routine_id` or use a non-split ID so they don't advance the cycle.

5. **Body** follows existing log format:
   - Workout Summary (date, focus, context)
   - Exercises by block (warm-up, primary compound, secondary hypertrophy, finisher, cardio)
   - Session Notes (include any mid-workout swaps and why)
   - Nutrition + Recovery ("None provided." if not volunteered)
   - Progression Notes (what to do next time based on double-progression model)

For exercises that were performed but details weren't given, log as "performed, details not provided" rather than omitting. RPE, session rating, and pump quality: include only if the user volunteered them.

6. **Update athlete profile.** Update the working weights table in `athlete-profile.md` if any weights or statuses changed. Add new exercises if they aren't in the table yet.

## Bi-Weekly Check-In

Every 2 weeks or when the user asks for a fitness review:

1. **Read all logs** from the last 14 days in `logs/`.
2. **Analyze:**
   - Volume per muscle group (sets/week)
   - Training frequency (days hit vs. expected)
   - Progression wins (weight increases, rep PRs)
   - Progression stalls (same weight/reps 3+ sessions)
   - Exercise rotation staleness (same exercises repeated too often for same split day)
   - Consistency patterns (missed days, shortened sessions)
3. **Report concisely:**
   - What's working (keep doing)
   - What needs attention (specific, actionable)
   - Recommendations (exercise swaps, volume adjustments, deload timing)
4. **If routine templates need updating**, edit them directly and update the `updated` date in frontmatter.

## Hard Rules

1. **Never duplicate protocol content into responses.** Always read the source files fresh — they may have been updated.
2. **Respect the rolling cycle.** Derive current day from the most recent split log's `routine_id`, not the calendar. The 7-day split is not calendar-fixed.
3. **Don't interrogate.** Log what the user provides, fill gaps with reasonable defaults. Only ask when something is genuinely ambiguous.
4. **Rotation is mandatory.** Never repeat the exact same exercise lineup for the same split day on consecutive cycles. Vary angle, grip, or equipment.
5. **Phone-friendly output.** Tight formatting, short lines, no walls of text. The user reads this on their phone.
6. **Ad-hoc sessions don't advance the cycle.** Only logs with `routine_id` matching `fitness-split-day-*` count for cycle tracking.
7. **Always resend on request.** If the user asks for a workout and you already sent one, resend it in full. Never say "scroll up" or "already sent." Just deliver it again.
