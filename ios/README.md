# Pixelated Fitness — iOS App

A SwiftUI companion app for the openclaw-fitness plugin. Shows your current workout at the gym, lets you check off sets, remove exercises, and submit feedback — all syncing with your AI coach through the bridge server.

## Features

- View your AI-generated workout with exercise details, sets, and reps
- Filter exercises by muscle group
- Remove exercises mid-workout (syncs back to coach)
- Submit workout completion with rating and notes
- View workout history
- Retro pixel art aesthetic

## Prerequisites

- macOS with Xcode 15+
- iOS 17+ device or simulator
- Bridge server running (see `../bridge/`)

## Setup

### 1. Clone and open the project

```bash
cd ios/pixelatedfitness
open pixelatedfitness.xcodeproj
```

### 2. Configure the bridge URL

Copy the example config:
```bash
cp pixelatedfitness/Config-Debug.plist.example pixelatedfitness/Config-Debug.plist
```

Edit `Config-Debug.plist` and set `Bridge_Base_URL` to your bridge server address.

### 3. Build and run

Select your device or simulator in Xcode and press Run (Cmd+R).

## Networking Setup

The app needs to reach your bridge server. Choose the option that fits your setup:

### Option 1: Same LAN (simplest)

If your phone and Mac are on the same Wi-Fi network:

1. Find your Mac's local IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
2. Set `Bridge_Base_URL` to `http://YOUR_MAC_IP:18792`
3. The bridge server binds to `0.0.0.0` so it accepts connections from any device on the LAN

**Limitation:** Only works when both devices are on the same network. Won't work at the gym unless your Mac is there too.

### Option 2: Tailscale VPN (recommended for gym use)

Use Tailscale to create a private network between your Mac and phone:

1. Install Tailscale on your Mac and iPhone
2. Sign in to both with the same account
3. Find your Mac's Tailscale IP: `tailscale ip -4` (looks like `100.x.x.x`)
4. Set `Bridge_Base_URL` to `http://YOUR_TAILSCALE_IP:18792`
5. The app's ATS configuration allows insecure HTTP to any IP

**This is the recommended setup** — it works from anywhere, including at the gym.

### Option 3: Public HTTPS

For production or shared use, put the bridge behind a reverse proxy with HTTPS:

1. Set up a reverse proxy (nginx, Caddy, etc.) pointing to `localhost:18792`
2. Get a TLS certificate (Let's Encrypt, etc.)
3. Set `Bridge_Base_URL` to `https://your-domain.com`
4. No ATS exceptions needed with HTTPS

## Architecture

```
┌─────────────────┐     HTTP      ┌──────────────┐     exec curl     ┌─────────────┐
│  iOS App         │ ◄──────────► │ Bridge Server │ ◄──────────────── │ AI Coach    │
│  (SwiftUI)       │              │ (Node.js)     │                   │ (OpenClaw)  │
└─────────────────┘              └──────────────┘                    └─────────────┘
       │                                │
       │ PATCH /workout                 │ POST /workout
       │ (remove exercise)              │ (push new workout)
       │                                │
       └── POST /workout/:id/complete   │
           (submit feedback)            │
                                        └── GET /workout
                                            (app polls for current)
```

## API Reference

See [BRIDGE-API.md](./BRIDGE-API.md) for the full bridge server API documentation.
