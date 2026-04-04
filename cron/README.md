# Cron Job Templates

These are template cron jobs for the fitness plugin. To use them, you need to merge them into your `~/.openclaw/cron/jobs.json` file.

## Setup

1. Open `~/.openclaw/cron/jobs.json`
2. Copy the job definitions from the template files below into the `jobs` array
3. Replace all `{{PLACEHOLDER}}` values with your own configuration:
   - `{{TIMEZONE}}` — Your timezone (e.g., `America/Denver`, `America/New_York`, `Europe/London`)
   - `{{CHANNEL}}` — Your OpenClaw delivery channel (e.g., `imessage`, `telegram`, `slack`)
   - `{{TARGET}}` — Your delivery target (e.g., phone number, chat ID)
4. Generate unique UUIDs for each job's `id` field (run `uuidgen` in your terminal)

## Available Templates

### morning-briefing.template.json
Daily training focus reminder. Runs at 5:30 AM, checks which day in the training cycle you're on, and sends a one-line summary of today's muscle group focus.

### log-reminder.template.json
Evening workout log reminder. Runs at 8:00 PM, checks if a workout log exists for today. If not, sends a gentle nudge to log the session.

### weekly-summary.template.json
Weekly progress analysis. Runs Sunday at 8:00 PM, reviews the past 7-14 days of workout logs and sends a brief consistency and progress summary.
