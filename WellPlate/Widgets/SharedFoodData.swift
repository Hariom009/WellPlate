import Foundation

// Shared data container written by the main app, read by the widget extension.
// Uses AppGroup UserDefaults — pure Foundation, no SwiftData dependency.
struct WidgetFoodData: Codable {
    var totalCalories: Int
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var recentFoods: [WidgetFoodItem]
    var calorieGoal: Int
    var proteinGoal: Double
    var carbsGoal: Double
    var fatGoal: Double
    var lastUpdated: Date

    static let appGroupID  = "group.com.hariom.wellplate"
    static let defaultsKey = "widgetFoodData"

    // MARK: - Persistence

    static func load() -> WidgetFoodData {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let raw      = defaults.data(forKey: defaultsKey),
            let decoded  = try? JSONDecoder().decode(WidgetFoodData.self, from: raw),
            Calendar.current.isDateInToday(decoded.lastUpdated)
        else { return .empty }
        return decoded
    }

    func save() {
        guard
            let defaults = UserDefaults(suiteName: Self.appGroupID),
            let encoded  = try? JSONEncoder().encode(self)
        else { return }
        defaults.set(encoded, forKey: Self.defaultsKey)
    }

    // MARK: - Presets

    static var empty: WidgetFoodData {
        WidgetFoodData(
            totalCalories: 0,
            totalProtein:  0,
            totalCarbs:    0,
            totalFat:      0,
            recentFoods:   [],
            calorieGoal:   2000,
            proteinGoal:   60,
            carbsGoal:     225,
            fatGoal:       65,
            lastUpdated:   .now
        )
    }

    static var placeholder: WidgetFoodData {
        WidgetFoodData(
            totalCalories: 1_243,
            totalProtein:  45,
            totalCarbs:    140,
            totalFat:      38,
            recentFoods: [
                WidgetFoodItem(id: UUID(), name: "Chicken Rice",  calories: 420),
                WidgetFoodItem(id: UUID(), name: "Greek Yogurt",  calories: 120),
                WidgetFoodItem(id: UUID(), name: "Oatmeal Bowl",  calories: 280)
            ],
            calorieGoal:  2000,
            proteinGoal:  60,
            carbsGoal:    225,
            fatGoal:      65,
            lastUpdated:  .now
        )
    }
}

struct WidgetFoodItem: Codable, Identifiable {
    var id:       UUID
    var name:     String
    var calories: Int
}
