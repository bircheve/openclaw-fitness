# Bridge Server API Reference

The workout bridge server acts as the data layer between the AI coach and the iOS app. It stores the current workout, accepts modifications, and records completed workouts.

**Default URL:** `http://localhost:18792`

## Endpoints

### GET /health

Health check endpoint.

**Response:**
```json
{ "ok": true, "has_workout": true }
```

### GET /workout

Returns the current active workout.

**Response (200):**
```json
{
  "workout_id": "uuid-string",
  "muscle_groups": ["chest", "triceps"],
  "version": 1,
  "work": {
    "warmup": { "exercises": [...] },
    "main": { "exercises": [...] },
    "cardio": { "exercises": [...] },
    "cooldown": { "exercises": [...] }
  }
}
```

**Response (404):** No active workout.
```json
{ "error": "no workout" }
```

### POST /workout

Push a new workout (called by the AI coach).

**Request Body:**
```json
{
  "workout_id": "uuid-string",
  "muscle_groups": ["chest", "biceps"],
  "work": {
    "warmup": {
      "exercises": [
        {
          "id": "uuid",
          "position": 0,
          "duration": 600,
          "name": "Treadmill Walk",
          "instructions": "5 min incline walk at moderate pace",
          "equipment": "Treadmill"
        }
      ]
    },
    "main": {
      "exercises": [
        {
          "id": "uuid",
          "position": 0,
          "name": "Incline Barbell Press",
          "instructions": "3-5 sec eccentric, full ROM",
          "equipment": "Barbell",
          "muscle_groups": ["chest"],
          "sets": [
            { "reps": 10 },
            { "reps": 10 },
            { "reps": 8 },
            { "reps": 8 }
          ]
        }
      ]
    },
    "cardio": {
      "exercises": [
        {
          "id": "uuid",
          "position": 0,
          "duration": 1800,
          "name": "StairMaster",
          "instructions": "Zone 2, 130-150 BPM",
          "equipment": "StairMaster"
        }
      ]
    },
    "cooldown": {
      "exercises": [
        {
          "id": "uuid",
          "position": 0,
          "duration": 300,
          "name": "Stretch",
          "instructions": "Full body stretch, focus on worked muscles",
          "equipment": "None"
        }
      ]
    }
  }
}
```

**Response (200):** `{ "ok": true }`
**Response (400):** Invalid JSON or missing required fields.

### PATCH /workout

Modify the current workout (called by the iOS app).

**Request Body:**
```json
{
  "action": "remove_exercise",
  "exercise_id": "uuid-of-exercise-to-remove"
}
```

**Response (200):** `{ "ok": true, "version": 2 }`
**Response (404):** No active workout or exercise not found.

**Side effects:** Sends an `[app-sync]` notification to the AI coach (if notifications are configured).

### POST /workout/:id/complete

Submit workout completion and feedback (called by the iOS app).

**Request Body:**
```json
{
  "feedback": {
    "rating": 4,
    "notes": "Good session, felt strong"
  },
  "completion": {
    "completedSets": {
      "exercise-uuid-1": [0, 1, 2, 3],
      "exercise-uuid-2": [0, 1, 2]
    },
    "completedTimed": ["exercise-uuid-3"],
    "removedExercises": ["exercise-uuid-4"]
  }
}
```

**Response (200):** `{ "ok": true }`

**Side effects:**
- Appends the workout to `history.json`
- Clears the current workout from `store.json`

### GET /history

Returns all completed workouts.

**Response (200):**
```json
[
  {
    "workout": { ... },
    "feedback": { "rating": 4, "notes": "..." },
    "completion": { ... },
    "completed_at": "2026-03-28T07:15:00.000Z"
  }
]
```

## Data Storage

- `store.json` — Current active workout (single file, overwritten on each POST)
- `history.json` — Array of completed workouts (prepended, newest first)

Both files are in the bridge server's directory. They are excluded from git via `.gitignore`.

## CORS

All endpoints include `Access-Control-Allow-Origin: *` headers for cross-origin access from the iOS app.
