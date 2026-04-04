import SwiftUI

struct ChangelogView: View {
    var body: some View {
        List {
            Section {
                ChangelogEntry(
                    version: "1.0.0",
                    date: "March 2026",
                    changes: [
                        "AI-powered workout delivery",
                        "Exercise tracking with set-by-set completion",
                        "Workout history",
                        "Clipboard summary for iMessage feedback",
                        "Network connectivity — works on LAN, VPN, or public HTTPS",
                    ]
                )
            }
        }
        .navigationTitle("Changelog")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ChangelogEntry: View {
    let version: String
    let date: String
    let changes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Version \(version)")
                    .font(.headline)
                Spacer()
                Text(date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(changes, id: \.self) { change in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{2022}")
                            .foregroundColor(.secondary)
                        Text(change)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("ChangelogView") {
    NavigationStack {
        ChangelogView()
    }
}
