//
//  StressModels.swift
//  WellPlate
//
//  Created on 21.02.2026.
//

import SwiftUI

// MARK: - Stress Level

enum StressLevel: String, CaseIterable {
    case excellent = "Excellent"
    case good      = "Good"
    case moderate  = "Moderate"
    case high      = "High"
    case veryHigh  = "Very High"

    init(score: Double) {
        switch score {
        case ..<21:   self = .excellent
        case 21..<41: self = .good
        case 41..<61: self = .moderate
        case 61..<81: self = .high
        default:      self = .veryHigh
        }
    }

    var label: String { rawValue }

    var color: Color {
        switch self {
        case .excellent: return .teal
        case .good:      return .green
        case .moderate:  return .yellow
        case .high:      return .orange
        case .veryHigh:  return .red
        }
    }

    var encouragementText: String {
        switch self {
        case .excellent: return "You're doing great today!"
        case .good:      return "Keep up the good work!"
        case .moderate:  return "Not bad — room to improve."
        case .high:      return "Take a break, you deserve it."
        case .veryHigh:  return "Time to recharge — prioritize self-care."
        }
    }

    var systemImage: String {
        switch self {
        case .excellent: return "face.smiling.inverse"
        case .good:      return "face.smiling"
        case .moderate:  return "face.dashed"
        case .high:      return "exclamationmark.triangle"
        case .veryHigh:  return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Stress Factor Result

struct StressFactorResult: Identifiable {
    let id = UUID()
    let title: String
    let score: Double          // 0–25
    let maxScore: Double       // always 25
    let icon: String           // SF Symbol name
    let accentColor: Color
    let statusText: String     // e.g. "7,245 steps"
    let detailText: String     // e.g. "Above average today"

    var progress: Double { score / maxScore }

    /// Neutral factor when no data is available (defaults to 12.5).
    static func neutral(title: String, icon: String, accentColor: Color) -> StressFactorResult {
        StressFactorResult(
            title: title,
            score: 12.5,
            maxScore: 25,
            icon: icon,
            accentColor: accentColor,
            statusText: "No data",
            detailText: "Using neutral estimate"
        )
    }
}
