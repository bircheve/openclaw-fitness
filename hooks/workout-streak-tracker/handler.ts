import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";

const LOGS_DIR = path.join(os.homedir(), ".openclaw", "logs");
const STATE_FILE = path.join(LOGS_DIR, "fitness-streak.json");

function parseDateFromFilename(filename: string): Date | null {
  const match = filename.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!match) return null;
  const d = new Date(parseInt(match[1]), parseInt(match[2]) - 1, parseInt(match[3]));
  return isNaN(d.getTime()) ? null : d;
}

function getMonday(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  d.setDate(diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

function weekKey(date: Date): string {
  const monday = getMonday(date);
  return `${monday.getFullYear()}-${String(monday.getMonth() + 1).padStart(2, "0")}-${String(monday.getDate()).padStart(2, "0")}`;
}

function monthKey(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

function dayName(date: Date): string {
  return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.getDay()];
}

const handler = async (event: {
  type: string;
  action: string;
  context: Record<string, unknown>;
  messages: string[];
}) => {
  if (event.type !== "agent" || event.action !== "bootstrap") {
    return;
  }

  const workspaceDir = event.context.workspaceDir as string | undefined;
  if (!workspaceDir) return;

  try {
    const logsDir = path.join(workspaceDir, "fitness", "logs");

    let logFiles: string[];
    try {
      logFiles = (await fs.readdir(logsDir)).filter((f) => f.endsWith(".md")).sort();
    } catch {
      return; // No logs directory
    }

    if (logFiles.length === 0) return;

    // Parse all dates from log filenames
    const sessionDates: Date[] = [];
    for (const f of logFiles) {
      const d = parseDateFromFilename(f);
      if (d) sessionDates.push(d);
    }

    // Deduplicate by date (multiple logs on same day count as 1 session)
    const uniqueDays = new Map<string, Date>();
    for (const d of sessionDates) {
      const key = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
      if (!uniqueDays.has(key)) uniqueDays.set(key, d);
    }
    const uniqueSessionDates = Array.from(uniqueDays.values()).sort(
      (a, b) => a.getTime() - b.getTime(),
    );

    const now = new Date();
    const thisWeekKey = weekKey(now);
    const lastWeekDate = new Date(now);
    lastWeekDate.setDate(lastWeekDate.getDate() - 7);
    const lastWeekKey = weekKey(lastWeekDate);

    // Count sessions per week
    const weekCounts = new Map<string, { count: number; days: string[] }>();
    for (const d of uniqueSessionDates) {
      const wk = weekKey(d);
      const existing = weekCounts.get(wk) || { count: 0, days: [] };
      existing.count++;
      existing.days.push(dayName(d));
      weekCounts.set(wk, existing);
    }

    const thisWeekData = weekCounts.get(thisWeekKey) || { count: 0, days: [] };
    const lastWeekData = weekCounts.get(lastWeekKey) || { count: 0, days: [] };

    // Count sessions per month
    const thisMonthKey = monthKey(now);
    const lastMonthDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const lastMonthKeyStr = monthKey(lastMonthDate);

    let thisMonthCount = 0;
    let lastMonthCount = 0;
    for (const d of uniqueSessionDates) {
      const mk = monthKey(d);
      if (mk === thisMonthKey) thisMonthCount++;
      if (mk === lastMonthKeyStr) lastMonthCount++;
    }

    // Calculate streak (consecutive weeks with 4+ sessions, working backward)
    const allWeekKeys = Array.from(weekCounts.keys()).sort().reverse();
    let streak = 0;

    for (const wk of allWeekKeys) {
      const data = weekCounts.get(wk)!;
      if (data.count >= 4) {
        streak++;
      } else {
        // Allow current week to not break streak (it's not complete yet)
        if (wk === thisWeekKey) continue;
        break;
      }
    }

    // Find longest streak
    let longestStreak = 0;
    let currentRun = 0;
    const sortedWeeks = Array.from(weekCounts.entries()).sort((a, b) => a[0].localeCompare(b[0]));

    for (let i = 0; i < sortedWeeks.length; i++) {
      const [wk, data] = sortedWeeks[i];
      if (data.count >= 4) {
        currentRun++;
        longestStreak = Math.max(longestStreak, currentRun);
      } else {
        currentRun = 0;
      }
    }

    // Write state
    const state = {
      updatedAt: now.toISOString(),
      currentStreak: streak,
      longestStreak,
      thisWeek: thisWeekData,
      lastWeek: lastWeekData,
      thisMonth: thisMonthCount,
      lastMonth: lastMonthCount,
      totalSessions: uniqueSessionDates.length,
    };

    await fs.mkdir(LOGS_DIR, { recursive: true });
    await fs.writeFile(STATE_FILE, JSON.stringify(state, null, 2), "utf-8");

    // Build context injection
    const parts: string[] = [];
    parts.push("[Training Consistency]");

    if (thisWeekData.count > 0) {
      parts.push(
        `This week: ${thisWeekData.count} session${thisWeekData.count !== 1 ? "s" : ""} (${thisWeekData.days.join(", ")}).`,
      );
    } else {
      parts.push("This week: no sessions logged yet.");
    }

    if (lastWeekData.count > 0) {
      parts.push(`Last week: ${lastWeekData.count} sessions.`);
    }

    if (streak > 0) {
      parts.push(`Streak: ${streak} consecutive week${streak !== 1 ? "s" : ""} with 4+ sessions.`);
    }

    if (thisMonthCount > 0 || lastMonthCount > 0) {
      parts.push(`This month: ${thisMonthCount} sessions. Last month: ${lastMonthCount}.`);
    }

    event.messages.push(parts.join(" "));
  } catch (err) {
    console.warn(
      "[workout-streak-tracker] Failed:",
      err instanceof Error ? err.message : String(err),
    );
  }
};

export default handler;
