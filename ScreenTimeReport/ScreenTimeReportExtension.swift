//
//  ScreenTimeReportExtension.swift
//  ScreenTimeReport
//
//  Created on 21.02.2026.
//

import DeviceActivity
import SwiftUI

@main
struct ScreenTimeReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { activityReport in
            TotalActivityView(report: activityReport)
        }
    }
}

// MARK: - Report Scene

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "TotalActivity")
    let content: (ActivityReport) -> TotalActivityView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> ActivityReport {
        var totalDuration: TimeInterval = 0
        var appCount = 0

        for await d in data {
            for await segment in d.activitySegments {
                totalDuration += segment.totalActivityDuration
                for await category in segment.categories {
                    for await _ in category.applications {
                        appCount += 1
                    }
                }
            }
        }

        return ActivityReport(
            totalDuration: totalDuration,
            appCount: appCount
        )
    }
}

// MARK: - Activity Report Model

struct ActivityReport {
    let totalDuration: TimeInterval
    let appCount: Int

    var hours: Double { totalDuration / 3600.0 }

    var formattedDuration: String {
        let h = Int(totalDuration) / 3600
        let m = (Int(totalDuration) % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        } else {
            return "\(m)m"
        }
    }
}
