# Toast & Async-Feedback UI — Design Plan

iOS 26 / SwiftUI / Apple HIG-aligned design for Pixelated Fitness app feedback UI, covering standard toasts plus the unique "asking Winston" async-agent case the reference patterns don't address.

---

## Part 1 — Research: Apple HIG & iOS 26 Best Practices

### What Apple actually recommends (from HIG "Notifying people" + SwiftUI docs)

Apple splits transient feedback into three axes. Conflating them is the most common design failure.

| Axis | Spectrum | Decides |
|------|----------|---------|
| **Permanence** | ephemeral (2–3s) ↔ persistent (until resolved) | When the UI disappears |
| **Severity** | confirmation ↔ advisory ↔ warning ↔ blocking | Tint, dismissibility, interrupt level |
| **Agency** | user-initiated ↔ system-initiated | Position, animation entrance direction |

**HIG principles worth keeping front-of-mind:**

1. **Don't use notifications to repeat what the UI already shows.** Deleting an exercise already makes it disappear — a "removed" toast only earns its cost if the removal might have failed silently (which yours currently does).
2. **Immediate feedback wins.** If Birch taps "remove" and nothing happens for 200ms, he's going to tap again. The toast should acknowledge the *intent*, not wait for the server.
3. **Destructive actions need graceful recovery paths.** A removed exercise toast should surface an "Undo" affordance — HIG-standard for transient destructive UX on iOS.
4. **Errors deserve more than an icon change.** HIG: "Describe what happened and how to recover." "Couldn't reach Winston — tap to retry" beats "Error."
5. **Reserve modals for blocking decisions.** `.alert()` interrupts the user's flow. Use it only when Birch literally cannot proceed without responding (e.g., account was signed out). Don't use alerts for "weight saved."
6. **Accessibility is not optional in 2026.** `.accessibilityAnnouncement()`, `@Environment(\.accessibilityReduceMotion)`, Dynamic Type scaling, VoiceOver rotor support.

### iOS 26-specific APIs to use

| API | Purpose | Availability |
|-----|---------|--------------|
| `.glassEffect(.regular)` | Liquid Glass material background on the toast pill — native iOS 26 look that matches Dynamic Island aesthetic | iOS 26 |
| `@Observable` macro | State container for `ToastCenter`, no boilerplate `@Published` | iOS 17+ |
| `.sensoryFeedback(.success, trigger: ...)` | Haptic feedback synced to toast appearance (success = light tap, error = double-tap) | iOS 17+ |
| `.symbolEffect(.bounce.up, options: .nonRepeating, value: ...)` | Icon bounce animation when toast appears | iOS 17+ |
| `.animation(.spring(duration: 0.35, bounce: 0.3))` | iOS 26 default spring — matches system feel | iOS 17+ |
| `.safeAreaPadding(.top)` / `.bottom` | Correct Dynamic Island / home indicator avoidance | iOS 17+ |
| Live Activities (`ActivityKit`) | For agent calls that may outlive the app session | iOS 16.1+ |
| `@Environment(\.accessibilityReduceMotion)` | Swap spring animation for fade when user has Reduce Motion on | iOS 17+ |

### What **not** to reach for

- **Third-party toast libraries** (SwiftMessages, Toast-Swift, AlertToast). Adds dependency weight, rarely tracks latest HIG, fights against iOS 26 Liquid Glass material. For this app's toast complexity, ~200 LOC of owned code is smaller than any library.
- **`.alert()`** for action confirmations. It blocks the whole UI — wrong for "removed."
- **Auto-dismissing "Asking Winston" toasts.** Agent calls don't fit toast timing. Needs a different component (see Part 3).

---

## Part 2 — Taxonomy for this App

Every user-triggered feedback moment in Pixelated Fitness falls into one of three categories. Each gets a different UI primitive.

### Category A — Instant Confirmation (ephemeral, <3s visible)

**When:** An action completed locally and the result is already reflected in the UI, but the user deserves a micro-ack for the intent.

**Examples:**
- Set marked complete — current: button turns green + haptic. **Keep this, don't add toast.** HIG rule #1: don't repeat the UI.
- Weight logged successfully (future, not built) — toast: "Weight saved"
- Meal logged (future) — toast: "Logged — 52g protein"
- Workout JSON copied to clipboard (existing toast) — keep, already good

**Spec:**
- 2.5-second visible duration, fade-in 0.25s, fade-out 0.4s, spring
- Bottom-anchored, 16pt from safe area
- Variants: success (green check), info (blue i)
- No close button (auto-dismisses, tap anywhere to dismiss early)
- Haptic: `.sensoryFeedback(.success, trigger: ...)`

### Category B — Result Feedback (server round-trip, 0.5–5s)

**When:** An action requires a bridge round-trip and the user needs to know the outcome. Error paths must be recoverable.

**Examples:**
- Exercise removed via `PATCH /workout` — currently fire-and-forget with `try?` (silent failure). This is the biggest gap today.
- Workout completion submitted via `POST /workout/:id/complete`
- (future) Photo analysis initial upload `POST /food-log/photo`

**Spec — success path:**
- Optimistic UI update (already done), immediately show "Removed — Undo" toast
- **Undo button** in the toast for destructive actions (HIG #3). Tap → re-insert exercise locally + send reinstate PATCH
- 4-second visible duration (slightly longer than Category A, because the Undo needs dwell time)
- Haptic: `.success` light tap

**Spec — error path:**
- Toast variant: `.error`
- Content: "Couldn't reach Winston — tap to retry"
- **Does not auto-dismiss** until user taps retry or dismisses manually
- Tap target = retry action; explicit X dismisses
- Haptic: `.error` double-tap
- Rolls back optimistic UI change on dismiss-without-retry

### Category C — Asking Winston (async agent, 5s – 2min, out-of-band response)

**When:** An action triggers a bridge endpoint that forwards to Winston via `execFile`-invoked openclaw agent call. The HTTP response returns immediately with `{ok: true}`; the actual outcome arrives later via (a) a re-POST to `/workout` with updated JSON, (b) an iMessage reply, or (c) both.

**Examples:**
- Exercise swap request — `POST /workout/suggest` (not yet built in app, exists on bridge)
- (future) Photo-based food analysis result — arrives via iMessage minutes later
- (future) Any "hey Winston, change X" feature

**Why a toast is wrong for this:**
Apple HIG: "A notification's lifetime should match the duration of the event it represents." A swap request's event is "Winston is thinking about alternatives" — that can take 30s. A 3s toast lies. A 60s toast is absurd. Keeping the toast up until Winston responds means occupying screen real estate indefinitely while Birch tries to keep working out.

**Correct pattern — `AskingWinstonBanner`:**
- A **thin status pill** at the top of the safe area (not overlay — inline, pushes content down), paired with the Dynamic Island aesthetic
- Uses iOS 26 `.glassEffect(.regular)` for the "native status" look
- Content: rotating verb ("Asking Winston…" → "Winston is thinking…" → "Almost there…") to show liveness, plus a subtle pulsing SF Symbol
- **Auto-dismisses when the backing data changes** — the WorkoutViewModel already polls `/workout` every 10s, so: when `workout.version` increments, the banner knows the agent responded and shows a brief "Updated" confirmation (Category A toast) before disappearing
- **Timeout fallback:** after 90s with no change, banner switches to `.warning` variant: "Winston's taking a while — check iMessage for a reply, or tap to retry"
- **Cancel affordance:** small X to abandon the request (local only — the agent call is already inflight server-side, but the user recovers their UI)

**For truly long operations (>60s expected):**
Consider a Live Activity (ActivityKit). Shows in Dynamic Island + Lock Screen, survives the app being backgrounded. This is the Apple-native way and it's what Dynamic Island was built for. Overkill for swaps but right for photo-food-analysis flows later.

### Category D — Blocking Errors (modal, user must acknowledge)

**When:** The user literally cannot proceed without a decision.

**Examples:**
- Session expired, sign in again
- Bridge unreachable on launch (no workout data at all)
- Data corruption or unrecoverable state

**Spec:** `.alert()` with a single primary action and optional cancel. **Don't use for "saving failed"** — that's Category B.

---

## Part 3 — Component Architecture

### File layout

```
pixelatedfitness/
  Design/
    ToastCenter.swift          // @Observable state container
    ToastView.swift            // Single-toast view
    ToastOverlay.swift         // Overlay container (stack of up to 3 toasts)
    ToastVariant.swift         // Enum: success, info, warning, error
    AskingWinstonBanner.swift  // Separate component for Category C
    SemanticColors.swift       // Extension on ColorPalette
  Resources/
    ColorPalette.swift         // (existing) add .feedbackSuccess etc.
```

### State container — `ToastCenter`

```swift
@Observable
final class ToastCenter {
    private(set) var toasts: [Toast] = []
    private(set) var askingWinston: AskingWinstonState? = nil

    func show(_ toast: Toast) { ... }   // enqueue with auto-dismiss
    func startAskingWinston(label: String, resolveOn: AskingWinstonState.Resolver) { ... }
    func dismissAskingWinston(result: AskingResult) { ... }
    func dismiss(id: UUID) { ... }
}

struct Toast: Identifiable {
    let id = UUID()
    let variant: ToastVariant   // .success, .info, .warning, .error
    let message: String
    let action: ToastAction?    // .undo(() -> Void), .retry(() -> Void)
    let duration: Duration      // .seconds(2.5) for success, .manual for error
}
```

### Injection

Inject at `pixelatedfitnessApp.swift`:

```swift
@main
struct pixelatedfitnessApp: App {
    @State private var toastCenter = ToastCenter()
    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environment(toastCenter)
                .overlay(alignment: .bottom) { ToastOverlay() }
                .safeAreaInset(edge: .top) { AskingWinstonBanner() }
        }
    }
}
```

- `.overlay(alignment: .bottom)` — bottom-anchored toasts for Categories A/B (Birch's attention is already near the bottom when manipulating set lists)
- `.safeAreaInset(edge: .top)` — the banner is *inline*, not overlay: it pushes content down so Birch can't lose track of where his workout is. This matches the Dynamic Island / status-bar mental model and is better than overlaying on top of the workout title.

### ToastView styling (per variant)

Each variant defines: tint color, SF Symbol icon, haptic pattern, default dismiss timing.

```swift
enum ToastVariant {
    case success   // .green,  "checkmark.circle.fill",     .success,  2.5s
    case info      // .blue,   "info.circle.fill",          .selection, 2.5s
    case warning   // .orange, "exclamationmark.triangle.fill", .warning, 5s
    case error     // .red,    "xmark.circle.fill",         .error,    manual
}
```

Visual: Liquid Glass background (`.glassEffect(.regular, in: Capsule())`), colored stroke on leading edge matching the reference screenshot, system font size 15pt with Dynamic Type support, max 2 lines with truncation.

### Semantic color extension

```swift
extension Color {
    static let feedbackSuccess = Color(hue: 0.33, saturation: 0.65, brightness: 0.90)
    static let feedbackInfo    = Color.accentColor  // existing brand purple works
    static let feedbackWarning = Color(hue: 0.10, saturation: 0.85, brightness: 0.95)
    static let feedbackError   = Color(hue: 0.00, saturation: 0.75, brightness: 0.90)
}
```

(Tune in Xcode Preview against dark backgrounds — numbers above are sketches matching the reference screenshot.)

### Accessibility

Every toast must:

1. Announce via `.accessibilityLabel("\(variant.semanticName) — \(message)")` so VoiceOver reads "Error — couldn't reach Winston, tap to retry" not just the icon.
2. Honor `@Environment(\.accessibilityReduceMotion)` — fall back to 0.15s fade instead of spring slide.
3. Respect `@ScaledMetric` for padding so Dynamic Type's largest setting doesn't clip text.
4. Make the whole toast a tap target when it has an action (never rely on a small button-within-toast).
5. `.accessibilityAddTraits(.isButton)` when actionable.

### Haptics

- Success: `.sensoryFeedback(.success, trigger: toastID)`
- Info: none (or `.selection` if dismiss-tappable)
- Warning: `.sensoryFeedback(.warning, trigger: toastID)`
- Error: `.sensoryFeedback(.error, trigger: toastID)` (double-tap pattern)
- AskingWinston appear: `.sensoryFeedback(.selection, trigger: ...)` (subtle, it's an ongoing state not an event)
- AskingWinston resolve: `.sensoryFeedback(.success, trigger: ...)`

---

## Part 4 — Call-Site Mapping (where to wire it in)

Concrete edits to existing code, following the exploration findings.

| Flow | File:line | Current | Change |
|------|-----------|---------|--------|
| Exercise removal success | `WorkoutViewModel.swift:260-265` | Fire-and-forget `try?` | Await PATCH, on success `toastCenter.show(.undoRemove(...))`, on failure `toastCenter.show(.error(retry))` + rollback |
| Exercise removal rollback | `BridgeWorkoutRepository.swift:50-59` | Silent on error | Propagate error up, not swallow |
| Workout submission | `RootContentView.swift:169` | Fire-and-forget, clipboard toast only | Await completion; on success show "Workout logged" success toast; on failure show error toast with retry |
| Exercise swap ask | (not yet wired) | N/A | `toastCenter.startAskingWinston("Looking for alternatives…", resolveOn: .workoutVersionChange)` |
| Workout load failure | `WorkoutListView.swift:42-59` | Inline error view | Keep the inline view for cold-start; add toast variant for transient failures during active session |
| Clipboard copy | `RootContentView.swift:88-100` | Custom one-off toast | Replace with `toastCenter.show(.info("Workout copied — paste to your AI coach"))` |

### The reinstate endpoint for Undo

The bridge currently has `PATCH /workout { action: "remove_exercise" }` but no reinstate. Options:

1. **Keep a local undo stack** on the client. Undo re-inserts locally + fires `PUT /workout/{id}/exercises/{exerciseId}` (would need adding to bridge).
2. **Store the removed exercise in a pending list.** Undo cancels before the PATCH is actually sent (debounce-undo pattern). Matches Gmail's undo send — show toast for 4s, only actually commit if not undone. **This is cleaner** — no reinstate endpoint needed on bridge.

Recommended: **debounce-undo**. Add a 4-second delay to `removeExercise` in ViewModel; if Undo is tapped during the window, cancel the PATCH entirely. If not, send it. Bridge change: none.

---

## Part 5 — Shipping Order

1. **Week 1** — Foundation: `ToastCenter`, `ToastView`, `ToastOverlay`, `ToastVariant`, `SemanticColors` extension, injection at app root. Unit tests for enqueue / dismiss / auto-timeout.
2. **Week 1** — Migrate existing clipboard toast + completion feedback alert to use `toastCenter`. Replaces ~40 LOC in `RootContentView`.
3. **Week 1** — Exercise removal → debounce-undo toast. Also flips fire-and-forget to awaited with error path. This is the highest-value single change because silent failure is the worst thing in the current app.
4. **Week 2** — `AskingWinstonBanner` component + `safeAreaInset` injection. Wire the exercise-swap flow (requires adding `POST /workout/suggest` call site — not yet built in app).
5. **Week 2** — Accessibility pass: VoiceOver, Reduce Motion, Dynamic Type at `.accessibility5`.
6. **Week 3** — Live Activity support for longer agent operations (photo food analysis when that flow gets built).

---

## Part 6 — What This Plan Deliberately Doesn't Try to Do

- **No third-party library.** ~350 LOC total owned code is smaller than the library+integration overhead and ages better.
- **No separate "info" color beyond brand purple.** The reference screenshot uses blue for info — your app is already purple-branded. Use `.accentColor` for info variant to keep a coherent brand voice. The reference is a starting point, not a contract.
- **No gamification / streak-burst toasts.** Per the system-wide no-bookkeeping principle, the app never ceremonies achievements. Winston surfaces those in iMessage. The app stays a quiet checklist.
- **No modal sheets for "asking Winston."** A sheet blocks the workout UI — exactly when Birch needs to keep moving through sets. The banner pattern stays out of his way.

---

## References

- Apple HIG — Patterns > [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback)
- Apple HIG — Components > [Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts)
- ActivityKit docs — Live Activities for agent callbacks
- Related: `PHASE1-PHASE4-CHANGES.md` (the vibe button work — uses the same `ToastCenter` for its submit feedback)
