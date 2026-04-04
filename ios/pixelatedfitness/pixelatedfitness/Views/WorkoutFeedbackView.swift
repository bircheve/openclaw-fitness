import SwiftUI

struct WorkoutFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var feedback: WorkoutFeedback
    var onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How was your workout?")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Your summary will be copied to clipboard for your AI coach.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Rating") {
                    Stepper("Rating: \(feedback.rating)", value: $feedback.rating, in: 1...5)
                    TextField("Notes (optional)", text: $feedback.notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Workout Feedback")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Copy to Clipboard") {
                        onSubmit()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview("WorkoutFeedbackView") {
    WorkoutFeedbackView(
        feedback: .constant(WorkoutFeedback(rating: 3, notes: "")),
        onSubmit: {}
    )
}
