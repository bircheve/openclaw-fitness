---
name: fitness-onboarding
description: Triggers when user says "set up fitness", "configure training", "get started with fitness", or when the fitness skill detects no athlete-profile.md exists
---

# Fitness Onboarding

## Trigger

- User says "set up fitness", "configure training", "get started", "set up my profile", or similar
- The fitness skill redirects here when `~/.openclaw/workspace/fitness/athlete-profile.md` does not exist or contains only the template placeholders

## Purpose

Conduct a conversational Q&A to learn about the user's goals, experience, equipment, and preferences, then generate a populated `athlete-profile.md` and select the right training program.

## Flow

This is a conversation, not a form. Be natural. Ask one phase at a time, adapt based on answers. Don't dump all questions at once.

### Phase 1 — Goals and Experience

Start with a warm intro:

> "Let's get you set up. I'll ask a few questions to build your training profile — takes about 2 minutes."

Then ask (conversationally, not as a numbered list):

1. **Fitness goals** — What are you training for? (hypertrophy/muscle building, strength, general fitness, weight loss, athletic performance, or a combination)
2. **Experience level** — How long have you been training consistently? (just starting out, a few months, 1-2 years, 3+ years)
3. **Training days** — How many days per week can you realistically train? (3-7)
4. **Session length** — How long is a typical session? (30 min, 45 min, 60 min, 75 min, 90 min)

### Phase 2 — Equipment and Environment

5. **Gym type** — What kind of gym do you have access to?
   - Full commercial gym (free weights, machines, cables, cardio)
   - Home gym with barbell + rack
   - Home gym with dumbbells only
   - Bodyweight / minimal equipment
6. **Training style preference** — Any preference? (bodybuilding, powerlifting, functional/CrossFit-style, no preference — I'll recommend)

### Phase 3 — Limitations

7. **Injuries or limitations** — Any current injuries, chronic issues, or movements you need to avoid? (free text — "none" is fine)
8. **Exercise preferences** — Any exercises you love or hate? (optional — helps with programming)

### Phase 4 — Preferences

9. **Training time** — When do you usually train? (morning, afternoon, evening — affects warmup recommendations)
10. **Cardio preference** — How do you feel about cardio? (love it, tolerate it, minimal, skip it entirely)

## After Q&A

### 1. Select the training program

Based on the answers, select the appropriate routine:

| Days/Week | Goal | Program |
|-----------|------|---------|
| 6-7 | Hypertrophy | 7-day split (default) |
| 5 | Hypertrophy/Strength | 7-day split, use Day 7 as rest |
| 3-4 | Any | PPL (Push/Pull/Legs) |
| 3-4 | Strength | PPL with heavier compounds |

For beginners (< 6 months): reduce volume per session — 8-10 working sets per muscle group instead of 10-16.

### 2. Generate the athlete profile

Read the template at `$FITNESS_DIR/athlete-profile.template.md` and populate it with the user's answers:

- **Training style:** From goal + style preference answers
- **Gym:** From gym type answer
- **Typical session time:** From training time answer
- **Program:** Selected program name
- **Target:** From body composition goal (if mentioned) or "General fitness"
- **Approach:** Derived from goals
- **Injury History:** From limitations answer
- **Preferences:** From exercise preferences + cardio preference answers

Leave the working weights table empty — it will be populated after the first logged workout.

Write the populated profile to `$FITNESS_DIR/athlete-profile.md`.

### 3. Confirm and hand off

Tell the user:
- Which program was selected and why
- A brief overview of how the training cycle works (e.g., "You'll follow a rolling 7-day split — each day targets different muscle groups. The cycle isn't tied to the calendar, so if you miss a day, you just pick up where you left off.")
- How to get started: **"Ask me 'what's my workout' whenever you're ready for a session."**
- Mention the iOS app if relevant: "If you have the Pixelated Fitness iOS app connected, your workouts will sync automatically."

## Tone

- Friendly and encouraging, but not over-the-top
- Efficient — don't pad with motivational filler
- Direct questions, accept short answers
- If the user gives minimal answers ("idk" or "whatever you think"), make reasonable defaults and move on

## Paths

```
FITNESS_DIR = ~/.openclaw/workspace/fitness
```

| Purpose | Path |
|---------|------|
| Profile template | `$FITNESS_DIR/athlete-profile.template.md` |
| Profile output | `$FITNESS_DIR/athlete-profile.md` |
| Split routines | `$FITNESS_DIR/routines/split/` |
| PPL routines | `$FITNESS_DIR/routines/ppl/` |
