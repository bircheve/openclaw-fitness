import Foundation
import SwiftUI

/// Visual + semantic variant of a toast. Chosen by intent, not color —
/// see `TOAST-PLAN.md` for the 4-category taxonomy.
enum ToastVariant {
    case success
    case info
    case warning
    case error

    var iconName: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .info:    "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error:   "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .success: .feedbackSuccess
        case .info:    .feedbackInfo
        case .warning: .feedbackWarning
        case .error:   .feedbackError
        }
    }

    /// Auto-dismiss duration. `error` uses a long timeout rather than
    /// no-timeout — toasts must always eventually go away or they'll
    /// orphan when the user navigates somewhere they can't dismiss from.
    var defaultDuration: Duration {
        switch self {
        case .success: .seconds(2.5)
        case .info:    .seconds(2.5)
        case .warning: .seconds(5)
        case .error:   .seconds(10)
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .success: "Success"
        case .info:    "Info"
        case .warning: "Warning"
        case .error:   "Error"
        }
    }

    var hapticFeedback: SensoryFeedback {
        switch self {
        case .success: .success
        case .info:    .selection
        case .warning: .warning
        case .error:   .error
        }
    }
}

/// Optional tappable affordance inside a toast. Used for Undo / Retry.
struct ToastAction {
    let title: String
    let handler: @MainActor () -> Void

    init(title: String, handler: @escaping @MainActor () -> Void) {
        self.title = title
        self.handler = handler
    }
}

/// A single toast instance enqueued in the ToastCenter.
struct Toast: Identifiable {
    let id: UUID
    let variant: ToastVariant
    let message: String
    let action: ToastAction?
    let duration: Duration

    init(
        variant: ToastVariant,
        message: String,
        action: ToastAction? = nil,
        duration: Duration? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.variant = variant
        self.message = message
        self.action = action
        self.duration = duration ?? variant.defaultDuration
    }
}
