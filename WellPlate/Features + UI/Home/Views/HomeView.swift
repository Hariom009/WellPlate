//
//  HomeView.swift
//  WellPlate
//
//  Created by Claude on 16.02.2026.
//  Updated by Claude on 17.02.2026.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showProfile = false
    @State private var isGoalsExpanded = false
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        ZStack {
            Color(.white)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                topNavigationBar
                
                // Text Editor Mode - Always visible like a notebook
                textEditorView
                
                Spacer()
            }
            
            // Expandable Goals View - Always visible at bottom
            // This gets updated when analysis completes
            VStack {
                Spacer()
                GoalsExpandableView(
                    isExpanded: $isGoalsExpanded,
                    currentNutrition: viewModel.nutritionalInfo,
                    dailyGoals: .default
                )
                .onTapGesture {
                    if !isGoalsExpanded {
                        isGoalsExpanded = true
                    }
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .onChange(of: viewModel.nutritionalInfo) { oldValue, newValue in
            // Auto-expand goals view when new nutritional info is available
            if newValue != nil && oldValue == nil {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isGoalsExpanded = true
                }
            }
        }
    }

    // MARK: - Top Navigation Bar

    private var topNavigationBar: some View {
        ZStack{
            HStack{
                // Left - Logo Space (placeholder for now)
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.orange)
                    )
                
                Spacer()
                
                // Right - Streak and Profile
                HStack(spacing: 12){
                    // Streak Button
                    Button(action: {
                        // Streak action
                    }) {
                        HStack(spacing:4){
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                            
                            Text("1")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    HStack{
                        // Profile Button
                        Button(action: {
                            showProfile = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.9))
                        }
                    }
                }
                .padding(.horizontal,8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            }
            
            // Center - Date Selector
            Button(action: {
                showDatePicker = true
            }) {
                HStack(spacing: 8) {
                    Text(dateText)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            }
            
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Text Editor View (Notebook Style)
    
    private var textEditorView: some View {
        ZStack(alignment: .topLeading) {
            // Background that's tappable
            Color(.white)
            
            VStack(spacing: 0) {
                // Text Editor - takes full height, always visible
                ZStack(alignment: .topLeading) {
                    // Placeholder text
                    if viewModel.foodDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start logging your meals...")
                                .font(.system(size: 16))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                        }
                        .allowsHitTesting(false)
                    }
                    
                    // The actual text editor with inline analyze button
                    HStack(alignment: .top, spacing: 12) {
                        TextEditor(text: $viewModel.foodDescription)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .focused($isTextEditorFocused)
                            .disabled(viewModel.isLoading)
                            .tint(.orange)
                            .onSubmit {
                                // Trigger analysis when Enter/Return is pressed
                                if !viewModel.foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    triggerAnalysis()
                                }
                            }
                            .submitLabel(.done)
                        
                        // Inline Analyze Button - appears when there's text
                        if !viewModel.foodDescription.isEmpty {
                            Button(action: {
                                triggerAnalysis()
                            }) {
                                Group {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(viewModel.isLoading)
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
        }
        .onAppear {
            // Auto-focus when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextEditorFocused = true
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func triggerAnalysis() {
        isTextEditorFocused = false
        // Remove the last newline if it exists (from pressing Enter)
        if viewModel.foodDescription.hasSuffix("\n") {
            viewModel.foodDescription.removeLast()
        }
        Task {
            await viewModel.analyzeFood()
        }
    }
    
    // MARK: - Date Picker Sheet
    
    private var datePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Today") {
                        selectedDate = Date()
                    }
                    .foregroundColor(.orange)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showDatePicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var dateText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(spacing: 20) {
            if let info = viewModel.nutritionalInfo {
                // Food Name & Serving
                VStack(spacing: 8) {
                    Text(info.foodName)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let serving = info.servingSize {
                        Text(serving)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let confidence = info.confidence {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(Int(confidence * 100))% confidence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                )

                // Nutrition Grid
                nutritionGrid(info: info)
            }
        }
    }

    private func nutritionGrid(info: NutritionalInfo) -> some View {
        VStack(spacing: 16) {
            // Main Macros
            HStack(spacing: 12) {
                nutritionCard(
                    icon: "flame.fill",
                    color: .orange,
                    label: "Calories",
                    value: "\(info.calories)",
                    unit: "kcal"
                )
                
                nutritionCard(
                    icon: "figure.strengthtraining.traditional",
                    color: .red,
                    label: "Protein",
                    value: String(format: "%.1f", info.protein),
                    unit: "g"
                )
            }
            
            HStack(spacing: 12) {
                nutritionCard(
                    icon: "leaf.fill",
                    color: .blue,
                    label: "Carbs",
                    value: String(format: "%.1f", info.carbs),
                    unit: "g"
                )
                
                nutritionCard(
                    icon: "drop.fill",
                    color: .yellow,
                    label: "Fat",
                    value: String(format: "%.1f", info.fat),
                    unit: "g"
                )
            }
            
            // Fiber as full width
            nutritionCardFullWidth(
                icon: "chevron.up.chevron.down",
                color: .green,
                label: "Fiber",
                value: String(format: "%.1f", info.fiber),
                unit: "g"
            )
        }
    }
    
    private func nutritionCard(icon: String, color: Color, label: String, value: String, unit: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private func nutritionCardFullWidth(icon: String, color: Color, label: String, value: String, unit: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Clear Button

    private var clearButton: some View {
        Button(action: {
            viewModel.clearResults()
            // Re-focus the text editor after clearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextEditorFocused = true
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                Text("Log Another Meal")
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(.white)
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

#Preview {
    HomeView()
}
