const http = require("http");
const fs = require("fs");
const path = require("path");
const { execFile } = require("child_process");

const PORT = parseInt(process.env.PORT || "18792", 10);
const STORE = path.join(__dirname, "store.json");
const HISTORY = path.join(__dirname, "history.json");

function readJSON(filepath) {
  try {
    return JSON.parse(fs.readFileSync(filepath, "utf8"));
  } catch {
    return null;
  }
}

function writeStore(data) {
  fs.writeFileSync(STORE, JSON.stringify(data, null, 2));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => resolve(Buffer.concat(chunks).toString()));
    req.on("error", reject);
  });
}

// --- Agent notification (debounced) ---

let pendingChanges = [];
let notifyTimer = null;

function queueNotification(description) {
  pendingChanges.push(description);
  if (notifyTimer) clearTimeout(notifyTimer);
  notifyTimer = setTimeout(() => {
    const batch = pendingChanges.join("; ");
    pendingChanges = [];
    notifyTimer = null;
    notifyAgent(batch);
  }, 3000);
}

function notifyAgent(description) {
  const openclawBin = process.env.OPENCLAW_BIN || "openclaw";
  const channel = process.env.NOTIFY_CHANNEL;
  const target = process.env.NOTIFY_TARGET;

  if (!channel || !target) {
    console.log("[workout-bridge] Notification skipped: NOTIFY_CHANNEL and NOTIFY_TARGET not configured. See README for setup.");
    console.log("[workout-bridge] Event:", description);
    return;
  }

  const message = `[app-sync] ${description}`;
  execFile(openclawBin, [
    "agent",
    "--message", message,
    "--deliver",
    "--channel", channel,
    "-t", target,
  ], { timeout: 60000 }, (err) => {
    if (err) console.error("[workout-bridge] notify failed:", err.message);
    else console.log("[workout-bridge] notified agent:", description);
  });
}

// --- Find exercise by ID across all sections ---

function findExerciseName(workout, exerciseId) {
  for (const section of ["warmup", "main", "cardio", "cooldown"]) {
    const exercises = workout.work?.[section]?.exercises || [];
    const found = exercises.find((e) => e.id === exerciseId);
    if (found) return found.name;
  }
  return null;
}

function removeExercise(workout, exerciseId) {
  let removed = false;
  for (const section of ["warmup", "main", "cardio", "cooldown"]) {
    const exercises = workout.work?.[section]?.exercises;
    if (!exercises) continue;
    const idx = exercises.findIndex((e) => e.id === exerciseId);
    if (idx !== -1) {
      exercises.splice(idx, 1);
      // Reindex positions
      exercises.forEach((e, i) => { e.position = i; });
      removed = true;
      break;
    }
  }
  return removed;
}

const server = http.createServer(async (req, res) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} from ${req.socket.remoteAddress}`);
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, PATCH, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    return res.end();
  }

  // GET /workout — current workout
  if (req.method === "GET" && req.url === "/workout") {
    const data = readJSON(STORE);
    if (!data) {
      res.writeHead(404, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "no workout" }));
    }
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify(data));
  }

  // POST /workout — agent pushes a new workout
  if (req.method === "POST" && req.url === "/workout") {
    const body = await readBody(req);
    try {
      const parsed = JSON.parse(body);
      if (!parsed.workout_id || !parsed.work) {
        res.writeHead(400, { "Content-Type": "application/json" });
        return res.end(JSON.stringify({ error: "invalid workout: needs workout_id and work" }));
      }
      parsed.version = 1;
      writeStore(parsed);
      res.writeHead(200, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ ok: true }));
    } catch {
      res.writeHead(400, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "invalid JSON" }));
    }
  }

  // PATCH /workout — app modifies current workout
  if (req.method === "PATCH" && req.url === "/workout") {
    const currentWorkout = readJSON(STORE);
    if (!currentWorkout) {
      res.writeHead(404, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "no workout" }));
    }

    const body = await readBody(req);
    try {
      const patch = JSON.parse(body);

      if (patch.action === "remove_exercise" && patch.exercise_id) {
        const name = findExerciseName(currentWorkout, patch.exercise_id);
        if (!name) {
          res.writeHead(404, { "Content-Type": "application/json" });
          return res.end(JSON.stringify({ error: "exercise not found" }));
        }

        removeExercise(currentWorkout, patch.exercise_id);
        currentWorkout.version = (currentWorkout.version || 1) + 1;
        writeStore(currentWorkout);

        queueNotification(`User removed ${name} from today's workout`);

        res.writeHead(200, { "Content-Type": "application/json" });
        return res.end(JSON.stringify({ ok: true, version: currentWorkout.version }));
      }

      res.writeHead(400, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "unknown action" }));
    } catch {
      res.writeHead(400, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "invalid JSON" }));
    }
  }

  // POST /workout/:id/complete — app submits completion + feedback
  const completeMatch = req.url.match(/^\/workout\/([^/]+)\/complete$/);
  if (req.method === "POST" && completeMatch) {
    const workoutId = decodeURIComponent(completeMatch[1]);
    const body = await readBody(req);
    try {
      const payload = JSON.parse(body);
      const currentWorkout = readJSON(STORE);

      if (!currentWorkout || currentWorkout.workout_id !== workoutId) {
        res.writeHead(404, { "Content-Type": "application/json" });
        return res.end(JSON.stringify({ error: "workout not found" }));
      }

      // Build history entry
      const entry = {
        workout: currentWorkout,
        feedback: payload.feedback || {},
        completion: payload.completion || {},
        completed_at: new Date().toISOString(),
      };

      // Append to history
      const history = readJSON(HISTORY) || [];
      history.unshift(entry);
      fs.writeFileSync(HISTORY, JSON.stringify(history, null, 2));

      // Clear current workout
      try { fs.unlinkSync(STORE); } catch {}

      res.writeHead(200, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ ok: true }));
    } catch {
      res.writeHead(400, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "invalid JSON" }));
    }
  }

  // GET /history — past completed workouts
  if (req.method === "GET" && req.url === "/history") {
    const history = readJSON(HISTORY) || [];
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify(history));
  }

  // GET /health — connectivity check
  if (req.method === "GET" && req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ ok: true, has_workout: !!readJSON(STORE) }));
  }

  res.writeHead(404, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "not found" }));
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Workout bridge listening on 0.0.0.0:${PORT}`);
});
