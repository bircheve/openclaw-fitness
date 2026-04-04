import SwiftUI

@main
struct pixelatedfitnessApp: App {
    private let deps = AppBootstrap.live

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environment(\.deps, deps)
                .preferredColorScheme(.dark)
        }
    }
}
