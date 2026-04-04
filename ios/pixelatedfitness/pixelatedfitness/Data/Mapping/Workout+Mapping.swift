import Foundation

extension Workout {
    init(dto: WorkoutResponseDTO, id: String = UUID().uuidString) {
        self.id = dto.workout_id
        self.muscleGroups = dto.muscle_groups
        self.version = dto.version

        let warmup = dto.work.warmup.exercises.map(TimedExercise.init(dto:))
        let main = dto.work.main.exercises.map(StrengthExercise.init(dto:))
        let cardio = dto.work.cardio.exercises.map(TimedExercise.init(dto:))
        let cooldown = dto.work.cooldown.exercises.map(TimedExercise.init(dto:))

        print("🏋️ Loaded workout: \(dto.workout_id)")
        print("🏋️ Warmup exercises: \(warmup.count)")
        print("🏋️ Main exercises: \(main.count)")
        print("🏋️ Cardio exercises: \(cardio.count)")
        print("🏋️ Cooldown exercises: \(cooldown.count)")

        self.sections = [
            .warmup(warmup), .main(main), .cardio(cardio), .cooldown(cooldown)
        ]
    }
}

extension StrengthExercise {
    init(dto: StrengthExerciseDTO) {
        self.id = dto.id
        self.position = dto.position
        self.name = dto.name
        self.instructions = String(dto.instructions.prefix(200))
        self.equipment = dto.equipment
        self.muscleGroups = dto.muscle_groups
        self.sets = dto.sets.map { SetTarget(reps: Int($0.reps.rounded())) }

        print("💪 Loaded strength exercise: \(dto.name) (ID: \(dto.id), Position: \(dto.position))")
    }
}

extension TimedExercise {
    init(dto: TimedExerciseDTO) {
        self.id = dto.id
        self.position = dto.position
        self.name = dto.name
        self.instructions = String(dto.instructions.prefix(200))
        self.equipment = dto.equipment
        self.duration = dto.duration

        print("⏱️ Loaded timed exercise: \(dto.name) (ID: \(dto.id), Position: \(dto.position), Duration: \(dto.duration)s)")
    }
}