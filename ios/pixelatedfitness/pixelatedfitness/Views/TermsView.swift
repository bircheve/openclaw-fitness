import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Use")
                    .font(.title2)
                    .bold()

                Text("Last updated: [Date]")
                    .foregroundColor(.secondary)

                Text("By using PixelatedFitness, you agree to these terms...")
                    .foregroundColor(.secondary)

                Text("[Terms content would go here]")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Terms of Use")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("TermsView") {
    NavigationStack {
        TermsView()
    }
}