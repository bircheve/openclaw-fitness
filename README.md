# openclaw-fitness

An AI-powered personal trainer that lives in [OpenClaw](https://openclaw.dev). It generates rolling-cycle workouts, coaches you through sessions, tracks progression, and syncs workouts to a companion iOS app at the gym.

## What is this?

This is an OpenClaw plugin that turns your AI agent into a knowledgeable personal trainer. It understands bodybuilding methodology, tracks your working weights across sessions, rotates exercises to prevent staleness, and adapts to your progress — all through natural conversation.

The system includes:
- **A coaching skill** that generates and delivers workouts
- **An onboarding flow** that learns your goals, equipment, and preferences
- **A bridge server** that syncs workouts to a companion iOS app
- **Hooks** that inject training context into every conversation
- **Cron jobs** for morning briefings, log reminders, and weekly summaries

## Features

- **Rolling 7-day training cycle** — not calendar-fixed. Miss a day? Pick up where you left off.
- **Conversational onboarding** — the coach asks about your goals, experience, equipment, and preferences to build your profile
- **Smart workout generation** — selects exercises from a library, rotates variations, and sets weights based on your progression history
- **Block-by-block delivery** — overview first, then one block at a time. Swap exercises mid-workout when machines are taken.
- **Real-time iOS app sync** — workouts push to the Pixelated Fitness companion app via a bridge server. Track sets, remove exercises, and submit feedback from your phone.
- **Double-progression tracking** — automatic weight increase suggestions when you hit the top of your rep range
- **Streak tracking** — weekly session counts, consistency streaks, and monthly comparisons
- **PR detection** — automatically flags new personal records in weight or reps
- **Stall detection** — identifies exercises stuck at the same weight for 3+ sessions
- **Bi-weekly check-ins** — proactive progress reviews with actionable recommendations
- **Exercise rotation** — never repeats the exact same lineup for the same muscle group on consecutive cycles
- **Comeback protocol** — adapts workouts after illness, injury, or extended breaks
- **Conversational logging** — no forms. Say "felt good, hit 185 on incline" and the coach logs it.

## Architecture

```
┌──────────┐    message    ┌──────────────┐    read/write    ┌─────────────────┐
│   You    │ ◄──────────► │  OpenClaw     │ ◄─────────────► │ Training Data   │
│          │              │  Agent        │                  │ (fitness/)      │
└──────────┘              │  + Skill      │                  │ - athlete profile│
                          │  + Hooks      │                  │ - routines      │
                          └──────┬───────┘                  │ - exercises     │
                                 │                           │ - logs          │
                          exec curl POST                     └─────────────────┘
                                 │
                          ┌──────▼───────┐      HTTP       ┌─────────────────┐
                          │ Bridge Server │ ◄────────────► │ iOS App         │
                          │ (Node.js)     │                │ (Pixelated      │
                          │ :18792        │                │  Fitness)       │
                          └──────────────┘                └─────────────────┘
```

## Prerequisites

- [OpenClaw](https://openclaw.dev) installed and configured
- Node.js 18+ (for the bridge server)
- Xcode 15+ (optional — only for the iOS app)

## Quick Start

### 1. Clone this repo

```bash
git clone https://github.com/YOUR_USERNAME/openclaw-fitness.git
cd openclaw-fitness
```

### 2. Run the installer

```bash
./install.sh
```

This copies skills, hooks, training content, and the extension to your `~/.openclaw/` directory. It will warn you before overwriting any existing files.

### 3. Register the extension

Add the following to your `~/.openclaw/openclaw.json`:

```json
{
  "plugins": {
    "allow": ["openclaw-fitness"],
    "entries": {
      "openclaw-fitness": { "enabled": true }
    },
    "installs": {
      "openclaw-fitness": {
        "source": "path",
        "spec": "~/.openclaw/extensions/openclaw-fitness",
        "sourcePath": "~/.openclaw/extensions/openclaw-fitness/index.ts",
        "installPath": "~/.openclaw/extensions/openclaw-fitness"
      }
    }
  }
}
```

### 4. Start the bridge server

```bash
cd bridge
cp .env.example .env   # Edit with your notification settings (optional)
node server.js
```

For auto-start on macOS, see `bridge/launchd/`.

### 5. Set up your profile

Start a conversation with your OpenClaw agent and say:

> "Set up fitness"

The onboarding skill will walk you through a 2-minute Q&A to configure your training profile.

### 6. Get your first workout

> "What's my workout?"

## Manual Installation

If you prefer to install manually instead of using `install.sh`:

| Source | Destination |
|--------|-------------|
| `training/` | `~/.openclaw/workspace/fitness/` |
| `skills/fitness/` | `~/.openclaw/workspace/skills/fitness/` |
| `skills/fitness-onboarding/` | `~/.openclaw/workspace/skills/fitness-onboarding/` |
| `hooks/workout-coach/` | `~/.openclaw/hooks/workout-coach/` |
| `hooks/workout-streak-tracker/` | `~/.openclaw/hooks/workout-streak-tracker/` |
| `hooks/post-workout-digest/` | `~/.openclaw/hooks/post-workout-digest/` |
| `extension/` | `~/.openclaw/extensions/openclaw-fitness/` |

Create the logs directory: `mkdir -p ~/.openclaw/workspace/fitness/logs`

Copy the athlete profile template: `cp training/athlete-profile.template.md ~/.openclaw/workspace/fitness/athlete-profile.md`

## Bridge Server Setup

The bridge server is a lightweight Node.js HTTP server that stores the current workout and relays modifications between the iOS app and the AI coach.

```bash
cd bridge
node server.js
# Workout bridge listening on 0.0.0.0:18792
```

Test it: `curl http://localhost:18792/health`

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `18792` | Bridge server port |
| `OPENCLAW_BIN` | `openclaw` | Path to OpenClaw binary |
| `NOTIFY_CHANNEL` | _(none)_ | OpenClaw channel for app-sync notifications |
| `NOTIFY_TARGET` | _(none)_ | Target for notifications (phone number, chat ID) |

### Auto-start on macOS

1. Edit `bridge/launchd/com.openclaw-fitness.bridge.plist.template`
2. Replace `{{NODE_PATH}}`, `{{BRIDGE_DIR}}`, and `{{LOG_DIR}}` with your paths
3. Copy to `~/Library/LaunchAgents/com.openclaw-fitness.bridge.plist`
4. Load: `launchctl load ~/Library/LaunchAgents/com.openclaw-fitness.bridge.plist`

## iOS App Setup

See [ios/README.md](ios/README.md) for build instructions and networking setup.

The iOS app is optional — the coaching skill works fully over messaging without it.

## How It Works

### A Typical Session

1. **Morning** — Cron job sends a one-line briefing: "Day 3 today — back + triceps"
2. **At the gym** — You say "what's my workout?" 
3. **Coach generates** — Reads your profile, determines cycle day, selects exercises, sets weights based on progression
4. **Workout delivered** — Overview sent to you + JSON pushed to the iOS app
5. **During workout** — Machine taken? "Swap lat pulldown" → 3 alternatives instantly
6. **After workout** — "How'd it feel?" → "Solid, curls were easy" → Coach logs everything
7. **Evening** — If you forgot to log, cron job nudges you

### Training Cycle

The program uses a **rolling 7-day split** (not tied to the calendar):

| Day | Focus | Cardio |
|-----|-------|--------|
| 1 | Chest + Biceps | 30-40 min stairmaster |
| 2 | Legs + Side Delts | None |
| 3 | Back + Triceps | 30-40 min stairmaster |
| 4 | Shoulders + Legs (light) | 20-30 min |
| 5 | Chest + Upper Push | 30-40 min stairmaster |
| 6 | Choice / Weak Point | Optional |
| 7 | Active Recovery Cardio | 75 min stairmaster |

A PPL (Push/Pull/Legs) alternative is included for 3-4 day schedules.

## Customization

### Adding exercises

Create a new `.md` file in `training/exercises/{muscle-group}/`:

```yaml
---
title: Exercise Name
type: exercise
primary_muscles:
  - target-muscle
equipment_required:
  - barbell
setup_cues:
  - "Setup instruction"
execution_cues:
  - "Execution instruction"
---

# Exercise Name

Description and notes.
```

### Modifying routines

Edit files in `training/routines/split/`. Each day defines exercise categories (not specific exercises) — the coach selects from the library.

### Changing the split

Modify `training/training-protocol.md` to change the weekly split structure, rep ranges, rest periods, or progression model.

## Cron Jobs

Optional scheduled jobs for morning briefings, log reminders, and weekly summaries. See [cron/README.md](cron/README.md) for setup instructions.

## Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `workout-coach` | `message:received` | Injects training context (cycle day, weights, progression) when workout keywords are detected |
| `workout-streak-tracker` | `agent:bootstrap` | Computes weekly session counts and consistency streaks on every session start |
| `post-workout-digest` | `message:sent` | Detects workout log content in outbound messages, computes PR/stall/threshold signals |

## File Structure

```
openclaw-fitness/
├── README.md                    # This file
├── install.sh                   # Automated installer
├── uninstall.sh                 # Clean removal
├── scripts/audit-pii.sh         # Pre-publish PII checker
├── extension/                   # OpenClaw bridge extension
├── skills/
│   ├── fitness/                 # Main coaching skill
│   └── fitness-onboarding/      # Onboarding Q&A
├── training/                    # Training content
│   ├── athlete-profile.*        # Template + example
│   ├── TRAINING.md              # Coaching playbook
│   ├── training-protocol.md     # Program structure
│   ├── exercises/               # Exercise library (13 files)
│   └── routines/                # Routine templates (14 files)
├── bridge/                      # Workout bridge server
├── hooks/                       # 3 OpenClaw hooks
├── cron/                        # Cron job templates
└── ios/                         # Pixelated Fitness iOS app
```

## Uninstalling

```bash
./uninstall.sh
```

This removes all installed files using the manifest created during installation. You'll also need to manually remove the plugin from `~/.openclaw/openclaw.json`.

## Contributing

Contributions welcome! Some ideas:

- Add more exercises to the library
- Create new routine templates (upper/lower split, full-body, etc.)
- Improve the iOS app (HealthKit integration, Apple Watch, etc.)
- Add new hooks (nutrition tracking, sleep correlation, etc.)

## License

MIT
