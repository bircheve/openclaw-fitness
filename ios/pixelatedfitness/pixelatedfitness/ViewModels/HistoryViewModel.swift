import Combine
import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var history: [CompletedWorkout] = []
    @Published var isLoading = false
    @Published var error: String?

    private let repo: WorkoutRepository

    init(repo: WorkoutRepository) {
        self.repo = repo
    }

    func load() {
        isLoading = true
        error = nil
        Task {
            do {
                let items = try await repo.loadHistory()
                self.history = items
                self.isLoading = false
            } catch let e as RepoError where e == .offline {
                self.error = "Can't reach the bridge server. Check your connection."
                self.isLoading = false
            } catch {
                self.error = String(describing: error)
                self.isLoading = false
            }
        }
    }
}
