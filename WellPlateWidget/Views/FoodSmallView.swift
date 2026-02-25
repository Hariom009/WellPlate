import SwiftUI
import WidgetKit

// MARK: - Small Widget  (~155 × 155 pt)
// Shows: calorie ring + "Add Food" deep-link tap

struct FoodSmallView: View {
    let data: WidgetFoodData

    private var fraction: Double {
        guard data.calorieGoal > 0 else { return 0 }
        return min(Double(data.totalCalories) / Double(data.calorieGoal), 1.0)
    }

    private var percentText: String {
        "\(Int(fraction * 100))%"
    }

    var body: some View {
        Link(destination: URL(string: "wellplate://logFood")!) {
            VStack(spacing: 0) {

                // Header row
                HStack(alignment: .firstTextBaseline) {
                    Text("Today")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "fork.knife")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                Spacer(minLength: 6)

                // Calorie ring
                CalorieRingView(data: data, ringWidth: 9)
                    .frame(width: 82, height: 82)
                    // Subtle "pop" when calorie count changes
                    .scaleEffect(data.totalCalories == 0 ? 0.96 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: data.totalCalories)

                Spacer(minLength: 6)

                // Calorie goal label
                Text("\(data.calorieGoal - data.totalCalories) cal left")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.default, value: data.totalCalories)

                Spacer(minLength: 8)

                // "Add Food" pill
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Add Food")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(Color.orange.opacity(0.12))
                )
            }
            .padding(14)
        }
        .wellPlateWidgetBackground {
            // Subtle warm tint behind the card
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
