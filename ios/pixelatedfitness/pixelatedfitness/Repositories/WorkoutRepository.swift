import Foundation

enum RepoError: Error, Equatable, Sendable {
    case notFound, offline, server, decoding, unauthorized, unknown
}

protocol WorkoutRepository: Sendable {
    func loadWorkout() async throws -> Workout
    func submitFeedback(for workoutId: String, _ feedback: WorkoutFeedback, completion: CompletionSummary) async throws
    func loadHistory() async throws -> [CompletedWorkout]
    func patchWorkout(action: String, exerciseId: String) async throws
    func checkHealth() async -> Bool
}

extension WorkoutRepository {
    func patchWorkout(action: String, exerciseId: String) async throws {}
    func checkHealth() async -> Bool { true }
}
