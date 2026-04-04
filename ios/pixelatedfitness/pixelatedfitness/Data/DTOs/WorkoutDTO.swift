import Foundation

struct WorkoutResponseDTO: Decodable {
    let workout_id: String
    let muscle_groups: [String]
    let work: WorkDTO
    let version: Int?
}

struct WorkDTO: Decodable {
    let warmup: TimeBasedWorkoutDTO
    let main: StrengthBasedWorkoutDTO
    let cardio: TimeBasedWorkoutDTO
    let cooldown: TimeBasedWorkoutDTO
}

struct StrengthBasedWorkoutDTO: Decodable {
    let exercises: [StrengthExerciseDTO]
}

struct StrengthExerciseDTO: Decodable {
    let id: String
    let position: Int
    let name: String
    let instructions: String
    let equipment: String
    let muscle_groups: [String]
    let sets: [SetDTO]
}

struct SetDTO: Decodable { let reps: Double }

struct TimeBasedWorkoutDTO: Decodable {
    let exercises: [TimedExerciseDTO]
}

struct TimedExerciseDTO: Decodable {
    let id: String
    let position: Int
    let duration: Double
    let name: String
    let instructions: String
    let equipment: String
}