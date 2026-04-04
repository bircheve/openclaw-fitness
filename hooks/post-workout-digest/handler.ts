import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";

const OPENCLAW_DIR = path.join(os.homedir(), ".openclaw");
const LOGS_DIR = path.join(OPENCLAW_DIR, "logs");
const PROGRESS_LOG = path.join(LOGS_DIR, "fitness-progress.jsonl");
const SIGNALS_LATEST = path.join(LOGS_DIR, "fitness-signals-latest.json");

// Detect workout log content in outbound messages
const WORKOUT_LOG_INDICATORS = [
  /routine_id:\s*day-\d/i,
  /\bexercise[s]?:.*\bsets?\b/i,
  /\blogged\b.*\bday\s*\d/i,
  /\bworkout\s+logged\b/i,
  /##\s*(Primary|Compound|Hypertrophy|Finisher|Cardio)/i,
  /\b\d+\s*lbs?\b.*\b\d+\s*reps?\b/i,
];

type ExerciseData = {
  name: string;
  weight?: number;
  reps?: number[];
  sets?: number;
};

type Signal = {
  exercise: string;
  type: "pr" | "stall" | "threshold" | "info";
  detail: string;
};

function looksLikeWorkoutLog(content: string): boolean {
  let hits = 0;
  for (const pattern of WORKOUT_LOG_INDICATORS) {
    if (pattern.test(content)) hits++;
  }
  return hits >= 2;
}

function parseExercisesFromContent(content: string): ExerciseData[] {
  const exercises: ExerciseData[] = [];

  const lines = content.split("\n");
  for (const line of lines) {
    // Pattern: "- Exercise Name: 185 lbs x 10, 9, 8, 7" or similar
    const match = line.match(
      /[-*]\s*\**([^:*]+?)\**:?\s*(\d+)\s*(?:lbs?|pounds?).*?(?:x|×)\s*([\d,\s]+)/i,
    );
    if (match) {
      const repsStr = match[3].split(/[,\s]+/).map((r) => parseInt(r, 10)).filter((n) => !isNaN(n));
      exercises.push({
        name: match[1].trim(),
        weight: parseInt(match[2], 10),
        reps: repsStr,
        sets: repsStr.length,
      });
      continue;
    }

    // Pattern: "Exercise Name — 4 sets — 70 lbs — 12, 11, 10, 9 reps"
    const altMatch = line.match(
      /[-*]\s*\**([^—*]+?)\**\s*—\s*(\d+)\s*sets?\s*—\s*(\d+)\s*(?:lbs?|pounds?)\s*—\s*([\d,\s]+)/i,
    );
    if (altMatch) {
      const repsStr = altMatch[4].split(/[,\s]+/).map((r) => parseInt(r, 10)).filter((n) => !isNaN(n));
      exercises.push({
        name: altMatch[1].trim(),
        weight: parseInt(altMatch[3], 10),
        reps: repsStr,
        sets: parseInt(altMatch[2], 10),
      });
    }
  }

  return exercises;
}

function parseProfileWeights(
  content: string,
): Map<string, { weight: number; reps: string; status: string }> {
  const weights = new Map<string, { weight: number; reps: string; status: string }>();

  const lines = content.split("\n");
  for (const line of lines) {
    const match = line.match(
      /\|\s*([^|]+?)\s*\|\s*(\d+)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|/,
    );
    if (match && !match[1].includes("Exercise") && !match[1].includes("---")) {
      weights.set(match[1].trim().toLowerCase(), {
        weight: parseInt(match[2], 10),
        reps: match[3].trim(),
        status: match[4].trim(),
      });
    }
  }

  return weights;
}

function parseProfilePRs(
  content: string,
): Map<string, { weight: number; reps: number }> {
  const prs = new Map<string, { weight: number; reps: number }>();

  const prSection = content.match(/## Personal Records\n([\s\S]*?)(?=\n##|$)/);
  if (!prSection) return prs;

  for (const line of prSection[1].split("\n")) {
    const match = line.match(
      /\|\s*([^|]+?)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|/,
    );
    if (match && !match[1].includes("Exercise") && !match[1].includes("---")) {
      prs.set(match[1].trim().toLowerCase(), {
        weight: parseInt(match[2], 10),
        reps: parseInt(match[3], 10),
      });
    }
  }

  return prs;
}

const handler = async (event: {
  type: string;
  action: string;
  context: Record<string, unknown>;
}) => {
  if (event.type !== "message" || event.action !== "sent") {
    return;
  }

  const ctx = event.context as {
    success?: boolean;
    content?: string;
    to?: string;
    channelId?: string;
    workspaceDir?: string;
  };

  if (ctx.success === false) return;

  const content = ctx.content;
  if (!content || typeof content !== "string") return;
  if (!looksLikeWorkoutLog(content)) return;

  const workspaceDir = ctx.workspaceDir || event.context.workspaceDir as string | undefined;
  if (!workspaceDir) return;

  try {
    const profilePath = path.join(
      workspaceDir as string,
      "fitness",
      "athlete-profile.md",
    );

    let profileContent = "";
    try {
      profileContent = await fs.readFile(profilePath, "utf-8");
    } catch {
      return; // No profile to compare against
    }

    const exercises = parseExercisesFromContent(content);
    if (exercises.length === 0) return;

    const profileWeights = parseProfileWeights(profileContent);
    const profilePRs = parseProfilePRs(profileContent);
    const signals: Signal[] = [];

    for (const ex of exercises) {
      const key = ex.name.toLowerCase();
      const profile = profileWeights.get(key);
      const pr = profilePRs.get(key);

      if (!ex.weight) continue;

      // PR detection: new weight exceeds known PR
      if (pr && ex.weight > pr.weight) {
        signals.push({
          exercise: ex.name,
          type: "pr",
          detail: `New weight PR: ${ex.weight} lbs (previous: ${pr.weight} lbs)`,
        });
      } else if (pr && ex.weight === pr.weight && ex.reps) {
        const maxReps = Math.max(...ex.reps);
        if (maxReps > pr.reps) {
          signals.push({
            exercise: ex.name,
            type: "pr",
            detail: `New rep PR at ${ex.weight} lbs: ${maxReps} reps (previous: ${pr.reps})`,
          });
        }
      }

      // Threshold detection: all sets at top of rep range
      if (ex.reps && ex.reps.length >= 3) {
        const topRange = 12;
        const allAtTop = ex.reps.every((r) => r >= topRange);
        if (allAtTop) {
          signals.push({
            exercise: ex.name,
            type: "threshold",
            detail: `All ${ex.reps.length} sets at ${Math.min(...ex.reps)}+ reps at ${ex.weight} lbs`,
          });
        }
      }

      // Stall detection: same weight as profile, status not progressing
      if (profile && ex.weight === profile.weight && profile.status === "--") {
        signals.push({
          exercise: ex.name,
          type: "stall",
          detail: `Same weight (${ex.weight} lbs) as profile, no progression noted`,
        });
      }

      // Info: basic data point
      if (ex.reps) {
        signals.push({
          exercise: ex.name,
          type: "info",
          detail: `${ex.weight} lbs x ${ex.reps.join(", ")} reps`,
        });
      }
    }

    if (signals.length === 0) return;

    const entry = {
      ts: new Date().toISOString(),
      exerciseCount: exercises.length,
      signals: signals.filter((s) => s.type !== "info"),
      allData: signals,
    };

    // Write to append-only log
    await fs.mkdir(LOGS_DIR, { recursive: true });
    await fs.appendFile(PROGRESS_LOG, JSON.stringify(entry) + "\n", "utf-8");

    // Write latest signals for next session bootstrap
    const latestSignals = {
      ts: entry.ts,
      signals: signals.filter((s) => s.type !== "info"),
      summary: signals
        .filter((s) => s.type !== "info")
        .map((s) => `${s.exercise}: ${s.detail}`)
        .join(". "),
    };
    await fs.writeFile(SIGNALS_LATEST, JSON.stringify(latestSignals, null, 2), "utf-8");

    if (latestSignals.signals.length > 0) {
      console.log(
        `[post-workout-digest] ${latestSignals.signals.length} signal(s): ${latestSignals.summary}`,
      );
    }
  } catch (err) {
    console.warn(
      "[post-workout-digest] Failed:",
      err instanceof Error ? err.message : String(err),
    );
  }
};

export default handler;
