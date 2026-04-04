import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("About Pixelated Fitness")
                    .font(.title2)
                    .bold()

                Text("A workout companion powered by OpenClaw. Workouts are generated, adapted, and tracked by your personal AI trainer. This app is your gym-side interface for checking off exercises and recording feedback.")

                Text("How it works:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Ask your AI coach for your workout")
                    Text("2. Your workout appears here automatically")
                    Text("3. Check off sets and exercises as you go")
                    Text("4. Submit feedback when done — it copies to clipboard")
                    Text("5. Paste the summary to your AI coach")
                }
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("AboutView") {
    NavigationStack {
        AboutView()
    }
}
