import SwiftUI

struct WorkoutListView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var musclePopoverSize: CGSize = .zero
    @State private var activeMusclePopoverExerciseID: StrengthExercise.ID?
    @State private var collapsedSections: Set<String> = []

    private var vm: WorkoutViewModel { viewModel }

    private let musclePopoverVerticalGap: CGFloat = 12
    private let musclePopoverHorizontalPadding: CGFloat = 16
    private let musclePopoverEstimatedHeight: CGFloat = 140
    private let musclePopoverEstimatedWidth: CGFloat = 220

    var body: some View {
        // Group doesn't provide concrete layout structure needed by NavigationStack
        VStack(spacing: 0) {
            if vm.isLoading {
                WorkoutSkeletonView()
            } else if vm.waitingForWorkout {
                VStack(spacing: 16) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Waiting for workout")
                        .font(.title3.weight(.medium))
                    Text("Ask your AI coach for your workout — it'll appear here automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    ProgressView()
                        .padding(.top, 8)
                    Button("Retry Now") {
                        vm.retry()
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.error {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Connection Issue")
                        .font(.title3.weight(.medium))
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Retry") {
                        vm.retry()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.workout != nil {
                VStack(spacing: 0) {
                    // WorkoutFilterBar(selectedSection: $viewModel.selectedSection)

                    List {
                        ForEach(vm.filteredSections) { section in
                        Section {
                            if !collapsedSections.contains(section.id) {
                                switch section {
                                case .warmup(let exercises),
                                     .cardio(let exercises),
                                     .cooldown(let exercises):
                                    ForEach(exercises) { timed in
                                    if !vm.removedExercises.contains(timed.id) {
                                        TimedExerciseRow(
                                            exercise: timed,
                                            completed: vm.isExerciseCompleted(timed),
                                            onToggle: { vm.toggleTimed(exerciseID: timed.id) }
                                        )
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                vm.toggleTimed(exerciseID: timed.id)
                                            } label: {
                                                Label("Complete", systemImage: "checkmark.circle.fill")
                                            }
                                            .tint(.green)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                vm.removeExercise(exerciseID: timed.id, exerciseName: timed.name)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }

                            case .main(let exercises):
                                ForEach(exercises) { strength in
                                    if !vm.removedExercises.contains(strength.id) {
                                        StrengthExerciseRow(
                                            exercise: strength,
                                            completedIndices: vm.completedSets[strength.id, default: []],
                                            onTapSet: { idx in
                                                vm.toggleSet(
                                                    exerciseID: strength.id,
                                                    setIndex: idx,
                                                    totalSets: strength.sets.count
                                                )
                                            },
                                            isCompleted: vm.isExerciseCompleted(strength),
                                            activePopoverExerciseID: $activeMusclePopoverExerciseID
                                        )
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                vm.completeAllSets(exerciseID: strength.id, totalSets: strength.sets.count)
                                            } label: {
                                                Label("Complete", systemImage: "checkmark.circle.fill")
                                            }
                                            .tint(.green)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                vm.removeExercise(exerciseID: strength.id, exerciseName: strength.name)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                }
                            }
                        } header: {
                            CollapsibleSectionHeader(
                                section: section,
                                exerciseCount: exerciseCount(for: section),
                                isCollapsed: collapsedSections.contains(section.id),
                                onToggle: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if collapsedSections.contains(section.id) {
                                            collapsedSections.remove(section.id)
                                        } else {
                                            collapsedSections.insert(section.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .listStyle(.insetGrouped)
                // .navigationTitle("Today's Workout")
                .overlayPreferenceValue(MusclePopoverPreferenceKey.self) { preferences in
                    GeometryReader { proxy in
                        musclePopoverOverlay(preferences: preferences, proxy: proxy)
                    }
                }
                }
            } else if let e = vm.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .imageScale(.large)
                        .foregroundStyle(.orange)
                    Text("Unable to load workout")
                        .font(.headline)
                    Text(e)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .task { if vm.workout == nil { vm.load() } }
        .onChange(of: vm.workout?.id) { _, _ in
            activeMusclePopoverExerciseID = nil
            musclePopoverSize = .zero
        }
    }
}

private extension WorkoutListView {
    @ViewBuilder
    func musclePopoverOverlay(preferences: [MusclePopoverPreferenceData], proxy: GeometryProxy) -> some View {
        if let preference = preferences.first(where: { $0.exerciseID == activeMusclePopoverExerciseID }) ?? preferences.last {
            let rect = proxy[preference.anchor]
            let popoverHeight = musclePopoverSize.height > 0 ? musclePopoverSize.height : musclePopoverEstimatedHeight
            let popoverWidth = musclePopoverSize.width > 0 ? musclePopoverSize.width : musclePopoverEstimatedWidth
            let aboveSpace = rect.minY
            let belowSpace = proxy.size.height - rect.maxY
            let requiredSpace = popoverHeight + musclePopoverVerticalGap
            let shouldPlaceAbove: Bool = {
                if aboveSpace >= requiredSpace {
                    return true
                } else if belowSpace >= requiredSpace {
                    return false
                } else {
                    return aboveSpace >= belowSpace
                }
            }()

            let yOffset: CGFloat = {
                if shouldPlaceAbove {
                    let proposed = rect.minY - musclePopoverVerticalGap - popoverHeight
                    return max(proposed, musclePopoverVerticalGap)
                } else {
                    let proposed = rect.maxY + musclePopoverVerticalGap
                    let maxY = proxy.size.height - popoverHeight - musclePopoverVerticalGap
                    return min(proposed, maxY)
                }
            }()
            let minX = musclePopoverHorizontalPadding
            let maxX = max(minX, proxy.size.width - popoverWidth - musclePopoverHorizontalPadding)
            let xOffset = min(max(rect.minX, minX), maxX)

            MuscleGroupPopoverView(muscleNames: preference.muscleNames)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { popoverProxy in
                        Color.clear
                            .onAppear { updateMusclePopoverSize(popoverProxy.size) }
                            .onChange(of: popoverProxy.size) { _, newValue in
                                updateMusclePopoverSize(newValue)
                            }
                    }
                )
                .offset(x: xOffset, y: yOffset)
                .transition(.scale(scale: 0.96, anchor: .bottomLeading).combined(with: .opacity))
                .allowsHitTesting(false)
                .zIndex(100)
        } else {
            Color.clear.opacity(0)
        }
    }

    func updateMusclePopoverSize(_ newValue: CGSize) {
        guard musclePopoverSize != newValue else { return }
        DispatchQueue.main.async {
            musclePopoverSize = newValue
        }
    }

    func exerciseCount(for section: WorkoutSection) -> Int {
        switch section {
        case .warmup(let exercises), .cardio(let exercises), .cooldown(let exercises):
            return exercises.filter { !vm.removedExercises.contains($0.id) }.count
        case .main(let exercises):
            return exercises.filter { !vm.removedExercises.contains($0.id) }.count
        }
    }
}

// MARK: - Collapsible Section Header

private struct CollapsibleSectionHeader: View {
    let section: WorkoutSection
    let exerciseCount: Int
    let isCollapsed: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Text(section.title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct StrengthExerciseRow: View {
    let exercise: StrengthExercise
    let completedIndices: Set<Int>
    let onTapSet: (Int) -> Void
    let isCompleted: Bool

    @Binding var activePopoverExerciseID: StrengthExercise.ID?
    @State private var popoverDismissTask: Task<Void, Never>?

    private let popoverDisplayDuration: TimeInterval = 2.8

    private var popoverBinding: Binding<Bool> {
        Binding(
            get: { activePopoverExerciseID == exercise.id },
            set: { newValue in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    if newValue {
                        activePopoverExerciseID = exercise.id
                    } else if activePopoverExerciseID == exercise.id {
                        activePopoverExerciseID = nil
                    }
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if !exercise.muscleGroups.isEmpty {
                    MuscleGroupIndicator(
                        exerciseID: exercise.id,
                        muscleNames: exercise.muscleGroups,
                        isPresented: popoverBinding
                    )
                }

                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(isCompleted ? Color.secondary : Color.primary)
                    .strikethrough(isCompleted)
                Spacer()
            }

            Text(exercise.instructions)
                .font(.subheadline)
                .foregroundStyle(isCompleted ? Color.secondary : Color.primary)
                .strikethrough(isCompleted)

            HStack(spacing: 8) {
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { idx, set in
                    Button {
                        onTapSet(idx)
                    } label: {
                        Text("\(set.reps)")
                            .foregroundColor(completedIndices.contains(idx) ? .white : .primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(completedIndices.contains(idx) ? Color.green : Color.clear)
                            )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(completedIndices.contains(idx) ? Color.green : Color.secondary, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: completedIndices.contains(idx))
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
        .onChange(of: activePopoverExerciseID) { _, newValue in
            if newValue == exercise.id { schedulePopoverDismissal() }
            else { cancelPopoverDismissal() }
        }
        .onDisappear {
            cancelPopoverDismissal()
            if activePopoverExerciseID == exercise.id {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    activePopoverExerciseID = nil
                }
            }
        }
    }

}

private extension StrengthExerciseRow {
    func schedulePopoverDismissal() {
        cancelPopoverDismissal()

        popoverDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(popoverDisplayDuration))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                if activePopoverExerciseID == exercise.id {
                    activePopoverExerciseID = nil
                }
            }
        }
    }

    func cancelPopoverDismissal() {
        popoverDismissTask?.cancel()
        popoverDismissTask = nil
    }
}

private struct MuscleGroupIndicator: View {
    let exerciseID: StrengthExercise.ID
    let muscleNames: [String]
    @Binding var isPresented: Bool

    private let swatchSize: CGFloat = 14
    private let buttonPadding: CGFloat = 4

    private var accessibilityLabel: String {
        let joined = muscleNames.map { $0.capitalized }.joined(separator: ", ")
        return joined.isEmpty ? "Muscle group" : "Muscle group: \(joined)"
    }

    var body: some View {
        Button(action: togglePopover) {
            HStack(spacing: 4) {
                ForEach(Array(muscleNames.enumerated()), id: \.offset) { _, rawName in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MuscleGroupPalette.color(for: rawName))
                        .frame(width: swatchSize, height: swatchSize)
                }
            }
            .padding(buttonPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .anchorPreference(key: MusclePopoverPreferenceKey.self, value: .bounds) { anchor in
            isPresented ? [MusclePopoverPreferenceData(exerciseID: exerciseID, muscleNames: muscleNames, anchor: anchor)] : []
        }
    }

    private func togglePopover() {
        isPresented.toggle()
    }
}

private struct MusclePopoverPreferenceData {
    let exerciseID: StrengthExercise.ID
    let muscleNames: [String]
    let anchor: Anchor<CGRect>
}

private struct MusclePopoverPreferenceKey: PreferenceKey {
    static var defaultValue: [MusclePopoverPreferenceData] = []

    static func reduce(value: inout [MusclePopoverPreferenceData], nextValue: () -> [MusclePopoverPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

struct TimedExerciseRow: View {
    let exercise: TimedExercise
    let completed: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(completed ? Color.secondary : Color.primary)
                    .strikethrough(completed)
                Spacer()
            }

            Text(exercise.instructions)
                .font(.subheadline)
                .foregroundStyle(completed ? Color.secondary : Color.primary)
                .strikethrough(completed)

            Button(action: onToggle) {
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch")
                    Text(format(exercise.duration))
                        .monospacedDigit()
                }
                .foregroundColor(completed ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(completed ? Color.green : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(completed ? Color.green : Color.secondary, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: completed)
        }
        .padding(.vertical, 6)
        .animation(.easeInOut(duration: 0.2), value: completed)
    }

    private func format(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct CompletionOverlay: View {
    let text: String
    let cornerRadius: CGFloat

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.38, blue: 0.12),
                Color(red: 0.76, green: 0.95, blue: 0.09)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(gradient)
            .overlay {
                Text(text)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(.horizontal, 6)
            }
            .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
    }
}
