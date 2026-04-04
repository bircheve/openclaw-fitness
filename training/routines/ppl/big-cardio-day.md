---
id: routine-big-cardio-day
title: Big Cardio Day
type: routine
created: 2026-02-01
updated: 2026-02-01
tags:
  - cardio
  - conditioning
  - active-recovery
related:
  - training/routines/ppl/push-day-a.md
program: ppl-hypertrophy
split: push-pull-legs
day_in_cycle: 7
estimated_duration: 90
target_muscle_groups:
  - cardiovascular
  - weak-points
exercises:
  - exercise_id: stairmaster
    sets: 1
    rep_range: "45-60 min"
    rest_seconds: 0
    technique: steady-state
  - exercise_id: weak-point-work
    sets: 6-9
    rep_range: "12-15"
    rest_seconds: 45
    technique: standard
cardio_finisher:
  exercise_id: stairmaster
  duration_minutes: 45
  target_intensity: moderate
training_style:
  tempo_eccentric: 3-5
  mind_muscle_connection: true
  failure_training: false
---

# Big Cardio Day

Extended cardio session with optional weak point training.

## Session Flow

1. **Extended Cardio** (45-60 min): Stairmaster at moderate intensity
2. **Weak Point Work** (20-30 min): Optional targeted muscle work
3. **Stretching** (10 min): Full body flexibility work

## Primary Focus: Cardio

This is primarily a cardio day. The stairmaster session is extended:

| Duration | Intensity | Heart Rate |
|----------|-----------|------------|
| 45-60 min | Moderate | 130-150 BPM |

### Cardio Options

While stairmaster is preferred, alternatives for variety:
- Incline treadmill walk (15% incline, 3.5 mph)
- Stationary bike (moderate resistance)
- Rowing machine

Can split into segments:
- 30 min stairmaster + 20 min incline walk
- 45 min stairmaster straight through

## Secondary Focus: Weak Point Work

After cardio, optionally hit a lagging muscle group with 2-3 exercises:

### Options Based on Weak Points

**If arms are lagging:**
- 3 sets curls
- 3 sets tricep pushdowns
- 3 sets hammer curls

**If side delts are lagging:**
- 4 sets lateral raises
- 3 sets face pulls

**If calves are lagging:**
- 4 sets standing calf raise
- 4 sets seated calf raise

**If rear delts are lagging:**
- 3 sets rear delt fly
- 3 sets face pulls
- 3 sets reverse pec deck

## Execution Notes

- This is NOT a heavy lifting day
- Weak point work is supplementary, not primary
- Keep weights moderate, focus on pump and connection
- Don't destroy yourself - you're back to Push Day A tomorrow

## Why This Day Exists

1. **Cardiovascular health**: Extended cardio session for heart health
2. **Calorie burn**: Supports lean physique goals
3. **Active recovery**: Light movement helps recovery
4. **Weak point development**: Extra volume for lagging areas
5. **Mental discipline**: Showing up 7 days a week

## This Is Not A Rest Day

Some programs have rest days. This is not one of them.

You show up, you do cardio, you optionally hit weak points. Every. Single. Week.

## Tracking in Logs

Log this day like any other:

```yaml
exercises:
  - exercise_id: stairmaster
    duration_minutes: 50
    intensity: moderate
    average_heart_rate: 140
  - exercise_id: lateral-raise
    sets:
      - { set_number: 1, type: working, weight_lbs: 20, reps: 15, rpe: 7 }
      - { set_number: 2, type: working, weight_lbs: 20, reps: 14, rpe: 8 }
      - { set_number: 3, type: working, weight_lbs: 20, reps: 12, rpe: 8 }
      - { set_number: 4, type: working, weight_lbs: 20, reps: 11, rpe: 9 }
```
