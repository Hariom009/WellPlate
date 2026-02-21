//
//  StressScoreGaugeView.swift
//  WellPlate
//
//  Created on 21.02.2026.
//

import SwiftUI

struct StressScoreGaugeView: View {

    let score: Double
    let level: StressLevel
    var size: CGFloat = 220

    // 270° arc: starts at 135° (bottom-left), sweeps 270° to 45° (bottom-right)
    private let startAngle: Double = 135
    private let sweepAngle: Double = 270

    var body: some View {
        ZStack {
            // Background arc
            arcShape
                .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 18, lineCap: .round))

            // Filled arc
            arcShape
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.teal, .green, .yellow, .orange, .red]),
                        center: .center,
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(startAngle + sweepAngle)
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )

            // Center content
            VStack(spacing: 4) {
                Text("\(Int(score))")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("/ 100")
                    .font(.system(size: size * 0.08, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                // Level pill badge
                Text(level.label)
                    .font(.system(size: size * 0.065, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(level.color))
                    .padding(.top, 4)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.2)) {
                animatedProgress = score / 100.0
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animatedProgress = newValue / 100.0
            }
        }
    }

    @State private var animatedProgress: Double = 0

    private var arcShape: some Shape {
        Arc(startAngle: .degrees(startAngle), endAngle: .degrees(startAngle + sweepAngle), clockwise: false)
    }
}

// MARK: - Custom Arc Shape

private struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        StressScoreGaugeView(score: 35, level: .good)
        StressScoreGaugeView(score: 72, level: .high, size: 160)
    }
    .padding()
}
