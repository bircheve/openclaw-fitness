import Foundation

final class FixtureUserRepository: UserRepository {
    private var currentUser: UserProfile
    private let simulateNetworkDelay: Bool

    // Synchronous access for pre-loaded data
    var currentUserProfile: UserProfile? { currentUser }

    init(user: UserProfile? = nil, simulateNetworkDelay: Bool = false) {
        // Use provided user or default to sample profile
        self.currentUser = user ?? UserProfile.sampleProfile()
        self.simulateNetworkDelay = simulateNetworkDelay
    }

    func loadUserProfile() async throws -> UserProfile {
        print("📁 Loading user profile from fixture data")

        if simulateNetworkDelay {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        print("✅ User profile loaded successfully")
        print("👤 User: \(currentUser.name) (\(currentUser.email))")
        print("📊 Subscription: \(currentUser.subscriptionStatus.rawValue)")
        print("💪 Total workouts: \(currentUser.stats.totalWorkouts)")

        return currentUser
    }

    func updateUserProfile(_ profile: UserProfile) async throws {
        print("📝 Updating user profile in fixture repository")

        if simulateNetworkDelay {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 750_000_000) // 0.75 seconds
        }

        // In a real implementation, we'd validate the update
        currentUser = profile

        print("✅ User profile updated successfully")
        print("👤 Updated user: \(profile.name) (\(profile.email))")
    }

    func deleteUserAccount() async throws {
        print("🗑️ Deleting user account (fixture)")

        if simulateNetworkDelay {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }

        print("✅ User account deleted (simulated)")

        // In a real implementation, this would actually delete the account
        // For fixture, we'll just reset to a default user
        currentUser = UserProfile(
            name: "Deleted User",
            email: "deleted@example.com",
            subscriptionStatus: .free
        )
    }

    func updatePreferences(_ preferences: UserPreferences) async throws {
        print("⚙️ Updating user preferences in fixture repository")

        if simulateNetworkDelay {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        }

        // Update the current user's preferences
        currentUser = UserProfile(
            id: currentUser.id,
            name: currentUser.name,
            email: currentUser.email,
            phone: currentUser.phone,
            subscriptionStatus: currentUser.subscriptionStatus,
            createdAt: currentUser.createdAt,
            profileImageURL: currentUser.profileImageURL,
            preferences: preferences,
            stats: currentUser.stats
        )

        print("✅ User preferences updated successfully")
        print("🎯 Goals: \(preferences.fitnessGoals.joined(separator: ", "))")
        print("💪 Intensity: \(preferences.workoutIntensity.rawValue)")
    }
}

// MARK: - Convenience Initializers

extension FixtureUserRepository {
    /// Creates a repository with a new user (minimal data)
    static func newUser(name: String, email: String) -> FixtureUserRepository {
        let newUser = UserProfile(name: name, email: email)
        return FixtureUserRepository(user: newUser)
    }

    /// Creates a repository without network delay (for faster testing)
    static func instant() -> FixtureUserRepository {
        return FixtureUserRepository(simulateNetworkDelay: false)
    }
}