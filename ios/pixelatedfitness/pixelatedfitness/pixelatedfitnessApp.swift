import SwiftUI

@main
struct pixelatedfitnessApp: App {
    private let deps = AppBootstrap.live

    @State private var toastCenter = ToastCenter()

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environment(\.deps, deps)
                .environment(toastCenter)
                .safeAreaInset(edge: .top, spacing: 0) {
                    AskingWinstonBanner()
                }
                .overlay(alignment: .bottom) {
                    ToastOverlay()
                }
                .preferredColorScheme(.dark)
        }
    }
}
