import Foundation
import Observation

/// Global state container for transient feedback UI.
///
/// Three categories of feedback are handled here:
/// - Ephemeral toasts (`success` / `info` / `warning` / `error`) — via `show` or conveniences.
/// - "Asking Winston" persistent banner — via `startAsking` / `resolveAsking`.
/// - Blocking modals — NOT handled here (use SwiftUI `.alert` directly for those).
///
/// Injected at app root as an `@Environment(ToastCenter.self)` object. Views
/// both read (`toasts`, `asking`) and write (`show`, `dismiss`) through this.
@MainActor
@Observable
final class ToastCenter {
    /// Currently visible toasts, oldest first. Capped at 3.
    private(set) var toasts: [Toast] = []

    /// Active "asking Winston" state, or nil. Banner renders only when set.
    private(set) var asking: AskingWinstonState? = nil

    private let maxVisibleToasts = 3
    private var dismissTasks: [UUID: Task<Void, Never>] = [:]

    // MARK: - Toasts

    func show(_ toast: Toast) {
        toasts.append(toast)
        if toasts.count > maxVisibleToasts {
            let dropped = toasts.removeFirst()
            cancelDismiss(id: dropped.id)
        }
        scheduleDismiss(for: toast)
    }

    func dismiss(id: UUID) {
        toasts.removeAll { $0.id == id }
        cancelDismiss(id: id)
    }

    private func scheduleDismiss(for toast: Toast) {
        cancelDismiss(id: toast.id)
        let id = toast.id
        let duration = toast.duration
        dismissTasks[id] = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.dismiss(id: id) }
        }
    }

    private func cancelDismiss(id: UUID) {
        dismissTasks[id]?.cancel()
        dismissTasks[id] = nil
    }

    // MARK: - Convenience helpers (preferred call sites)

    func success(_ message: String) {
        show(Toast(variant: .success, message: message))
    }

    func info(_ message: String) {
        show(Toast(variant: .info, message: message))
    }

    func warning(_ message: String) {
        show(Toast(variant: .warning, message: message))
    }

    func error(_ message: String, retry: (@MainActor () -> Void)? = nil) {
        let action = retry.map { ToastAction(title: "Retry", handler: $0) }
        show(Toast(variant: .error, message: message, action: action))
    }

    func undoable(_ message: String, undo: @escaping @MainActor () -> Void) {
        let action = ToastAction(title: "Undo", handler: undo)
        show(Toast(variant: .info, message: message, action: action, duration: .seconds(4)))
    }

    // MARK: - Asking Winston

    func startAsking(_ label: String) {
        asking = AskingWinstonState(label: label)
    }

    func resolveAsking(_ result: AskingResult) {
        guard asking != nil else { return }
        asking = nil
        switch result {
        case .success(let message):
            show(Toast(variant: .success, message: message))
        case .failure(let message):
            show(Toast(variant: .error, message: message))
        case .cancelled:
            break
        }
    }
}

/// State for the persistent "asking Winston" banner. Banner is visible
/// while a value exists; cleared via `resolveAsking`.
struct AskingWinstonState: Equatable {
    let id: UUID = UUID()
    var label: String
    var startedAt: Date = Date()
}

/// Outcome of an "asking Winston" operation.
enum AskingResult {
    case success(String)
    case failure(String)
    case cancelled
}
