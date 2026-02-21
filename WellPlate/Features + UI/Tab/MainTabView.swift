//
//  MainTabView.swift
//  WellPlate
//
//  Created by Hari's Mac on 20.02.2026.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            // MARK: - Intake
            Tab("Intake", systemImage: "fork.knife") {
                HomeView(viewModel: HomeViewModel(modelContext: modelContext))
            }

            // MARK: - Burn
            Tab("Burn", systemImage: "flame.fill") {
                BurnView()
            }

            // MARK: - Sleep
            Tab("Sleep", systemImage: "moon.zzz.fill") {
                SleepView()
            }

            // MARK: - Stress
            Tab("Stress", systemImage: "brain.head.profile.fill") {
                StressView(viewModel: StressViewModel(modelContext: modelContext))
            }

            // MARK: - Profile (separated — like Search in Apple Music)
            Tab("Profile", systemImage: "person.crop.circle.fill", role: .search) {
                ProfilePlaceholderView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(.orange)
    }
}

#Preview {
    MainTabView()
}

