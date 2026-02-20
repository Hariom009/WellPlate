# Progress Insights View - Feature Documentation

## Overview
A comprehensive analytics and visualization view for tracking nutrition intake progress with beautiful charts, trends, and insights.

## Location
- **File**: `WellPlate/Features + UI/Progress/Views/ProgressInsightsView.swift`
- **Access**: Tap the "Stats" button in the top navigation bar of HomeView

## Features

### 1. **Interactive Time Range Selector**
- **7 Days**: Weekly view for immediate feedback
- **14 Days**: Two-week view for short-term trends
- **30 Days**: Monthly view for long-term patterns

### 2. **Main Analytics Chart**
- **Multi-metric visualization**: Switch between Calories, Protein, Carbs, Fat, and Fiber
- **Interactive line chart**: Tap to select specific days
- **Gradient area fill**: Beautiful visual representation
- **Goal reference line**: Shows target for calories
- **Trend indicators**: See percentage change vs previous period
- **Smooth animations**: Catmull-Rom interpolation for natural curves

### 3. **Key Metrics Grid** (4 cards)
- **Total Intake**: Aggregate calories with trend indicator
- **Average Protein**: Daily protein consumption
- **Meals Logged**: Total items tracked
- **Consistency Score**: Percentage of days logged

### 4. **Macro Distribution**
- **Pie chart**: Visual breakdown of protein/carbs/fat
- **Legend with percentages**: Exact gram amounts and ratios
- **Color-coded segments**:
  - Red = Protein
  - Blue = Carbs
  - Yellow = Fat

### 5. **Trends & Insights** (Smart Analytics)
The view automatically generates personalized insights:
- ✅ **Within/Above calorie goal** alerts
- 💪 **Excellent protein intake** recognition (≥100g)
- ⭐ **Consistent logging** praise (≥70% days)
- 🔥 **Streak tracker** for consecutive logging days (≥3 days)

### 6. **Detailed Statistics**
- **Highest day**: Maximum calorie intake in period
- **Lowest day**: Minimum calorie intake in period
- **Average fiber**: Daily fiber consumption
- **Most active day**: Day with most meals logged

## Design Highlights

### Visual Design
- **Modern iOS aesthetic**: Follows iOS design guidelines
- **Smooth animations**: Spring animations with proper damping
- **Shadow depth**: Subtle shadows for card elevation
- **Color system**: Consistent with app's orange theme
- **Typography hierarchy**: Clear information architecture

### UX Features
- **Full-screen presentation**: Immersive analytics experience
- **Easy dismissal**: X button (top-left) or swipe down
- **Share capability**: Export/share button (top-right) ready for future implementation
- **Empty state**: Friendly placeholder when no data exists
- **Responsive layout**: Adapts to different screen sizes

### Performance
- **SwiftData Query**: Efficient 90-day data fetch
- **Lazy computation**: Stats calculated only when needed
- **Incremental rendering**: Smooth scrolling with proper lazy loading

## Technical Implementation

### Data Aggregation
```swift
- Query pulls last 90 days of FoodLogEntry records
- Groups entries by day for daily aggregates
- Filters based on selected time range
- Calculates period statistics (avg, max, min, total)
```

### Key Components

1. **DailyAggregate**: Represents one day's nutrition totals
2. **PeriodStats**: Statistical summary for selected time range
3. **TimeRange**: Enum for 7/14/30 day periods
4. **NutritionMetric**: Enum for different nutrition types
5. **MacroPieChart**: Custom SwiftUI pie chart component

### Charts Framework
Uses native **SwiftUI Charts** (iOS 16+):
- LineMark for trend lines
- AreaMark for gradient fill
- PointMark for selected day
- RuleMark for goal reference
- Custom axis formatting

## Integration

### In HomeView
Added a new "Stats" button in the navigation bar:
```swift
Button(action: {
    showProgressInsights = true
}) {
    HStack(spacing: 4) {
        Image(systemName: "chart.line.uptrend.xyaxis")
        Text("Stats")
    }
}
```

### Presentation
Uses `.fullScreenCover` for immersive experience:
```swift
.fullScreenCover(isPresented: $showProgressInsights) {
    ProgressInsightsView()
}
```

## Future Enhancements (Optional)

1. **Export/Share**:
   - Generate PDF reports
   - Share charts as images
   - Export data as CSV

2. **Additional Charts**:
   - Bar chart comparison view
   - Stacked bar for macro breakdown
   - Heatmap calendar view

3. **Advanced Analytics**:
   - Week-over-week comparisons
   - Goal achievement percentage
   - Nutrient correlation analysis
   - Meal timing patterns

4. **Customization**:
   - Custom date range picker
   - User-defined goals per metric
   - Favorite metrics pinning

5. **AI Insights**:
   - Pattern detection
   - Personalized recommendations
   - Achievement predictions

## Notes

- No navigation integration required (per request)
- Standalone view accessible via button
- Self-contained with all dependencies
- Works with existing SwiftData models
- No breaking changes to existing code

## Dependencies
- SwiftUI
- SwiftData
- Charts (iOS 16+)
- Existing models: FoodLogEntry, NutritionalInfo, DailyGoals

---

**Created**: February 19, 2026
**Version**: 1.0
**Status**: ✅ Production Ready
