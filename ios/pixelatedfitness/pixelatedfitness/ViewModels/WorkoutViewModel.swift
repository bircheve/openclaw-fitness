import Foundation
import SwiftUI
import Combine

enum WorkoutSectionFilter: String, CaseIterable {
    case all = "All"
    case warmup = "Warm-up"
    case main = "Main"
    case cardio = "Cardio"
    case cooldown = "Cooldown"

    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .warmup: return "figure.walk"
        case .main: return "dumbbell"
        case .cardio: return "heart.fill"
        case .cooldown: return "figure.cooldown"
        }
    }

    var tintColor: Color {
        switch self {
        case .all:
            return Color(red: 0.30, green: 0.51, blue: 1.0)
        case .warmup:
            return Color(red: 0.98, green: 0.55, blue: 0.24)
        case .main:
            return Color(red: 0.47, green: 0.29, blue: 1.0)
        case .cardio:
            return Color(red: 0.24, green: 0.78, blue: 0.55)
        case .cooldown:
            return Color(red: 0.60, green: 0.40, blue: 0.94)
        }
    }
}

enum WorkoutViewOutput: Equatable {
    case finished(Workout, CompletionSummary)
}

@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published var workout: Workout?
    @Published var isLoading = false
    @Published var error: String?
    @Published var waitingForWorkout = false

    @Published var completedSets: [String: Set<Int>] = [:]
    @Published var completedTimed: Set<String> = []
    @Published var removedExercises: Set<String> = []

    @Published var selectedSection: WorkoutSectionFilter = .all

    private let repo: WorkoutRepository
    private let onOutput: @Sendable (WorkoutViewOutput) -> Void
    private var pollTask: Task<Void, Never>?
    private var syncTask: Task<Void, Never>?

    init(repo: WorkoutRepository, onOutput: @escaping @Sendable (WorkoutViewOutput) -> Void = { _ in }) {
        self.repo = repo
        self.onOutput = onOutput
    }

    var filteredSections: [WorkoutSection] {
        guard let workout = workout else { return [] }

        switch selectedSection {
        case .all:
            return workout.sections
        case .warmup:
            return workout.sections.filter { if case .warmup = $0 { return true } else { return false } }
        case .main:
            return workout.sections.filter { if case .main = $0 { return true } else { return false } }
        case .cardio:
            return workout.sections.filter { if case .cardio = $0 { return true } else { return false } }
        case .cooldown:
            return workout.sections.filter { if case .cooldown = $0 { return true } else { return false } }
        }
    }

    func load() {
        isLoading = true
        error = nil
        waitingForWorkout = false
        Task {
            do {
                let w = try await repo.loadWorkout()
                self.workout = w
                self.selectedSection = .all
                self.isLoading = false
                self.waitingForWorkout = false
                stopPolling()
                startSyncPolling()
            } catch let repoError as RepoError where repoError == .notFound {
                self.workout = nil
                self.completedSets = [:]
                self.completedTimed = []
                self.removedExercises = []
                self.isLoading = false
                self.waitingForWorkout = true
                startPolling()
            } catch let repoError as RepoError where repoError == .offline {
                self.workout = nil
                self.isLoading = false
                self.waitingForWorkout = true
                startPolling()
            } catch {
                self.error = String(describing: error)
                self.isLoading = false
            }
        }
    }

    func retry() {
        load()
    }

    private func startPolling() {
        stopPolling()
        pollTask = Task {
            while !Task.isCancelled && waitingForWorkout {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled, waitingForWorkout else { break }
                do {
                    let w = try await repo.loadWorkout()
                    self.workout = w
                    self.selectedSection = .all
                    self.waitingForWorkout = false
                    stopPolling()
                    startSyncPolling()
                    return
                } catch {
                    // Keep polling
                }
            }
        }
    }

    private func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func startSyncPolling() {
        stopSyncPolling()
        syncTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { break }
                do {
                    let w = try await repo.loadWorkout()
                    if w.version != self.workout?.version {
                        self.applySyncUpdate(w)
                    }
                } catch let repoError as RepoError where repoError == .notFound {
                    // Workout was cleared (completed elsewhere) — reset
                    self.workout = nil
                    self.completedSets = [:]
                    self.completedTimed = []
                    self.removedExercises = []
                    self.waitingForWorkout = true
                    stopSyncPolling()
                    startPolling()
                    return
                } catch {
                    // Transient failure — keep current workout, keep polling
                }
            }
        }
    }

    private func stopSyncPolling() {
        syncTask?.cancel()
        syncTask = nil
    }

    /// Apply a version update while preserving completion state for exercises that still exist.
    private func applySyncUpdate(_ newWorkout: Workout) {
        let newExerciseIDs = Set(newWorkout.sections.flatMap { section -> [String] in
            switch section {
            case .warmup(let arr): return arr.map(\.id)
            case .main(let arr): return arr.map(\.id)
            case .cardio(let arr): return arr.map(\.id)
            case .cooldown(let arr): return arr.map(\.id)
            }
        })

        // Keep completion state only for exercises that still exist
        completedSets = completedSets.filter { newExerciseIDs.contains($0.key) }
        completedTimed = completedTimed.filter { newExerciseIDs.contains($0) }
        removedExercises = removedExercises.filter { newExerciseIDs.contains($0) }

        self.workout = newWorkout
    }

    func updateWorkout(_ newWorkout: Workout) {
        self.workout = newWorkout
        self.completedSets = [:]
        self.completedTimed = []
        self.removedExercises = []
        self.selectedSection = .all
        self.waitingForWorkout = false
        stopPolling()
        startSyncPolling()
    }

    func toggleSet(exerciseID: String, setIndex: Int, totalSets: Int) {
        var set = completedSets[exerciseID, default: []]
        if set.contains(setIndex) { set.remove(setIndex) } else { set.insert(setIndex) }
        completedSets[exerciseID] = set

        if set.count == totalSets { maybeFinish() }
    }

    func toggleTimed(exerciseID: String) {
        if completedTimed.contains(exerciseID) {
            completedTimed.remove(exerciseID)
        } else {
            completedTimed.insert(exerciseID)
        }
        maybeFinish()
    }

    func isExerciseCompleted(_ e: StrengthExercise) -> Bool {
        completedSets[e.id, default: []].count == e.sets.count
    }
    func isExerciseCompleted(_ e: TimedExercise) -> Bool {
        completedTimed.contains(e.id)
    }

    private func maybeFinish() {
        guard let w = workout else { return }
        let allDone = w.sections.allSatisfy { section in
            switch section {
            case .warmup(let arr):  return arr.allSatisfy { isExerciseCompleted($0) }
            case .main(let arr):    return arr.allSatisfy { isExerciseCompleted($0) }
            case .cardio(let arr):  return arr.allSatisfy { isExerciseCompleted($0) }
            case .cooldown(let arr):return arr.allSatisfy { isExerciseCompleted($0) }
            }
        }
        if allDone {
            stopSyncPolling()
            let summary = CompletionSummary(
                completedSets: completedSets,
                completedTimed: completedTimed,
                removedExercises: removedExercises
            )
            onOutput(.finished(w, summary))
        }
    }

    // MARK: - Swipe Actions

    func completeAllSets(exerciseID: String, totalSets: Int) {
        completedSets[exerciseID] = Set(0..<totalSets)
        maybeFinish()
    }

    func removeExercise(exerciseID: String) {
        removedExercises.insert(exerciseID)
        Task {
            try? await repo.patchWorkout(action: "remove_exercise", exerciseId: exerciseID)
        }
    }
}
