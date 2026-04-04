import Foundation

protocol NutritionRepository: Sendable {
    func loadPlan() async throws -> NutritionPlan
}
