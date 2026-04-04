import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title2)
                    .bold()

                Text("Last updated: [Date]")
                    .foregroundColor(.secondary)

                Text("Your privacy is important to us...")
                    .foregroundColor(.secondary)

                Text("[Privacy policy content would go here]")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("PrivacyView") {
    NavigationStack {
        PrivacyView()
    }
}