//
//  ScreenTimeMonitorExtension.swift
//  ScreenTimeMonitor
//
//  Created on 21.02.2026.
//

import DeviceActivity
import Foundation

/// DeviceActivityMonitor extension that fires when hourly usage thresholds are reached.
/// Writes the current threshold value to a shared App Group UserDefaults so the main app
/// can read it for stress scoring.
class ScreenTimeMonitorExtension: DeviceActivityMonitor {

    private let appGroupID = "group.com.hariom.health.WellPlate"
    private let thresholdKey = "screenTimeThresholdHours"
    private let thresholdDateKey = "screenTimeThresholdDate"

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }

    // MARK: - Interval Start (new day)

    override func intervalDidStart(for activity: DeviceActivityName) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(dayFormatter.string(from: Date()), forKey: thresholdDateKey)
        defaults.set(0.0, forKey: thresholdKey)
    }

    // MARK: - Threshold Reached

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        // Event names follow pattern: "threshold_Xh"
        let name = event.rawValue
        guard let suffix = name.split(separator: "_").last else { return }

        // Parse the hour value (remove trailing "h")
        let hourString = suffix.hasSuffix("h") ? String(suffix.dropLast()) : String(suffix)
        guard let hours = Double(hourString) else { return }

        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        let current = defaults.double(forKey: thresholdKey)
        if hours > current {
            defaults.set(hours, forKey: thresholdKey)
            defaults.set(dayFormatter.string(from: Date()), forKey: thresholdDateKey)
        }
    }

    // MARK: - Interval End

    override func intervalDidEnd(for activity: DeviceActivityName) {
        // Data stays in UserDefaults for the main app to read until next day reset
    }
}
