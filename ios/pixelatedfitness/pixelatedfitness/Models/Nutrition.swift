import Foundation

struct NutritionPlan: Equatable, Sendable {
    let phases: [NutritionPhase]
    let substitutions: [String: String]
    let freeFoods: [String]
}

struct NutritionPhase: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let days: [NutritionDay]
}

struct NutritionDay: Identifiable, Equatable, Sendable {
    let day: String
    let targets: MacroTargets
    let meals: [Meal]

    var id: String { day }
}

struct MacroTargets: Equatable, Sendable {
    let calories: Int
    let fat: Int
    let carbs: Int
    let protein: Int
}

struct Meal: Identifiable, Equatable, Sendable {
    let id: String
    let position: Int
    let slot: String
    let name: String
    let ingredients: [String]
    let directions: [String]
    let macros: MacroTargets
}
