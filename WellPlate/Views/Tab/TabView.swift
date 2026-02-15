import SwiftUI

struct ModernTabBarView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Analytics Tab
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            // Exercise Tab
            ExerciseView()
                .tabItem {
                    Label("Exercise", systemImage: "figure.run")
                }
                .tag(2)
            
            // Diets Tab
            DietsView()
                .tabItem {
                    Label("Diets", systemImage: "fork.knife")
                }
                .tag(3)
            
            // Camera Tab
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(4)
            
            // Assistant Tab
            AssistantView()
                .tabItem {
                    Label("Assistant", systemImage: "sparkles")
                }
                .tag(5)
        }
        .tint(.orange)
    }
}

// MARK: - Tab Views
struct AnalyticsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.green.opacity(0.3), Color.blue.opacity(0.3)]
                        : [Color.green.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Analytics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Track your progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Analytics")
        }
    }
}

struct ExerciseView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.orange.opacity(0.3), Color.red.opacity(0.3)]
                        : [Color.orange.opacity(0.1), Color.red.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Exercise")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Start your workout")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Exercise")
        }
    }
}

struct DietsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.pink.opacity(0.3), Color.purple.opacity(0.3)]
                        : [Color.pink.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Diets")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Plan your meals")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Diets")
        }
    }
}

struct CameraView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.indigo.opacity(0.3), Color.blue.opacity(0.3)]
                        : [Color.indigo.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.indigo, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Camera")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Capture your journey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Camera")
        }
    }
}

struct AssistantView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.purple.opacity(0.3), Color.pink.opacity(0.3)]
                        : [Color.purple.opacity(0.1), Color.pink.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Assistant")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Get personalized help")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Assistant")
        }
    }
}

// MARK: - Preview

#Preview {
    ModernTabBarView()
}
