import SwiftUI

/// Skeleton loading view that mimics the workout list layout
struct WorkoutSkeletonView: View {
    var body: some View {
        List {
            // Warmup section
            Section {
                ForEach(0..<3, id: \.self) { index in
                    SkeletonExerciseRow(showSets: false, rowIndex: index)
                }
            } header: {
                SkeletonSectionHeader()
            }

            // Main section
            Section {
                ForEach(0..<5, id: \.self) { index in
                    SkeletonExerciseRow(showSets: true, rowIndex: index)
                }
            } header: {
                SkeletonSectionHeader()
            }

            // Cardio section
            Section {
                ForEach(0..<2, id: \.self) { index in
                    SkeletonExerciseRow(showSets: false, rowIndex: index + 10)
                }
            } header: {
                SkeletonSectionHeader()
            }

            // Cooldown section
            Section {
                ForEach(0..<2, id: \.self) { index in
                    SkeletonExerciseRow(showSets: false, rowIndex: index + 20)
                }
            } header: {
                SkeletonSectionHeader()
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Skeleton Components

private struct SkeletonSectionHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonShape()
                .frame(width: 80, height: 17)

            SkeletonShape()
                .frame(width: 70, height: 15)

            Spacer()

            SkeletonShape()
                .frame(width: 14, height: 14)
        }
        .padding(.vertical, 8)
    }
}

private struct SkeletonExerciseRow: View {
    let showSets: Bool
    let rowIndex: Int

    // Deterministic widths based on row index to prevent jitter
    private var exerciseNameWidth: CGFloat {
        let widths: [CGFloat] = [140, 160, 120, 180, 150, 130, 170, 145, 155, 135]
        return widths[rowIndex % widths.count]
    }

    private var instructionWidth: CGFloat {
        let widths: [CGFloat] = [240, 220, 260, 200, 250, 230, 210, 270, 225, 245]
        return widths[rowIndex % widths.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise name
            HStack(spacing: 10) {
                if showSets {
                    // Muscle indicator
                    HStack(spacing: 4) {
                        SkeletonShape()
                            .frame(width: 14, height: 14)
                        SkeletonShape()
                            .frame(width: 14, height: 14)
                    }
                }

                SkeletonShape()
                    .frame(width: exerciseNameWidth, height: 17)

                Spacer()
            }

            // Instructions (2 lines)
            VStack(alignment: .leading, spacing: 4) {
                SkeletonShape()
                    .frame(height: 15)

                SkeletonShape()
                    .frame(width: instructionWidth, height: 15)
            }

            // Sets or duration
            HStack(spacing: 8) {
                if showSets {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonShape()
                            .frame(width: 36, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    SkeletonShape()
                        .frame(width: 80, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct SkeletonShape: View {
    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.2))
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.35),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * shimmerPhase))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1
                }
            }
    }
}

// MARK: - Preview

#Preview("Workout Skeleton") {
    WorkoutSkeletonView()
}
