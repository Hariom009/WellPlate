//
//  StressView.swift
//  WellPlate
//
//  Created on 21.02.2026.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Sheet Enum

enum StressSheet: Identifiable {
    case exercise
    case sleep
    case diet
    case screenTimeDetail
    case screenTimeEntry
    case vital(VitalMetric)

    var id: String {
        switch self {
        case .exercise:         return "exercise"
        case .sleep:            return "sleep"
        case .diet:             return "diet"
        case .screenTimeDetail: return "screenTimeDetail"
        case .screenTimeEntry:  return "screenTimeEntry"
        case .vital(let m):     return "vital_\(m.id)"
        }
    }
}

// MARK: - StressView

struct StressView: View {

    @StateObject var viewModel: StressViewModel
    @ObservedObject private var screenTimeManager = ScreenTimeManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var activeSheet: StressSheet? = nil
    @State private var pendingManualHours: Double = 0
    private let refreshTicker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                Group {
                    if !HealthKitService.isAvailable {
                        unavailableView
                    } else if viewModel.isLoading {
                        loadingView
                    } else if !viewModel.isAuthorized {
                        permissionView
                    } else {
                        mainContent
                    }
                }
            }
            .navigationTitle("Stress")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await ScreenTimeManager.shared.requestAuthorization()
            ScreenTimeManager.shared.startMonitoring()
            await viewModel.requestPermissionAndLoad()
            viewModel.refreshScreenTimeOnly()
        }
        .onAppear {
            viewModel.refreshDietFactor()
            viewModel.refreshScreenTimeOnly()
        }
        .onReceive(refreshTicker) { _ in
            guard viewModel.isAuthorized else { return }
            viewModel.refreshScreenTimeOnly()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            viewModel.refreshScreenTimeOnly()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .exercise:
                ExerciseDetailView(
                    stepsSamples: viewModel.stepsHistory,
                    energySamples: viewModel.energyHistory
                )
            case .sleep:
                SleepDetailView(
                    summaries: viewModel.sleepHistory,
                    stats: viewModel.sleepStats
                )
            case .diet:
                DietDetailView(
                    factor: viewModel.dietFactor,
                    todayLogs: viewModel.currentDayLogs
                )
            case .screenTimeDetail:
                ScreenTimeDetailView(
                    factor: viewModel.screenTimeFactor,
                    source: viewModel.screenTimeSource
                )
            case .screenTimeEntry:
                ScreenTimeInputSheet(
                    hours: $pendingManualHours,
                    autoDetectedHours: ScreenTimeManager.shared.currentAutoDetectedReading.map { Double($0.displayRoundedHours) }
                ) {
                    viewModel.setManualScreenTime(pendingManualHours)
                }
            case .vital(let metric):
                VitalDetailView(
                    metric: metric,
                    samples: viewModel.vitalHistory(for: metric)
                )
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                gaugeCard
                screenTimeReportCard
                factorsSection
                vitalsSection
                insightsCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .refreshable {
            await viewModel.loadData()
            viewModel.refreshScreenTimeOnly()
        }
    }

    // MARK: - Gauge Card

    private var gaugeCard: some View {
        VStack(spacing: 12) {
            StressScoreGaugeView(
                score: viewModel.totalScore,
                level: viewModel.stressLevel
            )

            Text(viewModel.stressLevel.encouragementText)
                .font(.r(.subheadline, .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Updated just now")
                    .font(.r(.caption2, .regular))
            }
            .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - Screen Time Report Card

    private var screenTimeReportCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "iphone")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
                Text("Screen Time")
                    .font(.r(.headline, .semibold))
                Spacer()
                switch viewModel.screenTimeSource {
                case .auto:
                    Text("Live")
                        .font(.r(.caption2, .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.cyan))
                case .manual:
                    Text("Manual")
                        .font(.r(.caption2, .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.orange))
                case .none:
                    EmptyView()
                }
                Button {
                    activeSheet = .screenTimeDetail
                } label: {
                    Text("Details →")
                        .font(.r(.caption, .medium))
                        .foregroundColor(.cyan)
                }
            }

            // Main time display
            let factor = viewModel.screenTimeFactor
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                switch viewModel.screenTimeSource {
                case .auto:
                    if let reading = ScreenTimeManager.shared.currentAutoDetectedReading {
                        Text("\(reading.displayRoundedHours)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading, endPoint: .trailing
                            ))
                        Text("h today")
                            .font(.r(.subheadline, .medium))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 6)
                    }
                case .manual:
                    Button {
                        pendingManualHours = viewModel.currentManualHours
                        activeSheet = .screenTimeEntry
                    } label: {
                        Text(String(format: "%.1f", viewModel.currentManualHours))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading, endPoint: .trailing
                            ))
                    }
                    .buttonStyle(.plain)
                    Text("h today")
                        .font(.r(.subheadline, .medium))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 6)
                case .none:
                    Button {
                        pendingManualHours = 0
                        activeSheet = .screenTimeEntry
                    } label: {
                        HStack(spacing: 6) {
                            Text("< 15 min")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.cyan.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                    Text("today")
                        .font(.r(.subheadline, .medium))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
                Spacer()
                // Score badge
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", factor.score))
                        .font(.r(22, .bold))
                        .foregroundColor(factor.accentColor)
                    + Text(" /25")
                        .font(.r(.caption, .medium))
                        .foregroundColor(.secondary)
                    Text("stress pts")
                        .font(.r(.caption2, .regular))
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(factor.accentColor)
                        .frame(width: max(0, geo.size.width * factor.progress), height: 6)
                }
            }
            .frame(height: 6)

            // Detail label
            Text(factor.detailText)
                .font(.r(.caption, .regular))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - Factors Section

    private var factorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stress Factors")
                .font(.r(.headline, .semibold))
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StressFactorCardView(factor: viewModel.exerciseFactor, onTap: { activeSheet = .exercise })
                StressFactorCardView(factor: viewModel.sleepFactor,    onTap: { activeSheet = .sleep })
                StressFactorCardView(factor: viewModel.dietFactor,     onTap: { activeSheet = .diet })
                StressFactorCardView(factor: viewModel.screenTimeFactor, onTap: { activeSheet = .screenTimeDetail })
            }
        }
    }

    // MARK: - Vitals Section

    private var vitalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vitals")
                .font(.r(.headline, .semibold))
                .padding(.leading, 4)

            VStack(spacing: 10) {
                StressVitalCardView(
                    metric: .heartRate,
                    todayValue: viewModel.todayHeartRate,
                    onTap: { activeSheet = .vital(.heartRate) }
                )
                StressVitalCardView(
                    metric: .restingHeartRate,
                    todayValue: viewModel.todayRestingHR,
                    onTap: { activeSheet = .vital(.restingHeartRate) }
                )
                StressVitalCardView(
                    metric: .hrv,
                    todayValue: viewModel.todayHRV,
                    onTap: { activeSheet = .vital(.hrv) }
                )

                // Blood pressure: two half-width cards side by side
                HStack(spacing: 10) {
                    bpHalfCard(metric: .systolicBP, value: viewModel.todaySystolicBP)
                    bpHalfCard(metric: .diastolicBP, value: viewModel.todayDiastolicBP)
                }

                StressVitalCardView(
                    metric: .respiratoryRate,
                    todayValue: viewModel.todayRespiratoryRate,
                    onTap: { activeSheet = .vital(.respiratoryRate) }
                )
            }
        }
    }

    private func bpHalfCard(metric: VitalMetric, value: Double?) -> some View {
        Button {
            activeSheet = .vital(metric)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: metric.systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(metric.accentColor)
                    Text(metric == .systolicBP ? "Systolic" : "Diastolic")
                        .font(.r(.caption, .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.4))
                }

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    if let v = value {
                        Text(String(format: "%.0f", v))
                            .font(.r(22, .bold))
                            .foregroundColor(metric.accentColor)
                            .monospacedDigit()
                    } else {
                        Text("—")
                            .font(.r(22, .bold))
                            .foregroundColor(.secondary)
                    }
                    Text(metric.unit)
                        .font(.r(.caption2, .regular))
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .appShadow(radius: 10, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Insights Card

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("What's Affecting You?")
                    .font(.r(.headline, .semibold))
            }

            ForEach(viewModel.topStressors) { factor in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: factor.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(factor.accentColor)
                        .frame(width: 24, height: 24)
                        .background(factor.accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(factor.title)
                            .font(.r(.subheadline, .semibold))
                        Text(tipForFactor(factor))
                            .font(.r(.caption, .regular))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Text(String(format: "%.0f", factor.score))
                        .font(.r(.subheadline, .bold))
                        .foregroundColor(factor.accentColor)
                    +
                    Text("/25")
                        .font(.r(.caption, .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private func tipForFactor(_ factor: StressFactorResult) -> String {
        switch factor.title {
        case "Exercise":
            return factor.score < 10
                ? "A 20-minute walk can significantly reduce stress hormones."
                : "Keep moving — your activity level is helping!"
        case "Sleep":
            return factor.score < 10
                ? "Aim for 7–9 hours tonight. Avoid screens before bed."
                : "Your sleep is contributing to lower stress."
        case "Diet":
            return factor.score < 10
                ? "Try adding more protein and fiber to your meals today."
                : "Good nutritional balance today!"
        case "Screen Time":
            return factor.score > 15
                ? "Take a break from your phone — try reading or a short walk."
                : "Nice screen time management!"
        default:
            return ""
        }
    }

    // MARK: - State Views

    private var permissionView: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.teal.opacity(0.15), .cyan.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(colors: [.teal, .cyan], startPoint: .top, endPoint: .bottom)
                    )
            }

            VStack(spacing: 8) {
                Text("Stress Insights")
                    .font(.r(.title2, .bold))
                Text("Allow HealthKit access to track exercise, sleep, and more for your stress score.")
                    .font(.r(.subheadline, .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.requestPermissionAndLoad() }
            } label: {
                Text("Allow Access")
                    .font(.r(.headline, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [.teal, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(.teal)
            Text("Analyzing stress factors…")
                .font(.r(.subheadline, .medium))
                .foregroundColor(.secondary)
        }
    }

    private var unavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("HealthKit Unavailable")
                .font(.r(.headline, .semibold))
            Text("Stress tracking requires a device with HealthKit support.")
                .font(.r(.subheadline, .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Shared Styling

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(.systemBackground))
            .appShadow(radius: 15, y: 5)
    }
}

// MARK: - Preview

#Preview {
    StressView(
        viewModel: StressViewModel(
            modelContext: try! ModelContainer(for: FoodLogEntry.self).mainContext
        )
    )
}
