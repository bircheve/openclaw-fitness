import SwiftUI

struct HistoryView: View {
    @StateObject private var vm: HistoryViewModel

    init(repo: WorkoutRepository) {
        _vm = StateObject(wrappedValue: HistoryViewModel(repo: repo))
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.history.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No workouts yet")
                        .font(.title3.weight(.medium))
                    Text("Completed workouts will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(vm.history) { entry in
                    HistoryRow(entry: entry)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .task { vm.load() }
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    let entry: CompletedWorkout
    @State private var isExpanded = false

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.completedAt)
    }

    private var muscleLabel: String {
        entry.workout.muscleGroups.map { $0.capitalized }.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header — always visible
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(muscleLabel)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(dateLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < entry.feedback.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(i < entry.feedback.rating ? .yellow : .secondary)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Detail — expanded
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.workout.sections) { section in
                        Text(section.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)

                        switch section {
                        case .main(let exercises):
                            ForEach(exercises) { ex in
                                let skipped = entry.completion.removedExercises.contains(ex.id)
                                let done = entry.completion.completedSets[ex.id]
                                let setsComplete = done?.count ?? 0
                                HStack(spacing: 6) {
                                    Image(systemName: skipped ? "xmark.circle" : (setsComplete == ex.sets.count ? "checkmark.circle.fill" : "circle"))
                                        .font(.caption)
                                        .foregroundStyle(skipped ? .red : (setsComplete == ex.sets.count ? .green : .secondary))
                                    Text(ex.name)
                                        .font(.subheadline)
                                        .strikethrough(skipped)
                                        .foregroundStyle(skipped ? .secondary : .primary)
                                    Spacer()
                                    if !skipped {
                                        Text("\(setsComplete)/\(ex.sets.count)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                        case .warmup(let exercises), .cardio(let exercises), .cooldown(let exercises):
                            ForEach(exercises) { ex in
                                let skipped = entry.completion.removedExercises.contains(ex.id)
                                let done = entry.completion.completedTimed.contains(ex.id)
                                HStack(spacing: 6) {
                                    Image(systemName: skipped ? "xmark.circle" : (done ? "checkmark.circle.fill" : "circle"))
                                        .font(.caption)
                                        .foregroundStyle(skipped ? .red : (done ? .green : .secondary))
                                    Text(ex.name)
                                        .font(.subheadline)
                                        .strikethrough(skipped)
                                        .foregroundStyle(skipped ? .secondary : .primary)
                                    Spacer()
                                    if !skipped {
                                        let mins = Int(ex.duration) / 60
                                        Text("\(mins) min")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    if !entry.feedback.notes.isEmpty {
                        Text(entry.feedback.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}
