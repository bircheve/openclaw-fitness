import fs from "node:fs/promises";
import path from "node:path";

const WORKOUT_KEYWORDS =
  /\b(workout|gym|training|lift|lifting|let'?s lift|what'?s my workout|chest|back|legs|shoulders|arms|biceps|triceps|stairmaster|cardio|deload)\b/i;

function extractFrontmatter(content: string): Record<string, string> {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};
  const pairs: Record<string, string> = {};
  for (const line of match[1].split("\n")) {
    const kv = line.match(/^(\w[\w_-]*):\s*(.+)/);
    if (kv) pairs[kv[1].trim()] = kv[2].trim().replace(/^["']|["']$/g, "");
  }
  return pairs;
}

function extractRoutineId(content: string): string | undefined {
  const fm = extractFrontmatter(content);
  return fm.routine_id;
}

function dayNumberFromRoutineId(routineId: string): number | undefined {
  const match = routineId.match(/day-(\d+)/);
  return match ? parseInt(match[1], 10) : undefined;
}

function parseDateFromFilename(filename: string): Date | null {
  const match = filename.match(/^(\d{4}-\d{2}-\d{2})/);
  if (!match) return null;
  const d = new Date(match[1] + "T12:00:00");
  return isNaN(d.getTime()) ? null : d;
}

function daysBetween(a: Date, b: Date): number {
  return Math.round(Math.abs(b.getTime() - a.getTime()) / (1000 * 60 * 60 * 24));
}

function extractWorkingWeightsTable(content: string): string {
  const lines = content.split("\n");
  const tableStart = lines.findIndex((l) => l.includes("| Exercise"));
  if (tableStart < 0) return "";

  const tableLines: string[] = [];
  for (let i = tableStart; i < lines.length; i++) {
    if (!lines[i].startsWith("|")) break;
    tableLines.push(lines[i]);
  }
  return tableLines.join("\n");
}

const handler = async (event: {
  type: string;
  action: string;
  context: Record<string, unknown>;
  messages: string[];
}) => {
  if (event.type !== "message" || event.action !== "received") {
    return;
  }

  const content = (event.context.content as string) ?? "";
  if (!WORKOUT_KEYWORDS.test(content)) {
    return;
  }

  const workspaceDir = event.context.workspaceDir as string | undefined;
  if (!workspaceDir) {
    return;
  }

  const fitnessBase = path.join(workspaceDir, "fitness");
  const logsDir = path.join(fitnessBase, "logs");
  const routinesDir = path.join(fitnessBase, "routines", "split");
  const profilePath = path.join(fitnessBase, "athlete-profile.md");

  try {
    // 1. Find most recent workout log
    const logFiles = (await fs.readdir(logsDir))
      .filter((f) => f.endsWith(".md"))
      .sort()
      .reverse();

    if (logFiles.length === 0) {
      return;
    }

    const latestLogFile = logFiles[0];
    const latestLogContent = await fs.readFile(path.join(logsDir, latestLogFile), "utf-8");
    const latestDate = parseDateFromFilename(latestLogFile);

    // 2. Determine cycle day
    const routineId = extractRoutineId(latestLogContent);
    let lastDay: number | undefined;
    if (routineId) {
      lastDay = dayNumberFromRoutineId(routineId);
    }

    let nextDay: number;
    if (lastDay !== undefined) {
      nextDay = lastDay >= 7 ? 1 : lastDay + 1;
    } else {
      nextDay = 1; // Default to day 1 if can't determine
    }

    // 3. Calculate gap
    const now = new Date();
    const gapDays = latestDate ? daysBetween(latestDate, now) : undefined;

    // 4. Read routine template
    const routineFiles = await fs.readdir(routinesDir);
    const dayFile = routineFiles.find((f) => f.startsWith(`day-${nextDay}-`));
    let routineContent = "";
    if (dayFile) {
      routineContent = await fs.readFile(path.join(routinesDir, dayFile), "utf-8");
    }

    // Extract routine title
    const titleMatch = routineContent.match(/^#\s+(.+)/m);
    const routineTitle = titleMatch ? titleMatch[1] : `Day ${nextDay}`;

    // Extract key sections (target muscles, block structure)
    const targetMatch = routineContent.match(/## Target Muscles\n([\s\S]*?)(?=\n##|$)/);
    const targetMuscles = targetMatch ? targetMatch[1].trim() : "";

    // Extract cardio info from frontmatter
    const routineFm = extractFrontmatter(routineContent);
    const cardioAfter = routineFm.cardio_after !== "false";
    const cardioDuration = routineFm.cardio_duration_minutes || "30-40";

    // 5. Read athlete profile for working weights
    let profileContent = "";
    try {
      profileContent = await fs.readFile(profilePath, "utf-8");
    } catch {
      // Profile may not exist
    }

    const weightsTable = extractWorkingWeightsTable(profileContent);

    // Find exercises with notable progression status
    const progressing: string[] = [];
    const readyToIncrease: string[] = [];
    if (weightsTable) {
      for (const line of weightsTable.split("\n")) {
        if (line.includes("progressing")) {
          const exMatch = line.match(/\|\s*([^|]+?)\s*\|/);
          if (exMatch) progressing.push(exMatch[1].trim());
        }
        if (line.includes("ready-to-increase")) {
          const exMatch = line.match(/\|\s*([^|]+?)\s*\|/);
          if (exMatch) readyToIncrease.push(exMatch[1].trim());
        }
      }
    }

    // 6. Check if today's log already exists
    const todayStr = now.toISOString().slice(0, 10);
    const todayLog = logFiles.find((f) => f.startsWith(todayStr));

    // 6b. Check athlete profile coaching notes for today's date
    let profileMentionsToday = false;
    if (!todayLog && profileContent) {
      const coachingNotesMatch = profileContent.match(/## Coaching Notes\n([\s\S]*?)(?=\n##|$)/);
      if (coachingNotesMatch) {
        profileMentionsToday = coachingNotesMatch[1].includes(todayStr);
      }
    }

    // 7. Build the brief
    const parts: string[] = [];
    parts.push(`[Training Context]`);

    if (todayLog) {
      parts.push(`Today's log already exists: ${todayLog}`);
    } else if (profileMentionsToday) {
      parts.push(`WARNING: Athlete profile has a coaching note for ${todayStr} but no log file exists. Auto-create a log from available context.`);
    }

    parts.push(`Next session: ${routineTitle}`);

    if (gapDays !== undefined) {
      parts.push(`Last session: ${gapDays} day${gapDays !== 1 ? "s" : ""} ago (${latestLogFile.replace(".md", "")})`);
      if (gapDays >= 7) {
        parts.push(`Extended gap detected (${gapDays} days). Per training protocol: restart compounds 5-10% lighter.`);
      }
    }

    if (targetMuscles) {
      parts.push(`Targets: ${targetMuscles.replace(/\n/g, " ").replace(/- /g, "")}`);
    }

    if (cardioAfter) {
      parts.push(`Cardio: ${cardioDuration} min stairmaster after lifting`);
    } else {
      parts.push(`Cardio: none (leg day)`);
    }

    if (readyToIncrease.length > 0) {
      parts.push(`Ready to increase weight: ${readyToIncrease.join(", ")}`);
    }

    if (progressing.length > 0) {
      parts.push(`Currently progressing: ${progressing.join(", ")}`);
    }

    if (weightsTable) {
      parts.push(`\nWorking weights:\n${weightsTable}`);
    }

    event.messages.push(parts.join("\n"));
  } catch (err) {
    console.warn(
      "[workout-coach] Failed:",
      err instanceof Error ? err.message : String(err),
    );
  }
};

export default handler;
