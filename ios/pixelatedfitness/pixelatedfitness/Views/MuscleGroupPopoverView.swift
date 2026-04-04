import SwiftUI

/// Shared color palette + popover content for displaying muscle group metadata.
struct MuscleGroupPopoverView: View {
    let muscleNames: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Targeted Muscles")
                .pxHeadline()
                .foregroundStyle(.primary)

            ForEach(Array(muscleNames.enumerated()), id: \.offset) { _, rawName in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(MuscleGroupPalette.color(for: rawName))
                        .frame(width: 16, height: 16)

                    Text(rawName.capitalized)
                        .pxSubheadline()
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 22)
        .frame(minWidth: 220, alignment: .leading)
        .background(popoverBackground)
        .overlay(popoverBorder)
        .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 10)
        .shadow(color: accentColor.opacity(0.2), radius: 6, x: 0, y: 2)
    }

    private var accentColor: Color {
        guard let first = muscleNames.first else { return .accentColor }
        return MuscleGroupPalette.color(for: first)
    }

    private var popoverBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        return shape
            .fill(.clear)
            .glassEffect(
                Glass.regular
                    .tint(accentColor.opacity(0.55))
                    .interactive(),
                in: shape
            )
    }

    @ViewBuilder
    private var popoverBorder: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        shape
            .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
            .blendMode(.overlay)
    }
}

enum MuscleGroupPalette {
    private static let muscleColors: [String: Color] = [
        "chest": Color(red: 0.94, green: 0.33, blue: 0.31),
        "back": Color(red: 0.19, green: 0.56, blue: 0.87),
        "shoulders": Color(red: 0.99, green: 0.68, blue: 0.28),
        "biceps": Color(red: 0.36, green: 0.72, blue: 0.35),
        "triceps": Color(red: 0.77, green: 0.44, blue: 0.81),
        "core": Color(red: 0.94, green: 0.54, blue: 0.21),
        "glutes": Color(red: 0.87, green: 0.35, blue: 0.53),
        "quads": Color(red: 0.52, green: 0.68, blue: 0.35),
        "hamstrings": Color(red: 0.39, green: 0.44, blue: 0.86),
        "calves": Color(red: 0.44, green: 0.73, blue: 0.83),
        "hip flexors": Color(red: 0.96, green: 0.72, blue: 0.44)
    ]

    static func color(for muscle: String) -> Color {
        muscleColors[muscle.lowercased(), default: .accentColor]
    }
}

#Preview("MuscleGroupPopoverView") {
    MuscleGroupPopoverView(muscleNames: ["Chest", "Back", "Core"])
}
