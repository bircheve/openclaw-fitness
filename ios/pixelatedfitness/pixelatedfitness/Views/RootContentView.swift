import SwiftUI
import UIKit

struct RootContentView: View {
    @Environment(\.deps) private var deps

    @State private var pendingWorkoutFeedback: WorkoutFeedbackState?
    @State private var feedbackError: String?
    @State private var sharedWorkoutViewModel: WorkoutViewModel?
    @State private var sharedNutritionViewModel: NutritionViewModel?
    @State private var showClipboardToast = false
    @State private var navigationPath: [AppRoute] = []
    @State private var selectedMode: AppMode = .workout

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                Picker("Mode", selection: $selectedMode) {
                    Text("Workout").tag(AppMode.workout)
                    Text("Nutrition").tag(AppMode.nutrition)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                Group {
                    switch selectedMode {
                    case .workout:
                        if let viewModel = sharedWorkoutViewModel {
                            WorkoutListView(viewModel: viewModel)
                        } else {
                            ProgressView()
                        }
                    case .nutrition:
                        if let viewModel = sharedNutritionViewModel {
                            NutritionView(viewModel: viewModel)
                        } else {
                            ProgressView()
                        }
                    }
                }
            }
            .navigationTitle(selectedMode == .workout ? "Workout" : "Nutrition")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        navigationPath.append(.settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigationPath.append(.history)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .history:
                    HistoryView(repo: deps.workouts)
                case .settings:
                    SettingsView()
                }
            }
        }
        .sheet(item: $pendingWorkoutFeedback) { pending in
            WorkoutFeedbackView(
                feedback: Binding(
                    get: { pendingWorkoutFeedback?.feedback ?? pending.feedback },
                    set: { pendingWorkoutFeedback?.feedback = $0 }
                ),
                onSubmit: { submitFeedback(for: pending.workout) }
            )
            .presentationDetents([.medium, .large])
        }
        .alert("Feedback Error", isPresented: Binding(
            get: { feedbackError != nil },
            set: { if !$0 { feedbackError = nil } }
        )) {
            Button("OK", role: .cancel) { feedbackError = nil }
        } message: {
            Text(feedbackError ?? "")
        }
        .overlay {
            if showClipboardToast {
                VStack {
                    Spacer()
                    Text("Workout copied — paste to your AI coach")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .allowsHitTesting(false)
            }
        }
        .task {
            if sharedWorkoutViewModel == nil {
                sharedWorkoutViewModel = WorkoutViewModel(repo: deps.workouts, onOutput: handleWorkoutOutput)
                sharedWorkoutViewModel?.load()
            }
            if sharedNutritionViewModel == nil {
                sharedNutritionViewModel = NutritionViewModel(repo: deps.nutrition)
            }
        }
    }
}

// MARK: - Navigation

private enum AppMode {
    case workout, nutrition
}

private enum AppRoute: Hashable {
    case history
    case settings
}

// MARK: - Coordinator helpers

private extension RootContentView {
    nonisolated func handleWorkoutOutput(_ output: WorkoutViewOutput) {
        Task { @MainActor in
            switch output {
            case .finished(let workout, let summary):
                pendingWorkoutFeedback = WorkoutFeedbackState(
                    workout: workout,
                    completionSummary: summary,
                    feedback: WorkoutFeedback(rating: 3, notes: "")
                )
            }
        }
    }

    func submitFeedback(for workout: Workout) {
        guard let pending = pendingWorkoutFeedback else { return }
        let feedback = pending.feedback
        let completionSummary = pending.completionSummary

        // Copy to clipboard immediately
        let summary = formatWorkoutSummary(
            workout: workout,
            completion: completionSummary,
            feedback: feedback
        )
        UIPasteboard.general.string = summary

        pendingWorkoutFeedback = nil
        feedbackError = nil

        withAnimation(.easeInOut(duration: 0.3)) {
            showClipboardToast = true
        }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeInOut(duration: 0.3)) {
                showClipboardToast = false
            }
        }

        // Also persist to bridge server (fire and forget)
        Task {
            try? await deps.workouts.submitFeedback(for: workout.id, feedback, completion: completionSummary)
            // Reload workout — it was cleared from bridge after completion
            sharedWorkoutViewModel?.load()
        }
    }

    func formatWorkoutSummary(workout: Workout, completion: CompletionSummary, feedback: WorkoutFeedback) -> String {
        var lines: [String] = []
        let muscleLabel = workout.muscleGroups.joined(separator: ", ")
        lines.append("Workout — \(muscleLabel)")
        lines.append("")

        for section in workout.sections {
            switch section {
            case .warmup(let exercises):
                lines.append("Warmup:")
                for ex in exercises {
                    let done = completion.completedTimed.contains(ex.id)
                    let skipped = completion.removedExercises.contains(ex.id)
                    let mins = Int(ex.duration) / 60
                    let label = mins > 0 ? "\(ex.name) (\(mins) min)" : ex.name
                    if skipped {
                        lines.append("  [skipped] \(label)")
                    } else {
                        lines.append("  \(done ? "+" : "-") \(label)")
                    }
                }
            case .main(let exercises):
                lines.append("Main:")
                for ex in exercises {
                    let skipped = completion.removedExercises.contains(ex.id)
                    let doneSets = completion.completedSets[ex.id] ?? []
                    let totalSets = ex.sets.count
                    if skipped {
                        lines.append("  [skipped] \(ex.name)")
                    } else {
                        let repsStr = ex.sets.map { "\($0.reps)" }.joined(separator: "/")
                        let setsLabel = "\(doneSets.count)/\(totalSets) sets"
                        lines.append("  \(doneSets.count == totalSets ? "+" : "-") \(ex.name): \(setsLabel) (\(repsStr) reps)")
                    }
                }
            case .cardio(let exercises):
                lines.append("Cardio:")
                for ex in exercises {
                    let done = completion.completedTimed.contains(ex.id)
                    let skipped = completion.removedExercises.contains(ex.id)
                    let mins = Int(ex.duration) / 60
                    if skipped {
                        lines.append("  [skipped] \(ex.name)")
                    } else {
                        lines.append("  \(done ? "+" : "-") \(ex.name) (\(mins) min)")
                    }
                }
            case .cooldown(let exercises):
                lines.append("Cooldown:")
                for ex in exercises {
                    let done = completion.completedTimed.contains(ex.id)
                    let skipped = completion.removedExercises.contains(ex.id)
                    let mins = Int(ex.duration) / 60
                    if skipped {
                        lines.append("  [skipped] \(ex.name)")
                    } else {
                        lines.append("  \(done ? "+" : "-") \(ex.name) (\(mins) min)")
                    }
                }
            }
            lines.append("")
        }

        lines.append("Rating: \(feedback.rating)/5")
        if !feedback.notes.isEmpty {
            lines.append("Notes: \(feedback.notes)")
        }

        return lines.joined(separator: "\n")
    }
}

private struct WorkoutFeedbackState: Identifiable, Equatable {
    let workout: Workout
    let completionSummary: CompletionSummary
    var feedback: WorkoutFeedback

    var id: String { workout.id }
}

#Preview("RootContentView") {
    RootContentView()
        .environment(\.deps, AppBootstrap.preview)
}
