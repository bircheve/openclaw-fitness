import Foundation

// MARK: - User Profile Models

struct UserProfile: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let subscriptionStatus: SubscriptionStatus
    let createdAt: Date
    let profileImageURL: String?
    let preferences: UserPreferences
    let stats: UserStats

    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        phone: String? = nil,
        subscriptionStatus: SubscriptionStatus = .free,
        createdAt: Date = Date(),
        profileImageURL: String? = nil,
        preferences: UserPreferences = UserPreferences(),
        stats: UserStats = UserStats()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.subscriptionStatus = subscriptionStatus
        self.createdAt = createdAt
        self.profileImageURL = profileImageURL
        self.preferences = preferences
        self.stats = stats
    }
}

struct UserPreferences: Equatable, Sendable, Codable {
    let preferredCardioEquipment: String?
    let preferredStrengthEquipment: String?
    let workoutIntensity: WorkoutIntensity
    let workoutDuration: WorkoutDuration
    let fitnessGoals: [String]
    let availableEquipment: [String]
    let workoutDaysPerWeek: Int
    let preferredWorkoutTime: String?

    init(
        preferredCardioEquipment: String? = nil,
        preferredStrengthEquipment: String? = nil,
        workoutIntensity: WorkoutIntensity = .moderate,
        workoutDuration: WorkoutDuration = .thirtyToFortyFive,
        fitnessGoals: [String] = [],
        availableEquipment: [String] = [],
        workoutDaysPerWeek: Int = 3,
        preferredWorkoutTime: String? = nil
    ) {
        self.preferredCardioEquipment = preferredCardioEquipment
        self.preferredStrengthEquipment = preferredStrengthEquipment
        self.workoutIntensity = workoutIntensity
        self.workoutDuration = workoutDuration
        self.fitnessGoals = fitnessGoals
        self.availableEquipment = availableEquipment
        self.workoutDaysPerWeek = workoutDaysPerWeek
        self.preferredWorkoutTime = preferredWorkoutTime
    }
}

struct UserStats: Equatable, Sendable, Codable {
    let totalWorkouts: Int
    let weeklyWorkouts: Int
    let currentStreak: Int
    let longestStreak: Int
    let favoriteExercises: [String]
    let totalWorkoutTime: TimeInterval
    let lastWorkoutDate: Date?

    init(
        totalWorkouts: Int = 0,
        weeklyWorkouts: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        favoriteExercises: [String] = [],
        totalWorkoutTime: TimeInterval = 0,
        lastWorkoutDate: Date? = nil
    ) {
        self.totalWorkouts = totalWorkouts
        self.weeklyWorkouts = weeklyWorkouts
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.favoriteExercises = favoriteExercises
        self.totalWorkoutTime = totalWorkoutTime
        self.lastWorkoutDate = lastWorkoutDate
    }
}

// MARK: - Enums

enum SubscriptionStatus: String, CaseIterable, Codable {
    case free = "Free"
    case premium = "Premium"
    case trial = "Trial"
}

enum WorkoutIntensity: String, CaseIterable, Codable {
    case light = "Light"
    case moderate = "Moderate"
    case intense = "Intense"
}

enum WorkoutDuration: String, CaseIterable, Codable {
    case fifteenToThirty = "15-30 minutes"
    case thirtyToFortyFive = "30-45 minutes"
    case fortyFiveToSixty = "45-60 minutes"
    case sixtyPlus = "60+ minutes"
}

// MARK: - Repository Protocol

protocol UserRepository: Sendable {
    func loadUserProfile() async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws
    func deleteUserAccount() async throws
    func updatePreferences(_ preferences: UserPreferences) async throws

    // Synchronous access for pre-loaded data
    var currentUserProfile: UserProfile? { get }
}

// MARK: - Repository Errors

enum UserRepositoryError: Error, Equatable, Sendable {
    case notFound
    case unauthorized
    case offline
    case server
    case decoding
    case unknown
}

// MARK: - Fixture Data Helper

extension UserProfile {
    static func sampleProfile() -> UserProfile {
        UserProfile(
            name: "User",
            email: "user@example.com",
            phone: "+1 (555) 123-4567",
            subscriptionStatus: .premium,
            preferences: UserPreferences(
                preferredCardioEquipment: "Stairmaster",
                preferredStrengthEquipment: "Dumbbells",
                workoutIntensity: .moderate,
                workoutDuration: .thirtyToFortyFive,
                fitnessGoals: ["General Fitness", "Strength", "Endurance"],
                availableEquipment: ["Dumbbells", "Resistance Bands", "Yoga Mat", "Kettlebells"],
                workoutDaysPerWeek: 4,
                preferredWorkoutTime: "Morning"
            ),
            stats: UserStats(
                totalWorkouts: 32,
                weeklyWorkouts: 3,
                currentStreak: 6,
                longestStreak: 10,
                favoriteExercises: ["Push-ups", "Squats", "Plank"],
                totalWorkoutTime: 1920, // 32 hours
                lastWorkoutDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
            )
        )
    }
}
