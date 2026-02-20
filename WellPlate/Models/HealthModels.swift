//
//  HealthModels.swift
//  WellPlate
//
//  Created by Hari's Mac on 20.02.2026.
//

import SwiftUI

// MARK: - Data Structures

struct DailyMetricSample: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct SleepSample: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double   // hours
}

// MARK: - Burn Metrics

enum BurnMetric: String, CaseIterable, Identifiable {
    case activeEnergy = "Active Energy"
    case steps        = "Steps"

    var id: String { rawValue }

    var unit: String {
        switch self {
        case .activeEnergy: return "kcal"
        case .steps:        return "steps"
        }
    }

    var systemImage: String {
        switch self {
        case .activeEnergy: return "flame.fill"
        case .steps:        return "figure.walk"
        }
    }

    var accentColor: Color {
        switch self {
        case .activeEnergy: return .orange
        case .steps:        return .green
        }
    }
}
