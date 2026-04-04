import Foundation

final class FixtureWorkoutRepository: WorkoutRepository {
    private let filename: String
    init(filename: String = "workouts.example") { self.filename = filename }

    func loadWorkout() async throws -> Workout {
        let url = Bundle.main.url(forResource: filename, withExtension: "json")!
        let data = try Data(contentsOf: url)
        let dto = try JSONDecoder().decode(WorkoutResponseDTO.self, from: data)
        return Workout(dto: dto)
    }

    func submitFeedback(for workoutId: String, _ feedback: WorkoutFeedback, completion: CompletionSummary) async throws {
        // Fixture mode — no-op
    }

    func loadHistory() async throws -> [CompletedWorkout] {
        // Fixture mode — return empty history
        return []
    }
}
