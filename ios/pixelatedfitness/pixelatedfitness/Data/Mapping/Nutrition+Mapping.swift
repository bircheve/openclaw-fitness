import Foundation

extension NutritionPlan {
    init(dto: NutritionPlanDTO) {
        self.phases = dto.phases.map(NutritionPhase.init(dto:))
        self.substitutions = dto.substitutions
        self.freeFoods = dto.free_foods
    }
}

extension NutritionPhase {
    init(dto: NutritionPhaseDTO) {
        self.id = dto.id
        self.name = dto.name
        self.days = dto.days.map(NutritionDay.init(dto:))
    }
}

extension NutritionDay {
    init(dto: NutritionDayDTO) {
        self.day = dto.day
        self.targets = MacroTargets(dto: dto.targets)
        self.meals = dto.meals.map(Meal.init(dto:))
    }
}

extension MacroTargets {
    init(dto: MacroTargetsDTO) {
        self.calories = dto.calories
        self.fat = dto.fat
        self.carbs = dto.carbs
        self.protein = dto.protein
    }
}

extension Meal {
    init(dto: MealDTO) {
        self.id = dto.id
        self.position = dto.position
        self.slot = dto.slot
        self.name = dto.name
        self.ingredients = dto.ingredients
        self.directions = dto.directions
        self.macros = MacroTargets(dto: dto.macros)
    }
}
