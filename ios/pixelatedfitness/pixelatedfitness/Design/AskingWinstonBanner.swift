import SwiftUI

/// Persistent top-anchored banner shown while Winston is processing a
/// request whose response arrives out-of-band (e.g. exercise swap that
/// gets POSTed back to the bridge as an updated workout, or a food photo
/// that Winston analyzes via iMessage).
///
/// Attach at root via `.safeAreaInset(edge: .top) { AskingWinstonBanner() }`.
/// Using `safeAreaInset` (inline) instead of `overlay` means the banner
/// pushes content down — Birch can't lose track of where his workout list is.
///
/// This component does NOT auto-dismiss on a timer. It clears when the
/// caller invokes `center.resolveAsking(...)` — typically when the workout
/// JSON version increments (see `WorkoutViewModel.applySyncUpdate`).
struct AskingWinstonBanner: View {
    @Environment(ToastCenter.self) private var center
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dotCount = 1
    @State private var dotTask: Task<Void, Never>? = nil

    var body: some View {
        Group {
            if let state = center.asking {
                bannerBody(state: state)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            } else {
                EmptyView()
            }
        }
        .animation(
            reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.25),
            value: center.asking?.id
        )
        .onChange(of: center.asking?.id) { _, newID in
            if newID != nil {
                startDotAnimation()
            } else {
                stopDotAnimation()
            }
        }
        .onAppear {
            if center.asking != nil { startDotAnimation() }
        }
        .onDisappear { stopDotAnimation() }
    }

    private func bannerBody(state: AskingWinstonState) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.brandLavender)
                .font(.system(size: 14, weight: .semibold))
                .symbolEffect(.variableColor.iterative, options: .repeating, value: state.id)
                .accessibilityHidden(true)

            Text(state.label + String(repeating: ".", count: dotCount))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 4)

            Button {
                center.resolveAsking(.cancelled)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel waiting for Winston")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background {
            Capsule(style: .continuous)
                .fill(Color.brandPrimary.opacity(0.9))
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color.brandAccent.opacity(0.5), lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Asking Winston — \(state.label)")
    }

    private func startDotAnimation() {
        stopDotAnimation()
        dotTask = Task { @MainActor in
            while !Task.isCancelled, center.asking != nil {
                try? await Task.sleep(for: .milliseconds(450))
                guard !Task.isCancelled else { break }
                dotCount = (dotCount % 3) + 1
            }
        }
    }

    private func stopDotAnimation() {
        dotTask?.cancel()
        dotTask = nil
        dotCount = 1
    }
}
