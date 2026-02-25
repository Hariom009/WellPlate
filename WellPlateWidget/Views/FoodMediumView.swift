import SwiftUI
import WidgetKit

// MARK: - Medium Widget  (~329 × 155 pt)
// Shows: calorie ring on the left, macro bars on the right

struct FoodMediumView: View {
    let data: WidgetFoodData

    var body: some View {
        Link(destination: URL(string: "wellplate://logFood")!) {
            HStack(spacing: 0) {

                // ── Left column: ring + label ──────────────────────────
                VStack(spacing: 6) {
                    Text("Today")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    CalorieRingView(data: data, ringWidth: 10)
                        .frame(width: 94, height: 94)
                        .scaleEffect(data.totalCalories == 0 ? 0.95 : 1.0)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.65),
                            value: data.totalCalories
                        )

                    // Quick-add hint
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("Add")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(width: 114)

                // Divider
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(width: 0.5)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)

                // ── Right column: macros ───────────────────────────────
                VStack(alignment: .leading, spacing: 9) {
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .wellPlateWidgetBackground {
            ZStack {
                Color(.systemBackground)
                LinearGradient(
                    colors: [Color.orange.opacity(0.05), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}
