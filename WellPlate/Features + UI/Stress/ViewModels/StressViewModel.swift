//
//  StressViewModel.swift
//  WellPlate
//
//  Created on 21.02.2026.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Screen Time Source

enum ScreenTimeSource {
    case auto        // from DeviceActivity report / threshold resolver
    case none        // no data for today
}

@MainActor
final class StressViewModel: ObservableObject {

    // MARK: - Published State

    @Published var exerciseFactor: StressFactorResult  = .neutral(title: "Exercise",    icon: "figure.run",  accentColor: .orange)
    @Published var sleepFactor: StressFactorResult      = .neutral(title: "Sleep",       icon: "moon.fill",   accentColor: .indigo)
    @Published var dietFactor: StressFactorResult       = .neutral(title: "Diet",        icon: "leaf.fill",   accentColor: .green)
    @Published var screenTimeFactor: StressFactorResult = .neutral(title: "Screen Time", icon: "iphone",      accentColor: .cyan)
    @Published var isLoading = false
    @Published var isAuthorized = false
    @Published var errorMessage: String? = nil
    @Published var screenTimeSource: ScreenTimeSource = .none

    // MARK: - Computed

    var totalScore: Double {
        exerciseFactor.score + sleepFactor.score + dietFactor.score + screenTimeFactor.score
    }

    var stressLevel: StressLevel { StressLevel(score: totalScore) }

    var allFactors: [StressFactorResult] {
        [exerciseFactor, sleepFactor, dietFactor, screenTimeFactor]
    }

    /// Top 2 factors contributing most to stress (highest score = most stressful).
    var topStressors: [StressFactorResult] {
        allFactors.sorted { $0.score > $1.score }.prefix(2).map { $0 }
    }

    // MARK: - Dependencies

    private let healthService: HealthKitServiceProtocol
    private let modelContext: ModelContext

    // MARK: - Init

    init(healthService: HealthKitServiceProtocol = HealthKitService(), modelContext: ModelContext) {
        self.healthService = healthService
        self.modelContext = modelContext

        if ScreenTimeManager.shared.currentAutoDetectedReading != nil {
            self.screenTimeSource = .auto
        }
    }

    // MARK: - Actions

    func requestPermissionAndLoad() async {
        guard HealthKitService.isAvailable else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await healthService.requestAuthorization()
            isAuthorized = healthService.isAuthorized
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadData() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let now = Date()
        let todayInterval = DateInterval(start: startOfDay, end: now)

        // Sleep: look back 1 day to capture last night
        let sleepStart = calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay
        let sleepInterval = DateInterval(start: sleepStart, end: now)

        // Fetch exercise + sleep in parallel
        async let stepsResult = fetchStepsSafely(for: todayInterval)
        async let energyResult = fetchEnergySafely(for: todayInterval)
        async let sleepResult = fetchSleepSafely(for: sleepInterval)

        let steps = await stepsResult
        let energy = await energyResult
        let sleepSummary = await sleepResult

        // Compute exercise factor
        let exerciseScore = computeExerciseScore(steps: steps, energy: energy)
        exerciseFactor = buildExerciseFactor(score: exerciseScore, steps: steps, energy: energy)

        // Compute sleep factor
        let sleepScore = computeSleepScore(summary: sleepSummary)
        sleepFactor = buildSleepFactor(score: sleepScore, summary: sleepSummary)

        // Refresh diet synchronously from SwiftData
        refreshDietFactor()

        // Refresh screen time from persisted value
        refreshScreenTimeFactor()
    }

    func refreshDietFactor() {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<FoodLogEntry>(
            predicate: #Predicate<FoodLogEntry> { entry in
                entry.day == today
            }
        )
        let logs = (try? modelContext.fetch(descriptor)) ?? []
        let score = computeDietScore(logs: logs)
        dietFactor = buildDietFactor(score: score, logs: logs)
    }

    func refreshScreenTimeOnly() {
        refreshScreenTimeFactor()
    }

    // MARK: - Private: Safe Fetchers (return nil on error)

    private func fetchStepsSafely(for range: DateInterval) async -> Double? {
        try? await healthService.fetchSteps(for: range).first?.value
    }

    private func fetchEnergySafely(for range: DateInterval) async -> Double? {
        try? await healthService.fetchActiveEnergy(for: range).first?.value
    }

    private func fetchSleepSafely(for range: DateInterval) async -> DailySleepSummary? {
        try? await healthService.fetchDailySleepSummaries(for: range).last
    }

    // MARK: - Score Engines

    private func computeExerciseScore(steps: Double?, energy: Double?) -> Double {
        guard steps != nil || energy != nil else { return 12.5 }

        var scores: [Double] = []

        if let s = steps {
            scores.append(25.0 * (1.0 - clamp(s / 10_000.0)))
        }
        if let e = energy {
            scores.append(25.0 * (1.0 - clamp(e / 600.0)))
        }

        return scores.reduce(0, +) / Double(scores.count)
    }

    private func computeSleepScore(summary: DailySleepSummary?) -> Double {
        guard let s = summary else { return 12.5 }
        let h = s.totalHours

        // Base score from total hours (0–20 pts)
        let baseScore: Double
        switch h {
        case ..<4:     baseScore = 20
        case 4..<5:    baseScore = lerp(from: 20, to: 18, t: (h - 4) / 1)
        case 5..<6:    baseScore = lerp(from: 18, to: 12, t: (h - 5) / 1)
        case 6..<7:    baseScore = lerp(from: 12, to: 5,  t: (h - 6) / 1)
        case 7..<9:    baseScore = lerp(from: 5,  to: 0,  t: (h - 7) / 2)
        case 9..<10:   baseScore = lerp(from: 0,  to: 4,  t: (h - 9) / 1)
        default:       baseScore = 6
        }

        // Deep sleep penalty (0–5 pts)
        let deepPenalty: Double
        if h > 0 {
            let deepRatio = s.deepHours / h
            deepPenalty = clamp((0.18 - deepRatio) / 0.18) * 5
        } else {
            deepPenalty = 2.5 // neutral
        }

        return min(25, baseScore + deepPenalty)
    }

    private func computeDietScore(logs: [FoodLogEntry]) -> Double {
        guard !logs.isEmpty else { return 12.5 }

        let totalProtein = logs.map(\.protein).reduce(0, +)
        let totalFiber   = logs.map(\.fiber).reduce(0, +)
        let totalFat     = logs.map(\.fat).reduce(0, +)
        let totalCarbs   = logs.map(\.carbs).reduce(0, +)

        let proteinRatio = clamp(totalProtein / 60.0)
        let fiberRatio   = clamp(totalFiber / 25.0)
        let balancedScore = proteinRatio * 0.55 + fiberRatio * 0.45

        let fatRatio  = clamp(totalFat / 65.0)
        let carbRatio = clamp(totalCarbs / 225.0)
        let excessScore = fatRatio * 0.45 + carbRatio * 0.55

        let netBalance = clamp((balancedScore - excessScore * 0.6 + 0.5) / 1.0)

        return 25.0 * (1.0 - netBalance)
    }

    private func computeScreenTimeScore(hours: Double?) -> Double {
        guard let h = hours else { return 0 }
        // 2 points per hour, capped at 25
        return min(25, h * 2.0)
    }

    // MARK: - Factor Builders

    private func buildExerciseFactor(score: Double, steps: Double?, energy: Double?) -> StressFactorResult {
        let stepsStr = steps.map { NumberFormatter.localizedString(from: NSNumber(value: Int($0)), number: .decimal) } ?? "—"
        let energyStr = energy.map { "\(Int($0)) kcal" } ?? "—"

        let status: String
        if steps != nil && energy != nil {
            status = "\(stepsStr) steps · \(energyStr)"
        } else if let _ = steps {
            status = "\(stepsStr) steps"
        } else if let _ = energy {
            status = energyStr
        } else {
            status = "No data"
        }

        let detail: String
        if score < 8 { detail = "Great activity level!" }
        else if score < 16 { detail = "Moderate activity today" }
        else { detail = "Try to move more today" }

        return StressFactorResult(title: "Exercise", score: score, maxScore: 25, icon: "figure.run",
                                  accentColor: .orange, statusText: status, detailText: detail)
    }

    private func buildSleepFactor(score: Double, summary: DailySleepSummary?) -> StressFactorResult {
        let status: String
        if let s = summary {
            status = String(format: "%.1fh total · %.1fh deep", s.totalHours, s.deepHours)
        } else {
            status = "No data"
        }

        let detail: String
        if score < 8 { detail = "Well rested!" }
        else if score < 16 { detail = "Decent sleep" }
        else { detail = "Try to sleep more tonight" }

        return StressFactorResult(title: "Sleep", score: score, maxScore: 25, icon: "moon.fill",
                                  accentColor: .indigo, statusText: status, detailText: detail)
    }

    private func buildDietFactor(score: Double, logs: [FoodLogEntry]) -> StressFactorResult {
        let status: String
        if logs.isEmpty {
            status = "No food logged"
        } else {
            let protein = Int(logs.map(\.protein).reduce(0, +))
            let fiber   = Int(logs.map(\.fiber).reduce(0, +))
            status = "\(protein)g protein · \(fiber)g fiber"
        }

        let detail: String
        if logs.isEmpty { detail = "Log meals for an accurate score" }
        else if score < 8 { detail = "Balanced diet today!" }
        else if score < 16 { detail = "Fair nutritional balance" }
        else { detail = "Consider healthier choices" }

        return StressFactorResult(title: "Diet", score: score, maxScore: 25, icon: "leaf.fill",
                                  accentColor: .green, statusText: status, detailText: detail)
    }

    private func refreshScreenTimeFactor() {
        let reading = ScreenTimeManager.shared.currentAutoDetectedReading
        let scoreHours = reading?.rawHours

        screenTimeSource = reading != nil ? .auto : .none

        let score = computeScreenTimeScore(hours: scoreHours)
        #if DEBUG
        let hoursLog = scoreHours.map { String(format: "%.3f", $0) } ?? "nil"
        print("[StressViewModel] screenTime hours=\(hoursLog) score=\(String(format: "%.2f", score))")
        #endif

        let status: String
        let detail: String
        if let reading {
            status = "\(reading.displayRoundedHours)h detected (±15m)"
            if score < 8 { detail = "Low screen time 👍" }
            else if score < 16 { detail = "Moderate screen usage" }
            else { detail = "Consider reducing screen time" }
        } else {
            status = "Under 4h today"
            detail = "Score adds 2pts per hour above 4h"
        }

        screenTimeFactor = StressFactorResult(title: "Screen Time", score: score, maxScore: 25, icon: "iphone",
                                              accentColor: .cyan, statusText: status, detailText: detail)
    }

    // MARK: - Helpers

    private func clamp(_ value: Double, min lo: Double = 0, max hi: Double = 1) -> Double {
        Swift.min(hi, Swift.max(lo, value))
    }

    private func lerp(from a: Double, to b: Double, t: Double) -> Double {
        a + (b - a) * clamp(t)
    }
}
