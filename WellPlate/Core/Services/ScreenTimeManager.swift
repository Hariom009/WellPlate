//
//  ScreenTimeManager.swift
//  WellPlate
//
//  Created on 21.02.2026.
//

import Foundation
import Combine

#if canImport(FamilyControls)
import FamilyControls
import DeviceActivity

@MainActor
final class ScreenTimeManager: ObservableObject {

    // MARK: - Constants

    static let shared = ScreenTimeManager()
    static let appGroupID = "group.com.hariom.health.WellPlate"
    static let thresholdKey = "screenTimeThresholdHours"
    static let thresholdDateKey = "screenTimeThresholdDate"

    // MARK: - Published State

    @Published var isAuthorized = false
    @Published var authorizationError: String?

    // MARK: - Private

    private let center = DeviceActivityCenter()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Init

    private init() {
        // Check if already authorized
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            authorizationError = nil
        } catch {
            isAuthorized = false
            authorizationError = error.localizedDescription
        }
    }

    // MARK: - Monitoring

    /// Schedule daily monitoring with hourly thresholds (1h–12h).
    func startMonitoring() {
        guard isAuthorized else { return }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for hour in 1...12 {
            let name = DeviceActivityEvent.Name("threshold_\(hour)h")
            events[name] = DeviceActivityEvent(
                threshold: DateComponents(hour: hour)
            )
        }

        do {
            try center.startMonitoring(
                .init("daily_screen_time"),
                during: schedule,
                events: events
            )
        } catch {
            print("[ScreenTimeManager] Failed to start monitoring: \(error)")
        }
    }

    func stopMonitoring() {
        center.stopMonitoring([.init("daily_screen_time")])
    }

    // MARK: - Read Shared Data

    /// Read the latest threshold hours from App Group UserDefaults (written by the monitor extension).
    /// Returns `nil` if no data for today or no App Group access.
    var currentAutoDetectedHours: Double? {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else { return nil }
        let storedDate = defaults.string(forKey: Self.thresholdDateKey) ?? ""
        let today = Self.dayFormatter.string(from: Date())
        guard storedDate == today else { return nil }
        guard defaults.object(forKey: Self.thresholdKey) != nil else { return nil }
        let hours = defaults.double(forKey: Self.thresholdKey)
        return hours
    }

    // MARK: - Helpers

    static func todayDateString() -> String {
        dayFormatter.string(from: Date())
    }
}

#else

// MARK: - Stub for Simulator / platforms without FamilyControls

@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    static let appGroupID = "group.com.hariom.health.WellPlate"

    @Published var isAuthorized = false
    @Published var authorizationError: String? = "FamilyControls not available"

    private init() {}

    func requestAuthorization() async { /* no-op */ }
    func startMonitoring() { /* no-op */ }
    func stopMonitoring() { /* no-op */ }

    var currentAutoDetectedHours: Double? { nil }

    static func todayDateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }
}
#endif
