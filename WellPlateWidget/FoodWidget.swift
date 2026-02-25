import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct FoodEntry: TimelineEntry {
    let date: Date
    let data: WidgetFoodData
}

// MARK: - Timeline Provider

struct FoodWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> FoodEntry {
        FoodEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (FoodEntry) -> Void) {
        let data = context.isPreview ? .placeholder : WidgetFoodData.load()
        completion(FoodEntry(date: .now, data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FoodEntry>) -> Void) {
        let entry     = FoodEntry(date: .now, data: WidgetFoodData.load())
        // Refresh every 30 minutes or when the app explicitly reloads via WidgetCenter
        let nextFetch = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        let timeline  = Timeline(entries: [entry], policy: .after(nextFetch))
        completion(timeline)
    }
}

// MARK: - Widget Entry View

struct FoodWidgetEntryView: View {
    let entry: FoodEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            FoodSmallView(data: entry.data)
        case .systemMedium:
            FoodMediumView(data: entry.data)
        case .systemLarge:
            FoodLargeView(data: entry.data)
        default:
            FoodSmallView(data: entry.data)
        }
    }
}

// MARK: - Widget Declaration

struct FoodWidget: Widget {
    let kind = "com.hariom.wellplate.foodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FoodWidgetProvider()) { entry in
            FoodWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Food Log")
        .description("Track your daily nutrition and log food quickly.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#if DEBUG
struct FoodWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FoodWidgetEntryView(entry: FoodEntry(date: .now, data: .placeholder))
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            FoodWidgetEntryView(entry: FoodEntry(date: .now, data: .placeholder))
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            FoodWidgetEntryView(entry: FoodEntry(date: .now, data: .placeholder))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
#endif
