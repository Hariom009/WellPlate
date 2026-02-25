import SwiftUI

extension View {
    @ViewBuilder
    func wellPlateWidgetBackground<Background: View>(
        @ViewBuilder _ background: () -> Background
    ) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                background()
            }
        } else {
            self.background(background())
        }
    }
}

// MARK: - Calorie Ring

struct CalorieRingView: View {
    let data: WidgetFoodData
    var ringWidth: CGFloat = 10

    private var fraction: Double {
        guard data.calorieGoal > 0 else { return 0 }
        return min(Double(data.totalCalories) / Double(data.calorieGoal), 1.0)
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.orange.opacity(0.18), lineWidth: ringWidth)

            // Fill — animates between timeline entries
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(
                        colors: [.orange, .pink],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle:   .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    .spring(response: 0.65, dampingFraction: 0.78),
                    value: fraction
                )

            // Labels
            VStack(spacing: 1) {
                Text("\(data.totalCalories)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.default, value: data.totalCalories)
                Text("cal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Macro Progress Row

struct MacroBarRow: View {
    let label:  String
    let value:  Double
    let goal:   Double
    let color:  Color
    let unit:   String

    private var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value))/\(Int(goal))\(unit)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.2))
                        .frame(height: 5)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(geo.size.width * fraction, 0), height: 5)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.72),
                            value: fraction
                        )
                }
            }
            .frame(height: 5)
        }
    }
}
