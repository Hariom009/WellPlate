//
//  VitalMetric.swift
//  WellPlate
//
//  Created on 25.02.2026.
//

import SwiftUI

enum VitalMetric: String, CaseIterable, Identifiable {
    case heartRate       = "Heart Rate"
    case restingHeartRate = "Resting Heart Rate"
    case hrv             = "Heart Rate Variability"
    case systolicBP      = "Systolic BP"
    case diastolicBP     = "Diastolic BP"
    case respiratoryRate = "Respiratory Rate"

    var id: String { rawValue }

    var unit: String {
        switch self {
        case .heartRate, .restingHeartRate: return "BPM"
        case .hrv:                          return "ms"
        case .systolicBP, .diastolicBP:     return "mmHg"
        case .respiratoryRate:              return "brpm"
        }
    }

    var systemImage: String {
        switch self {
        case .heartRate:        return "heart.fill"
        case .restingHeartRate: return "heart.circle.fill"
        case .hrv:              return "waveform.path.ecg"
        case .systolicBP:       return "arrow.up.heart.fill"
        case .diastolicBP:      return "arrow.down.heart.fill"
        case .respiratoryRate:  return "lungs.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .heartRate:        return .red
        case .restingHeartRate: return .pink
        case .hrv:              return .teal
        case .systolicBP:       return .orange
        case .diastolicBP:      return .yellow
        case .respiratoryRate:  return .cyan
        }
    }

    var normalRange: String {
        switch self {
        case .heartRate:        return "60–100 BPM at rest"
        case .restingHeartRate: return "60–100 BPM (athletes: 40–60)"
        case .hrv:              return "20–70 ms (higher = better recovery)"
        case .systolicBP:       return "< 120 mmHg (normal)"
        case .diastolicBP:      return "< 80 mmHg (normal)"
        case .respiratoryRate:  return "12–20 breaths per minute"
        }
    }

    var higherIsBetter: Bool {
        switch self {
        case .hrv:              return true
        case .heartRate, .restingHeartRate: return false
        case .systolicBP, .diastolicBP:     return false
        case .respiratoryRate:  return false
        }
    }
}
