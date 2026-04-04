import type { PluginAPI } from "openclaw";

const BRIDGE_URL = process.env.FITNESS_BRIDGE_URL || "http://localhost:18792/workout";
const MARKER_RE = /\[workout-bridge:([\s\S]*?)\]/;

export default function (api: PluginAPI) {
  console.log("[openclaw-fitness] plugin initialized, bridge URL:", BRIDGE_URL);

  api.on("message_sending", (event) => {
    const content = event.content || "";

    const match = content.match(MARKER_RE);
    if (!match) {
      return;
    }

    const jsonStr = match[1].trim();
    console.log(`[openclaw-fitness] workout marker found, JSON length=${jsonStr.length}`);

    // Strip the marker from the outgoing message
    const cleaned = content.replace(MARKER_RE, "").trim();

    // POST workout JSON to bridge server (fire and forget)
    fetch(BRIDGE_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: jsonStr,
    })
      .then((res) => {
        if (!res.ok) console.error(`[openclaw-fitness] POST failed: ${res.status}`);
        else console.log("[openclaw-fitness] POST success — workout pushed to bridge");
      })
      .catch((err) => {
        console.error(`[openclaw-fitness] POST error:`, err);
      });

    return { content: cleaned };
  });
}
