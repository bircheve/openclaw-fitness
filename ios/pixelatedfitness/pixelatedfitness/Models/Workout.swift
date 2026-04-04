import Foundation

struct Workout: Identifiable, Equatable, Sendable {
    let id: String
    let muscleGroups: [String]
    let sections: [WorkoutSection]
    let version: Int?
}

enum WorkoutSection: Equatable, Sendable, Identifiable {
    case warmup([TimedExercise])
    case main([StrengthExercise])
    case cardio([TimedExercise])
    case cooldown([TimedExercise])

    var id: String {
        switch self {
        case .warmup: return "warmup"
        case .main: return "main"
        case .cardio: return "cardio"
        case .cooldown: return "cooldown"
        }
    }

    var title: String {
        switch self {
        case .warmup: "Warm-up"
        case .main: "Main"
        case .cardio: "Cardio"
        case .cooldown: "Cooldown"
        }
    }
}

struct StrengthExercise: Identifiable, Equatable, Sendable {
    let id: String
    let position: Int
    let name: String
    let instructions: String
    let equipment: String
    let muscleGroups: [String]
    let sets: [SetTarget]
}

struct TimedExercise: Identifiable, Equatable, Sendable {
    let id: String
    let position: Int
    let name: String
    let instructions: String
    let equipment: String
    let duration: TimeInterval
}

struct SetTarget: Equatable, Sendable { let reps: Int }

struct WorkoutFeedback: Equatable, Sendable {
    var rating: Int
    var notes: String
}

/// Snapshot of what the user completed during a workout session.
struct CompletionSummary: Equatable, Sendable {
    let completedSets: [String: Set<Int>]
    let completedTimed: Set<String>
    let removedExercises: Set<String>
}

/// A completed workout with feedback, stored in history.
struct CompletedWorkout: Identifiable, Equatable, Sendable {
    let workout: Workout
    let feedback: WorkoutFeedback
    let completion: CompletionSummary
    let completedAt: Date

    var id: String { workout.id + "-" + completedAt.ISO8601Format() }
}

