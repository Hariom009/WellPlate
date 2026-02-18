c//
//  GoalsExpandableView.swift
//  WellPlate
//
//  Created by Claude on 17.02.2026.
//

import SwiftUI

struct GoalsExpandableView: View {
    @Binding var isExpanded: Bool
    let currentNutrition: NutritionalInfo?
    let dailyGoals: DailyGoals
    
    // Animation namespace for matched geometry
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            } else {
                collapsedView
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
    
    // MARK: - Collapsed View (Bottom Bar)
    
    private var collapsedView: some View {
        Button(action: {
            isExpanded = true
        }) {
            HStack(spacing: 12) {
                // Calories
                nutritionPill(
                    icon: "🔥",
                    value: currentCalories,
                    label: "C"
                )
                
                Text("•")
                    .foregroundColor(.gray.opacity(0.3))
                    .font(.caption)
                
                // Carbs
                nutritionPill(
                    icon: "🍞",
                    value: currentCarbs,
                    label: "C"
                )
                
                Text("•")
                    .foregroundColor(.gray.opacity(0.3))
                    .font(.caption)
                
                // Protein
                nutritionPill(
                    icon: "🥩",
                    value: currentProtein,
                    label: "P"
                )
                
                Text("•")
                    .foregroundColor(.gray.opacity(0.3))
                    .font(.caption)
                
                // Fat
                nutritionPill(
                    icon: "🥑",
                    value: currentFat,
                    label: "F"
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    private func nutritionPill(icon: String, value: Int, label: String) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.r(14, .regular))
            
            Text("\(value)")
                .font(.r(14, .semibold))
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Expanded View
    
    private var expandedView: some View {
        VStack(spacing: 0) {
            // Goals Card
            VStack(spacing: 20) {
                // Header with dismiss button
                HStack {
                    Text("Goals")
                        .font(.system(size: 24, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: {
                        isExpanded = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }
                
                // Calories Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Text("🔥")
                                .font(.system(size: 16))
                            Text("Calories")
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Spacer()
                        
                        Text("\(currentCalories) / \(dailyGoals.calories)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: min(geometry.size.width * caloriesProgress, geometry.size.width))
                        }
                    }
                    .frame(height: 12)
                }
                
                // Macro Circles - Top Row
                HStack(spacing: 20) {
                    macroCircle(
                        value: currentCarbs,
                        goal: dailyGoals.carbs,
                        label: "Carbs",
                        unit: "g",
                        color: .blue
                    )
                    
                    macroCircle(
                        value: currentProtein,
                        goal: dailyGoals.protein,
                        label: "Protein",
                        unit: "g",
                        color: .red
                    )
                    
                    macroCircle(
                        value: currentFat,
                        goal: dailyGoals.fat,
                        label: "Fat",
                        unit: "g",
                        color: .yellow
                    )
                }
                
                // Macro Circles - Bottom Row
                HStack(spacing: 20) {
                    macroCircle(
                        value: currentSugar,
                        goal: dailyGoals.sugar,
                        label: "Sugar",
                        unit: "g",
                        color: .pink
                    )
                    
                    macroCircle(
                        value: currentFiber,
                        goal: dailyGoals.fiber,
                        label: "Fiber",
                        unit: "g",
                        color: .green
                    )
                    
                    macroCircle(
                        value: currentSodium,
                        goal: dailyGoals.sodium,
                        label: "Sodium",
                        unit: "mg",
                        color: .purple
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Macro Circle Component
    
    private func macroCircle(value: Int, goal: Int, label: String, unit: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 8)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: min(CGFloat(value) / CGFloat(goal), 1.0))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // Value text
                Text("\(value)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(width: 80, height: 80)
            
            // Label
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var currentCalories: Int {
        currentNutrition?.calories ?? 0
    }
    
    private var currentCarbs: Int {
        Int(currentNutrition?.carbs ?? 0)
    }
    
    private var currentProtein: Int {
        Int(currentNutrition?.protein ?? 0)
    }
    
    private var currentFat: Int {
        Int(currentNutrition?.fat ?? 0)
    }
    
    private var currentSugar: Int {
        // Approximate sugar as 40% of carbs (common estimate)
        Int((currentNutrition?.carbs ?? 0) * 0.4)
    }
    
    private var currentFiber: Int {
        Int(currentNutrition?.fiber ?? 0)
    }
    
    private var currentSodium: Int {
        // Estimate ~600mg sodium per 500 calories (rough average)
        Int(Double(currentCalories) * 1.2)
    }
    
    private var caloriesProgress: CGFloat {
        guard dailyGoals.calories > 0 else { return 0 }
        return CGFloat(currentCalories) / CGFloat(dailyGoals.calories)
    }
}

// MARK: - Daily Goals Model

struct DailyGoals {
    let calories: Int
    let carbs: Int
    let protein: Int
    let fat: Int
    let sugar: Int
    let fiber: Int
    let sodium: Int
    
    static let `default` = DailyGoals(
        calories: 1942,
        carbs: 220,
        protein: 150,
        fat: 65,
        sugar: 50,
        fiber: 30,
        sodium: 2300
    )
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        
        GoalsExpandableView(
            isExpanded: .constant(false),
            currentNutrition: NutritionalInfo(
                foodName: "Grilled Chicken Salad",
                servingSize: "1 bowl",
                calories: 450,
                protein: 45.0,
                carbs: 30.0,
                fat: 15.0,
                fiber: 8.0,
                confidence: 0.95
            ),
            dailyGoals: .default
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Expanded") {
    VStack {
        Spacer()
        
        GoalsExpandableView(
            isExpanded: .constant(true),
            currentNutrition: NutritionalInfo(
                foodName: "Grilled Chicken Salad",
                servingSize: "1 bowl",
                calories: 450,
                protein: 45.0,
                carbs: 30.0,
                fat: 15.0,
                fiber: 8.0,
                confidence: 0.95
            ),
            dailyGoals: .default
        )
    }
    .background(Color(.systemGroupedBackground))
}
