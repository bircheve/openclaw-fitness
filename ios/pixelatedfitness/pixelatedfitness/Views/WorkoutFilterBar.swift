import SwiftUI

struct WorkoutFilterBar: View {
    @Binding var selectedSection: WorkoutSectionFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WorkoutSectionFilter.allCases, id: \.self) { section in
                    FilterButton(
                        title: section.rawValue,
                        iconName: section.iconName,
                        tintColor: section.tintColor,
                        isSelected: selectedSection == section
                    ) {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()

                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedSection = section
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct FilterButton: View {
    let title: String
    let iconName: String
    let tintColor: Color
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: isSelected ? 15 : 18, weight: isSelected ? .semibold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)

                if isSelected {
                    Text(title)
                        .font(.system(.callout, weight: .semibold))
                        .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                }
            }
            .foregroundStyle(foregroundStyle)
            .frame(
                width: isSelected ? nil : 44,
                height: 44
            )
            .frame(minWidth: isSelected ? buttonMinWidth : 44)
            .padding(.horizontal, isSelected ? 20 : 0)
            .background(backgroundShape)
            .overlay(overlayStroke)
            .contentShape(isSelected ? AnyShape(Capsule(style: .continuous)) : AnyShape(Circle()))
            .shadow(
                color: isSelected ? tintColor.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 2 : 0
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var buttonMinWidth: CGFloat {
        120 // Minimum width for expanded button
    }

    private var foregroundStyle: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.white)
        } else {
            return AnyShapeStyle(unselectedForeground)
        }
    }

    private var backgroundShape: some View {
        Group {
            if isSelected {
                Capsule(style: .continuous)
                    .fill(AnyShapeStyle(selectedBackground))
            } else {
                Circle()
                    .fill(AnyShapeStyle(unselectedBackground))
            }
        }
    }

    private var overlayStroke: some View {
        Group {
            if isSelected {
                Capsule(style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 0)
            } else {
                Circle()
                    .strokeBorder(strokeColor, lineWidth: 0.5)
            }
        }
    }

    private var selectedBackground: some ShapeStyle {
        // Enhanced gradient for selected state
        LinearGradient(
            colors: [tintColor, tintColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var strokeColor: Color {
        if isSelected {
            return Color.clear
        } else {
            return Color.primary.opacity(colorScheme == .dark ? 0.2 : 0.15)
        }
    }

    private var unselectedBackground: Color {
        Color(uiColor: colorScheme == .dark ? .tertiarySystemFill : .secondarySystemGroupedBackground)
            .opacity(colorScheme == .dark ? 0.6 : 0.8)
    }

    private var unselectedForeground: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.8 : 0.75)
    }
}

#Preview {
    @Previewable @State var selectedSection = WorkoutSectionFilter.all
    return WorkoutFilterBar(selectedSection: $selectedSection)
        .padding()
}
