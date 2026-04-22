import SwiftUI
import UIKit

struct RootContentView: View {
    @Environment(\.deps) private var deps
    @Environment(ToastCenter.self) private var toastCenter

    @State private var pendingWorkoutFeedback: WorkoutFeedbackState?
    @State private var sharedWorkoutViewModel: WorkoutViewModel?
    @State private var sharedNutritionViewModel: NutritionViewModel?
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
            case .exerciseRemovalPending(let exerciseID, let exerciseName):
                // Show an Undo toast. If the user taps Undo within the debounce
                // window, the PATCH is cancelled client-side (no server call).
                toastCenter.undoable("Removed \(exerciseName)") { [weak sharedWorkoutViewModel] in
                    sharedWorkoutViewModel?.undoRemoveExercise(exerciseID: exerciseID)
                }
            case .exerciseRemovalFailed(let exerciseName):
                toastCenter.error("Couldn't remove \(exerciseName) — put it back.")
            }
        }
    }

    func submitFeedback(for workout: Workout) {
        guard let pending = pendingWorkoutFeedback else { return }
        let feedback = pending.feedback
        let completionSummary = pending.completionSummary

        // Copy to clipboard immediately (primary user-visible outcome)
        let summary = formatWorkoutSummary(
            workout: workout,
            completion: completionSummary,
            feedback: feedback
        )
        UIPasteboard.general.string = summary

        pendingWorkoutFeedback = nil
        toastCenter.info("Workout copied — paste to your AI coach")

        // Persist to bridge server, surface outcome via toast + reload
        Task {
            do {
                try await deps.workouts.submitFeedback(for: workout.id, feedback, completion: completionSummary)
                toastCenter.success("Workout logged")
            } catch {
                toastCenter.error("Couldn't log workout to the coach — the clipboard copy is still available.") {
                    submitFeedback(for: workout)
                }
            }
            // Reload regardless — workout is cleared from bridge after completion
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
