import SwiftUI
import Charts
import SwiftData

struct ProgressInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allFoodLogs: [FoodLogEntry]

    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetric: NutritionMetric = .calories
    @State private var showShareSheet = false
    @State private var selectedDay: Date?

    init() {
        // Query last 90 days of data
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        let predicate = #Predicate<FoodLogEntry> { entry in
            entry.day >= ninetyDaysAgo
        }
        _allFoodLogs = Query(filter: predicate, sort: \.day, order: .forward)
    }

    // MARK: - Computed Properties

    private var dailyAggregates: [DailyAggregate] {
        let grouped = Dictionary(grouping: allFoodLogs) { $0.day }

        return grouped.map { day, logs in
            DailyAggregate(
                date: day,
                calories: logs.reduce(0) { $0 + $1.calories },
                protein: logs.reduce(0.0) { $0 + $1.protein },
                carbs: logs.reduce(0.0) { $0 + $1.carbs },
                fat: logs.reduce(0.0) { $0 + $1.fat },
                fiber: logs.reduce(0.0) { $0 + $1.fiber },
                mealCount: logs.count
            )
        }
        .sorted { $0.date < $1.date }
    }

    private var filteredData: [DailyAggregate] {
        let cutoffDate = Calendar.current.date(byAdding: selectedTimeRange.calendarComponent,
                                               value: -selectedTimeRange.rawValue,
                                               to: Date()) ?? Date()
        return dailyAggregates.filter { $0.date >= cutoffDate }
    }

    private var currentPeriodStats: PeriodStats {
        calculateStats(for: filteredData)
    }

    private var previousPeriodStats: PeriodStats {
        let cutoffDate = Calendar.current.date(byAdding: selectedTimeRange.calendarComponent,
                                               value: -selectedTimeRange.rawValue * 2,
                                               to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: selectedTimeRange.calendarComponent,
                                            value: -selectedTimeRange.rawValue,
                                            to: Date()) ?? Date()

        let previousData = dailyAggregates.filter { $0.date >= cutoffDate && $0.date < endDate }
        return calculateStats(for: previousData)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Time Range Selector
                        timeRangeSelector

                        // Main Chart
                        mainChartCard

                        // Key Metrics Grid
                        keyMetricsGrid

                        // Macro Distribution
                        macroDistributionCard

                        // Trends & Insights
                        trendsCard

                        // Detailed Stats
                        detailedStatsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Progress & Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: 12) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTimeRange = range
                    }
                }) {
                    Text(range.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedTimeRange == range ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTimeRange == range ?
                                     LinearGradient(colors: [.orange, .orange.opacity(0.8)],
                                                  startPoint: .topLeading,
                                                  endPoint: .bottomTrailing) :
                                        LinearGradient(colors: [Color(.systemBackground)],
                                                     startPoint: .top,
                                                     endPoint: .bottom))
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Main Chart Card

    private var mainChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedMetric.displayName)
                        .font(.system(size: 20, weight: .bold))

                    HStack(spacing: 8) {
                        Text("\(currentPeriodStats.average(for: selectedMetric), specifier: "%.0f")")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.orange)

                        Text("avg/day")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Trend indicator
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: trendDirection.icon)
                            .font(.system(size: 14, weight: .bold))
                        Text("\(abs(trendPercentage), specifier: "%.1f")%")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(trendDirection.color)

                    Text("vs last period")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Metric Selector Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(NutritionMetric.allCases, id: \.self) { metric in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMetric = metric
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(metric.icon)
                                    .font(.system(size: 12))
                                Text(metric.shortName)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(selectedMetric == metric ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedMetric == metric ?
                                         metric.color : Color.gray.opacity(0.1))
                            )
                        }
                    }
                }
            }

            // Chart
            if filteredData.isEmpty {
                emptyChartPlaceholder
            } else {
                chart
                    .frame(height: 220)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
    }

    private var chart: some View {
        Chart {
            ForEach(filteredData) { data in
                LineMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value(selectedMetric.displayName, data.value(for: selectedMetric))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [selectedMetric.color, selectedMetric.color.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value(selectedMetric.displayName, data.value(for: selectedMetric))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [selectedMetric.color.opacity(0.3), selectedMetric.color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                if let selectedDay = selectedDay, Calendar.current.isDate(data.date, inSameDayAs: selectedDay) {
                    PointMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value(selectedMetric.displayName, data.value(for: selectedMetric))
                    )
                    .foregroundStyle(selectedMetric.color)
                    .symbolSize(100)
                }
            }

            // Goal line
            if selectedMetric == .calories {
                RuleMark(y: .value("Goal", DailyGoals.default.calories))
                    .foregroundStyle(Color.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                            .padding(4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: selectedTimeRange.xAxisStride)) { value in
                AxisGridLine()
                AxisTick()
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: selectedTimeRange.dateFormat)
                            .font(.system(size: 10))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.system(size: 10))
                    }
                }
            }
        }
        .chartXSelection(value: $selectedDay)
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.3))

            Text("No data for this period")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            Text("Start logging meals to see insights")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Key Metrics Grid

    private var keyMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(
                title: "Total Intake",
                value: "\(currentPeriodStats.totalCalories)",
                unit: "kcal",
                icon: "flame.fill",
                color: .orange,
                trend: calculateTrend(current: Double(currentPeriodStats.totalCalories),
                                    previous: Double(previousPeriodStats.totalCalories))
            )

            metricCard(
                title: "Avg Protein",
                value: String(format: "%.0f", currentPeriodStats.avgProtein),
                unit: "g/day",
                icon: "figure.strengthtraining.traditional",
                color: .red,
                trend: calculateTrend(current: currentPeriodStats.avgProtein,
                                    previous: previousPeriodStats.avgProtein)
            )

            metricCard(
                title: "Meals Logged",
                value: "\(currentPeriodStats.totalMeals)",
                unit: "items",
                icon: "fork.knife",
                color: .blue,
                trend: calculateTrend(current: Double(currentPeriodStats.totalMeals),
                                    previous: Double(previousPeriodStats.totalMeals))
            )

            metricCard(
                title: "Consistency",
                value: "\(currentPeriodStats.consistencyScore)",
                unit: "%",
                icon: "checkmark.circle.fill",
                color: .green,
                trend: nil
            )
        }
    }

    private func metricCard(title: String, value: String, unit: String,
                           icon: String, color: Color, trend: Double?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)

                Spacer()

                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(abs(trend), specifier: "%.0f")%")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(trend >= 0 ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill((trend >= 0 ? Color.green : Color.red).opacity(0.1))
                    )
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
        )
    }

    // MARK: - Macro Distribution Card

    private var macroDistributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macro Distribution")
                .font(.system(size: 18, weight: .bold))

            HStack(spacing: 20) {
                // Pie chart representation
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 140, height: 140)

                    // Macro segments
                    MacroPieChart(
                        protein: currentPeriodStats.avgProtein,
                        carbs: currentPeriodStats.avgCarbs,
                        fat: currentPeriodStats.avgFat
                    )
                    .frame(width: 140, height: 140)

                    // Center label
                    VStack(spacing: 2) {
                        Text("Macros")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("g/day")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }

                // Legend
                VStack(alignment: .leading, spacing: 12) {
                    macroLegendItem(
                        color: .red,
                        name: "Protein",
                        value: currentPeriodStats.avgProtein,
                        percentage: macroPercentage(.protein)
                    )

                    macroLegendItem(
                        color: .blue,
                        name: "Carbs",
                        value: currentPeriodStats.avgCarbs,
                        percentage: macroPercentage(.carbs)
                    )

                    macroLegendItem(
                        color: .yellow,
                        name: "Fat",
                        value: currentPeriodStats.avgFat,
                        percentage: macroPercentage(.fat)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
    }

    private func macroLegendItem(color: Color, name: String, value: Double, percentage: Double) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text("\(value, specifier: "%.0f")g")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("\(percentage, specifier: "%.0f")%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Trends Card

    private var trendsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends & Insights")
                .font(.system(size: 18, weight: .bold))

            VStack(spacing: 12) {
                if currentPeriodStats.avgCalories > Double(DailyGoals.default.calories) {
                    insightRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        title: "Above calorie goal",
                        description: "Averaging \(Int(currentPeriodStats.avgCalories - Double(DailyGoals.default.calories))) kcal over target"
                    )
                } else {
                    insightRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "Within calorie goal",
                        description: "Great job staying on track!"
                    )
                }

                if currentPeriodStats.avgProtein >= 100 {
                    insightRow(
                        icon: "bolt.fill",
                        color: .blue,
                        title: "Excellent protein intake",
                        description: "Averaging \(Int(currentPeriodStats.avgProtein))g per day"
                    )
                }

                if currentPeriodStats.consistencyScore >= 70 {
                    insightRow(
                        icon: "star.fill",
                        color: .yellow,
                        title: "Consistent logging",
                        description: "You've been tracking \(currentPeriodStats.consistencyScore)% of days"
                    )
                }

                let streakDays = calculateCurrentStreak()
                if streakDays >= 3 {
                    insightRow(
                        icon: "flame.fill",
                        color: .red,
                        title: "\(streakDays)-day streak",
                        description: "Keep it going!"
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
    }

    private func insightRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Detailed Stats Card

    private var detailedStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Statistics")
                .font(.system(size: 18, weight: .bold))

            VStack(spacing: 12) {
                statRow(label: "Highest day", value: "\(currentPeriodStats.maxCalories) kcal",
                       icon: "arrow.up.circle.fill", color: .orange)
                statRow(label: "Lowest day", value: "\(currentPeriodStats.minCalories) kcal",
                       icon: "arrow.down.circle.fill", color: .blue)
                statRow(label: "Average fiber", value: String(format: "%.1f g/day", currentPeriodStats.avgFiber),
                       icon: "leaf.fill", color: .green)
                statRow(label: "Most active day", value: mostActiveDay,
                       icon: "star.fill", color: .yellow)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
    }

    private func statRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Helper Methods

    private var trendDirection: (icon: String, color: Color) {
        let change = currentPeriodStats.average(for: selectedMetric) -
                    previousPeriodStats.average(for: selectedMetric)

        if change > 0 {
            return ("arrow.up.right", .green)
        } else if change < 0 {
            return ("arrow.down.right", .red)
        } else {
            return ("minus", .gray)
        }
    }

    private var trendPercentage: Double {
        let current = currentPeriodStats.average(for: selectedMetric)
        let previous = previousPeriodStats.average(for: selectedMetric)

        guard previous > 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }

    private func calculateTrend(current: Double, previous: Double) -> Double? {
        guard previous > 0 else { return nil }
        return ((current - previous) / previous) * 100
    }

    private func calculateStats(for data: [DailyAggregate]) -> PeriodStats {
        guard !data.isEmpty else {
            return PeriodStats(totalCalories: 0, avgCalories: 0, maxCalories: 0,
                             minCalories: 0, avgProtein: 0, avgCarbs: 0, avgFat: 0,
                             avgFiber: 0, totalMeals: 0, consistencyScore: 0)
        }

        let totalCalories = data.reduce(0) { $0 + $1.calories }
        let avgCalories = Double(totalCalories) / Double(data.count)
        let maxCalories = data.map { $0.calories }.max() ?? 0
        let minCalories = data.map { $0.calories }.min() ?? 0

        let avgProtein = data.reduce(0.0) { $0 + $1.protein } / Double(data.count)
        let avgCarbs = data.reduce(0.0) { $0 + $1.carbs } / Double(data.count)
        let avgFat = data.reduce(0.0) { $0 + $1.fat } / Double(data.count)
        let avgFiber = data.reduce(0.0) { $0 + $1.fiber } / Double(data.count)

        let totalMeals = data.reduce(0) { $0 + $1.mealCount }

        let daysInPeriod = selectedTimeRange.rawValue
        let consistencyScore = min(Int((Double(data.count) / Double(daysInPeriod)) * 100), 100)

        return PeriodStats(
            totalCalories: totalCalories,
            avgCalories: avgCalories,
            maxCalories: maxCalories,
            minCalories: minCalories,
            avgProtein: avgProtein,
            avgCarbs: avgCarbs,
            avgFat: avgFat,
            avgFiber: avgFiber,
            totalMeals: totalMeals,
            consistencyScore: consistencyScore
        )
    }

    private func macroPercentage(_ macro: MacroType) -> Double {
        let total = currentPeriodStats.avgProtein + currentPeriodStats.avgCarbs + currentPeriodStats.avgFat
        guard total > 0 else { return 0 }

        let value: Double
        switch macro {
        case .protein: value = currentPeriodStats.avgProtein
        case .carbs: value = currentPeriodStats.avgCarbs
        case .fat: value = currentPeriodStats.avgFat
        }

        return (value / total) * 100
    }

    private var mostActiveDay: String {
        guard let maxDay = filteredData.max(by: { $0.mealCount < $1.mealCount }) else {
            return "N/A"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: maxDay.date)
    }

    private func calculateCurrentStreak() -> Int {
        guard !dailyAggregates.isEmpty else { return 0 }

        let sortedDays = dailyAggregates.sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        for day in sortedDays {
            if Calendar.current.isDate(day.date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }

        return streak
    }
}

// MARK: - Supporting Types

enum TimeRange: Int, CaseIterable {
    case week = 7
    case twoWeeks = 14
    case month = 30

    var displayName: String {
        switch self {
        case .week: return "7D"
        case .twoWeeks: return "14D"
        case .month: return "30D"
        }
    }

    var calendarComponent: Calendar.Component {
        return .day
    }

    var xAxisStride: Calendar.Component {
        switch self {
        case .week: return .day
        case .twoWeeks: return .day
        case .month: return .weekOfYear
        }
    }

    var dateFormat: Date.FormatStyle {
        switch self {
        case .week, .twoWeeks: return .dateTime.month(.abbreviated).day()
        case .month: return .dateTime.month(.abbreviated).day()
        }
    }
}

enum NutritionMetric: CaseIterable {
    case calories, protein, carbs, fat, fiber

    var displayName: String {
        switch self {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fat: return "Fat"
        case .fiber: return "Fiber"
        }
    }

    var shortName: String {
        switch self {
        case .calories: return "Cal"
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fat: return "Fat"
        case .fiber: return "Fiber"
        }
    }

    var icon: String {
        switch self {
        case .calories: return "🔥"
        case .protein: return "🥩"
        case .carbs: return "🍞"
        case .fat: return "🥑"
        case .fiber: return "🌾"
        }
    }

    var color: Color {
        switch self {
        case .calories: return .orange
        case .protein: return .red
        case .carbs: return .blue
        case .fat: return .yellow
        case .fiber: return .green
        }
    }
}

enum MacroType {
    case protein, carbs, fat
}

struct DailyAggregate: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let mealCount: Int

    func value(for metric: NutritionMetric) -> Double {
        switch metric {
        case .calories: return Double(calories)
        case .protein: return protein
        case .carbs: return carbs
        case .fat: return fat
        case .fiber: return fiber
        }
    }
}

struct PeriodStats {
    let totalCalories: Int
    let avgCalories: Double
    let maxCalories: Int
    let minCalories: Int
    let avgProtein: Double
    let avgCarbs: Double
    let avgFat: Double
    let avgFiber: Double
    let totalMeals: Int
    let consistencyScore: Int

    func average(for metric: NutritionMetric) -> Double {
        switch metric {
        case .calories: return avgCalories
        case .protein: return avgProtein
        case .carbs: return avgCarbs
        case .fat: return avgFat
        case .fiber: return avgFiber
        }
    }
}

// MARK: - Macro Pie Chart

struct MacroPieChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double

    private var total: Double {
        protein + carbs + fat
    }

    private var proteinAngle: Angle {
        guard total > 0 else { return .degrees(0) }
        return .degrees((protein / total) * 360)
    }

    private var carbsAngle: Angle {
        guard total > 0 else { return .degrees(0) }
        return .degrees((carbs / total) * 360)
    }

    private var fatAngle: Angle {
        guard total > 0 else { return .degrees(0) }
        return .degrees((fat / total) * 360)
    }

    var body: some View {
        ZStack {
            // Protein segment
            Circle()
                .trim(from: 0, to: protein / total)
                .stroke(Color.red, lineWidth: 25)
                .rotationEffect(.degrees(-90))

            // Carbs segment
            Circle()
                .trim(from: 0, to: carbs / total)
                .stroke(Color.blue, lineWidth: 25)
                .rotationEffect(Angle(degrees: -90 + proteinAngle.degrees))

            // Fat segment
            Circle()
                .trim(from: 0, to: fat / total)
                .stroke(Color.yellow, lineWidth: 25)
                .rotationEffect(Angle(degrees: -90 + proteinAngle.degrees + carbsAngle.degrees))
        }
    }
}

// MARK: - Preview

#Preview {
    ProgressInsightsView()
        .modelContainer(for: [FoodLogEntry.self], inMemory: true)
}
