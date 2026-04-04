import SwiftUI

struct SettingsView: View {
    @Environment(\.deps) private var deps

    var body: some View {
        List {
            Section {
                NavigationLink {
                    HistoryView(repo: deps.workouts)
                } label: {
                    Label("Workout History", systemImage: "clock.arrow.circlepath")
                }
            }

            Section("About") {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
                }

                NavigationLink {
                    ChangelogView()
                } label: {
                    Label("Changelog", systemImage: "list.bullet.rectangle")
                }
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Bridge Server")
                    Spacer()
                    Text(ConfigurationManager.bridgeBaseURL)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview("SettingsView") {
    NavigationStack {
        SettingsView()
    }
    .environment(\.deps, AppBootstrap.preview)
}
