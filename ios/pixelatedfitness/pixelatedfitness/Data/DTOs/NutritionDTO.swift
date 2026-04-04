import Foundation

struct NutritionPlanDTO: Decodable {
    let phases: [NutritionPhaseDTO]
    let substitutions: [String: String]
    let free_foods: [String]
}

struct NutritionPhaseDTO: Decodable {
    let id: String
    let name: String
    let days: [NutritionDayDTO]
}

struct NutritionDayDTO: Decodable {
    let day: String
    let targets: MacroTargetsDTO
    let meals: [MealDTO]
}

struct MacroTargetsDTO: Decodable {
    let calories: Int
    let fat: Int
    let carbs: Int
    let protein: Int
}

struct MealDTO: Decodable {
    let id: String
    let position: Int
    let slot: String
    let name: String
    let ingredients: [String]
    let directions: [String]
    let macros: MacroTargetsDTO
}
