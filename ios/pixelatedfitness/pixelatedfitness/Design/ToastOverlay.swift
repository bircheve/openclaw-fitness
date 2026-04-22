import SwiftUI

/// Stack of visible toasts anchored at the bottom of the app window.
/// Attach at root via `.overlay(alignment: .bottom) { ToastOverlay() }`.
///
/// Handles entry/exit animation, Reduce Motion fallback, and haptic feedback.
/// Individual toasts auto-dismiss after their `duration` expires (managed
/// by `ToastCenter`); users can also tap the X or the toast action to dismiss.
struct ToastOverlay: View {
    @Environment(ToastCenter.self) private var center
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            ForEach(center.toasts) { toast in
                ToastView(toast: toast) {
                    center.dismiss(id: toast.id)
                }
                .transition(transition)
                .sensoryFeedback(toast.variant.hapticFeedback, trigger: toast.id)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .animation(animation, value: center.toasts.map(\.id))
        .allowsHitTesting(!center.toasts.isEmpty)
    }

    private var transition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity.combined(with: .scale(scale: 0.95))
            )
    }

    private var animation: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.2)
            : .spring(duration: 0.35, bounce: 0.3)
    }
}
