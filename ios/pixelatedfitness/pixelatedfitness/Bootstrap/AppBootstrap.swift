import Foundation

struct AppBootstrap {
    static let preview = AppDependencies(
        workouts: FixtureWorkoutRepository(),
        nutrition: FixtureNutritionRepository(),
        user: FixtureUserRepository()
    )

    static var live: AppDependencies {
        let baseURL = URL(string: ConfigurationManager.bridgeBaseURL)!
        return AppDependencies(
            workouts: BridgeWorkoutRepository(baseURL: baseURL),
            nutrition: BridgeNutritionRepository(baseURL: baseURL),
            user: FixtureUserRepository()
        )
    }
}
