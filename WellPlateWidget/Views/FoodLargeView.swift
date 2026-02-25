import SwiftUI
import WidgetKit

// MARK: - Large Widget  (~329 × 345 pt)
// Shows: calorie headline + progress bar, macros, recent foods, add-food CTA

struct FoodLargeView: View {
    let data: WidgetFoodData

    private var calorieFraction: Double {
        guard data.calorieGoal > 0 else { return 0 }
        return min(Double(data.totalCalories) / Double(data.calorieGoal), 1.0)
    }

    var body: some View {
        Link(destination: URL(string: "wellplate://logFood")!) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Header ────────────────────────────────────────────
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        Text("Nutrition")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Text(Date(), style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 14)

                // ── Calorie headline ──────────────────────────────────
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(data.totalCalories)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.default, value: data.totalCalories)

                    Text("/ \(data.calorieGoal) cal")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 3)
                }

                // Calorie progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.orange.opacity(0.15))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(geo.size.width * calorieFraction, 0),
                                height: 8
                            )
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.78),
                                value: calorieFraction
                            )
                    }
                }
                .frame(height: 8)
                .padding(.top, 6)
                .padding(.bottom, 14)

                Divider()
                    .padding(.bottom, 12)

                // ── Macros ────────────────────────────────────────────
                VStack(spacing: 9) {
                    MacroBarRow(
                        label: "Protein",
                        value: data.totalProtein,
                        goal:  data.proteinGoal,
                        color: .green,
                        unit:  "g"
                    )
                    MacroBarRow(
                        label: "Carbs",
                        value: data.totalCarbs,
                        goal:  data.carbsGoal,
                        color: .blue,
                        unit:  "g"
                    )
                    MacroBarRow(
                        label: "Fat",
                        value: data.totalFat,
                        goal:  data.fatGoal,
                        color: Color(.systemOrange),
                        unit:  "g"
                    )
                }

                // ── Recent Foods ──────────────────────────────────────
                if !data.recentFoods.isEmpty {
                    Divider()
                        .padding(.vertical, 12)

                    Text("Recent")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 6)

                    VStack(spacing: 5) {
                        ForEach(data.recentFoods.prefix(3)) { food in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.orange.opacity(0.35))
                                    .frame(width: 6, height: 6)
                                Text(food.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(food.calories) cal")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: data.recentFoods.count)
                }

                Spacer(minLength: 10)

                // ── Add Food CTA ──────────────────────────────────────
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Food")
                        .fontWeight(.semibold)
                }
                .font(.callout)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .pink.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(16)
        }
        .wellPlateWidgetBackground {
            ZStack {
                Color(.systemBackground)
                LinearGradient(
                    colors: [Color.orange.opacity(0.06), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}
