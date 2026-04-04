import Foundation
import SwiftUI

struct AppDependencies: Sendable {
    var workouts: WorkoutRepository
    var nutrition: NutritionRepository
    var user: UserRepository
}

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies(
        workouts: FixtureWorkoutRepository(),
        nutrition: FixtureNutritionRepository(),
        user: FixtureUserRepository()
    )
}

extension EnvironmentValues {
    var deps: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
