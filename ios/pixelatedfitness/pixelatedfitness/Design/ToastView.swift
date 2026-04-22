import SwiftUI

/// Renders a single toast card. Styled after modern iOS 26 toast
/// patterns: dark background, colored leading icon + stroke, optional
/// action button, Dynamic Type-aware padding, symbol-effect on appearance.
struct ToastView: View {
    let toast: Toast
    let onDismiss: @MainActor () -> Void

    @ScaledMetric(relativeTo: .subheadline) private var hPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .subheadline) private var vPadding: CGFloat = 12

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: toast.variant.iconName)
                .foregroundStyle(toast.variant.tint)
                .font(.system(size: 22, weight: .semibold))
                .symbolEffect(.bounce.up, options: .nonRepeating, value: toast.id)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(toast.message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let action = toast.action {
                    Button(action.title) {
                        action.handler()
                        onDismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(toast.variant.tint)
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(.isButton)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(toast.variant.tint.opacity(0.85))
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss \(toast.variant.accessibilityLabel.lowercased())")
        }
        .padding(.horizontal, hPadding)
        .padding(.vertical, vPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(white: 0.08))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(toast.variant.tint, lineWidth: 1.5)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(toast.variant.accessibilityLabel): \(toast.message)")
    }
}

#Preview("Toast variants", traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        ToastView(
            toast: Toast(variant: .success, message: "Workout logged"),
            onDismiss: {}
        )
        ToastView(
            toast: Toast(
                variant: .info,
                message: "Removed Incline DB Press",
                action: ToastAction(title: "Undo", handler: {})
            ),
            onDismiss: {}
        )
        ToastView(
            toast: Toast(variant: .warning, message: "Winston is taking a while — check iMessage"),
            onDismiss: {}
        )
        ToastView(
            toast: Toast(
                variant: .error,
                message: "Couldn't reach Winston",
                action: ToastAction(title: "Retry", handler: {})
            ),
            onDismiss: {}
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
