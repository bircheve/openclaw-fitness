import Foundation
import SwiftUI
import Combine

@MainActor
final class NutritionViewModel: ObservableObject {
    @Published var plan: NutritionPlan?
    @Published var selectedPhase: Int = 0
    @Published var selectedDay: Int = 0
    @Published var isLoading = false
    @Published var error: String?

    private let repo: NutritionRepository

    init(repo: NutritionRepository) {
        self.repo = repo
    }

    var currentPhase: NutritionPhase? {
        guard let plan, selectedPhase < plan.phases.count else { return nil }
        return plan.phases[selectedPhase]
    }

    var currentDay: NutritionDay? {
        guard let phase = currentPhase, selectedDay < phase.days.count else { return nil }
        return phase.days[selectedDay]
    }

    var dayNames: [String] {
        currentPhase?.days.map { String($0.day.prefix(3)) } ?? []
    }

    func load() {
        isLoading = true
        error = nil
        Task {
            do {
                let p = try await repo.loadPlan()
                self.plan = p
                self.isLoading = false
            } catch let repoError as RepoError where repoError == .offline {
                self.error = "Can't load nutrition. Check connection."
                self.isLoading = false
            } catch {
                self.error = "Failed to load nutrition plan."
                self.isLoading = false
            }
        }
    }

    /// Group meals by slot for display.
    var mealsBySlot: [(slot: String, meals: [Meal])] {
        guard let day = currentDay else { return [] }
        var grouped: [(String, [Meal])] = []
        var seen: Set<String> = []
        for meal in day.meals {
            let slot = meal.slot
            if !seen.contains(slot) {
                seen.insert(slot)
                grouped.append((slot, day.meals.filter { $0.slot == slot }))
            }
        }
        return grouped
    }
}
