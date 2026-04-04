import Foundation

final class BridgeWorkoutRepository: WorkoutRepository, @unchecked Sendable {
    private let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func loadWorkout() async throws -> Workout {
        let url = baseURL.appendingPathComponent("workout")
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RepoError.offline
        }

        guard let http = response as? HTTPURLResponse else { throw RepoError.unknown }

        switch http.statusCode {
        case 200: break
        case 404: throw RepoError.notFound
        default: throw RepoError.server
        }

        do {
            let dto = try JSONDecoder().decode(WorkoutResponseDTO.self, from: data)
            return Workout(dto: dto)
        } catch {
            throw RepoError.decoding
        }
    }

    func checkHealth() async -> Bool {
        let url = baseURL.appendingPathComponent("health")
        let request = URLRequest(url: url, timeoutInterval: 5)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return http.statusCode == 200
        } catch {
            return false
        }
    }

    func patchWorkout(action: String, exerciseId: String) async throws {
        let url = baseURL.appendingPathComponent("workout")
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["action": action, "exercise_id": exerciseId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
    }

    func submitFeedback(for workoutId: String, _ feedback: WorkoutFeedback, completion: CompletionSummary) async throws {
        let url = baseURL.appendingPathComponent("workout/\(workoutId)/complete")
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "feedback": [
                "rating": feedback.rating,
                "notes": feedback.notes,
            ],
            "completion": [
                "completedSets": completion.completedSets.mapValues { Array($0) },
                "completedTimed": Array(completion.completedTimed),
                "removedExercises": Array(completion.removedExercises),
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            // Non-critical — clipboard copy is the primary feedback path
            return
        }
    }

    func loadHistory() async throws -> [CompletedWorkout] {
        let url = baseURL.appendingPathComponent("history")
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RepoError.offline
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw RepoError.server
        }

        do {
            let entries = try JSONDecoder().decode([HistoryEntryDTO].self, from: data)
            return entries.compactMap { $0.toDomain() }
        } catch {
            throw RepoError.decoding
        }
    }
}

// MARK: - History DTO

private struct HistoryEntryDTO: Decodable {
    let workout: WorkoutResponseDTO
    let feedback: FeedbackDTO?
    let completion: CompletionDTO?
    let completed_at: String?

    struct FeedbackDTO: Decodable {
        let rating: Int?
        let notes: String?
    }

    struct CompletionDTO: Decodable {
        let completedSets: [String: [Int]]?
        let completedTimed: [String]?
        let removedExercises: [String]?
    }

    func toDomain() -> CompletedWorkout? {
        let w = Workout(dto: workout)
        let fb = WorkoutFeedback(
            rating: feedback?.rating ?? 0,
            notes: feedback?.notes ?? ""
        )
        let comp = CompletionSummary(
            completedSets: (completion?.completedSets ?? [:]).mapValues { Set($0) },
            completedTimed: Set(completion?.completedTimed ?? []),
            removedExercises: Set(completion?.removedExercises ?? [])
        )

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = completed_at.flatMap { formatter.date(from: $0) } ?? Date()

        return CompletedWorkout(workout: w, feedback: fb, completion: comp, completedAt: date)
    }
}
