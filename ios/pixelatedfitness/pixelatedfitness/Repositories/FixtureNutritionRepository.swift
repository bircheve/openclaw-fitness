import Foundation

final class FixtureNutritionRepository: NutritionRepository {
    func loadPlan() async throws -> NutritionPlan {
        NutritionPlan(
            phases: [
                NutritionPhase(id: "weeks-1-3", name: "Weeks 1-3", days: [
                    NutritionDay(day: "Monday", targets: MacroTargets(calories: 2355, fat: 60, carbs: 213, protein: 250), meals: [
                        Meal(id: "1", position: 0, slot: "breakfast", name: "Basic Omelette", ingredients: ["1 Egg", "1/4 cup Egg Whites"], directions: ["Whisk together and cook in a pan."], macros: MacroTargets(calories: 103, fat: 5, carbs: 1, protein: 13)),
                    ]),
                ]),
            ],
            substitutions: [:],
            freeFoods: []
        )
    }
}
