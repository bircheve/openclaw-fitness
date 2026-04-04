---
title: Double Progression Method
type: principle
created: 2026-02-01
updated: 2026-02-01
tags:
  - progression
  - hypertrophy
  - methodology
related:
  - training/training-philosophy.md
confidence: high
---

# Double Progression Method

The primary progression model for all hypertrophy training. Simple, effective, and sustainable.

## The Method

1. **Set a rep range** (e.g., 10-12 reps)
2. **Start at the bottom** of the range with a challenging weight
3. **Build reps** session over session until hitting the top of the range on ALL working sets
4. **Increase weight** by the smallest increment (typically 5 lbs for upper, 10 lbs for lower)
5. **Reset to bottom** of rep range and repeat

## Example Progression

Incline Barbell Press with 10-12 rep range:

| Session | Weight | Set 1 | Set 2 | Set 3 | Set 4 | Action |
|---------|--------|-------|-------|-------|-------|--------|
| Week 1 | 185 lbs | 10 | 10 | 9 | 8 | Maintain |
| Week 2 | 185 lbs | 11 | 10 | 10 | 9 | Maintain |
| Week 3 | 185 lbs | 12 | 11 | 11 | 10 | Maintain |
| Week 4 | 185 lbs | 12 | 12 | 11 | 11 | Maintain |
| Week 5 | 185 lbs | 12 | 12 | 12 | 12 | **Increase** |
| Week 6 | 190 lbs | 10 | 10 | 9 | 8 | Maintain |

## Why This Works

### Ensures Real Strength Gains
You only add weight when you've proven you can handle the current weight for the full rep range. No guessing, no ego lifting.

### Reduces Injury Risk
Premature loading is a leading cause of gym injuries. Double progression prevents jumping weight before you're ready.

### Provides Clear Progression Criteria
No ambiguity. Either you hit all your reps or you don't. Progress is objective and trackable.

### Works With Hypertrophy Rep Ranges
Unlike strength programs that use low reps, double progression shines in the 8-15 rep range where small improvements are meaningful.

## Rep Ranges by Exercise Type

| Exercise Type | Rep Range | Weight Jump |
|---------------|-----------|-------------|
| Compound (barbell) | 8-10 | 5 lbs |
| Compound (dumbbell) | 10-12 | 5 lbs total (2.5 each) |
| Isolation (cables/machines) | 12-15 | Smallest increment |
| Isolation (dumbbells) | 12-15 | 5 lbs total |

## Tracking in Workout Logs

Use the `progression_notes` field to track status:

```yaml
progression_notes:
  - exercise_id: fitness-incline-barbell-press
    status: ready-to-increase
    next_weight_lbs: 190
    notes: "Hit 12, 12, 12, 12 - increase next session"
```

### Status Values
- `maintain`: Not yet at top of range on all sets
- `progressing`: Getting closer, keep current weight
- `ready-to-increase`: Hit top of range on all sets, increase next session
- `deload`: Struggling, reduce weight 10-15%

## When to Deload

If you fail to progress for 2-3 consecutive sessions:
1. Reduce weight by 10-15%
2. Build back up using double progression
3. You'll often surpass your previous best

Deload triggers:
- Missing reps you previously hit
- Form breakdown on working sets
- Excessive fatigue or joint pain
- Life stress affecting recovery

## Common Mistakes

### Increasing Too Fast
Adding weight before hitting the top of the range leads to stalled progress and potential injury.

### Rep Range Too Narrow
A range of 10-12 gives room to progress. A range of 10-10 (single target) doesn't work.

### Ignoring Failed Sets
If your last set is always 3-4 reps short, the weight is too heavy. Drop down and build properly.

### Different Reps Each Session
Inconsistent effort makes tracking impossible. Every set should be close to failure (RPE 8-10).

## The Long Game

Double progression is slow but sustainable. A 5 lb increase every 3-4 weeks adds up:
- 60-80 lbs per year on compounds
- Consistent, injury-free gains
- No plateaus from jumping too fast

Trust the process. The weights will climb if you're consistent.
