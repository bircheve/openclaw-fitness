import SwiftUI

struct NutritionView: View {
    @ObservedObject var viewModel: NutritionViewModel

    @State private var expandedMealId: String?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading nutrition...")
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") { viewModel.load() }
                        .buttonStyle(.bordered)
                }
            } else if viewModel.plan != nil {
                nutritionContent
            }
        }
        .task {
            if viewModel.plan == nil { viewModel.load() }
        }
    }

    private var nutritionContent: some View {
        VStack(spacing: 0) {
            // Phase picker
            Picker("Phase", selection: $viewModel.selectedPhase) {
                ForEach(Array((viewModel.plan?.phases ?? []).enumerated()), id: \.offset) { idx, phase in
                    Text(phase.name).tag(idx)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            // Day picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.dayNames.enumerated()), id: \.offset) { idx, name in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedDay = idx
                            }
                        } label: {
                            Text(name)
                                .font(.subheadline.weight(viewModel.selectedDay == idx ? .bold : .regular))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.selectedDay == idx
                                        ? Color.accentColor.opacity(0.2)
                                        : Color(.systemGray5)
                                )
                                .clipShape(Capsule())
                                .foregroundStyle(viewModel.selectedDay == idx ? .primary : .secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }

            // Macro summary bar
            if let day = viewModel.currentDay {
                macroBar(targets: day.targets)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            // Meals list
            List {
                ForEach(viewModel.mealsBySlot, id: \.slot) { slot, meals in
                    Section {
                        ForEach(meals) { meal in
                            mealRow(meal)
                        }
                    } header: {
                        Text(slotDisplayName(slot))
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func macroBar(targets: MacroTargets) -> some View {
        HStack(spacing: 16) {
            macroChip(label: "Cal", value: "\(targets.calories)", color: .orange)
            macroChip(label: "P", value: "\(targets.protein)g", color: .blue)
            macroChip(label: "C", value: "\(targets.carbs)g", color: .green)
            macroChip(label: "F", value: "\(targets.fat)g", color: .red)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func macroChip(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func mealRow(_ meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.name)
                        .font(.subheadline.weight(.medium))
                    Text("\(meal.macros.calories) cal  \(meal.macros.protein)g P  \(meal.macros.carbs)g C  \(meal.macros.fat)g F")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: expandedMealId == meal.id ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedMealId = expandedMealId == meal.id ? nil : meal.id
                }
            }

            if expandedMealId == meal.id {
                VStack(alignment: .leading, spacing: 8) {
                    if !meal.ingredients.isEmpty {
                        Text("Ingredients")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(meal.ingredients, id: \.self) { ingredient in
                            Text("  \(ingredient)")
                                .font(.caption)
                        }
                    }
                    if !meal.directions.isEmpty {
                        Text("Directions")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(Array(meal.directions.enumerated()), id: \.offset) { idx, step in
                            Text("\(idx + 1). \(step)")
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }

    private func slotDisplayName(_ slot: String) -> String {
        switch slot {
        case "breakfast": return "Breakfast"
        case "snack_1": return "Snack"
        case "lunch": return "Lunch"
        case "snack_2": return "Snack"
        case "dinner": return "Dinner"
        case "snack_3": return "Snack"
        default: return slot.capitalized
        }
    }
}
