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
            HomeView(viewModel: HomeViewModel(modelContext: modelContext))
                .tabItem {
                    Label("Intake", systemImage: "fork.knife")
                }

            // MARK: - Burn
            BurnView()
                .tabItem {
                    Label("Burn", systemImage: "flame.fill")
                }

            // MARK: - Sleep
            SleepPlaceholderView()
                .tabItem {
                    Label("Sleep", systemImage: "moon.zzz.fill")
                }

            // MARK: - Profile
            ProfilePlaceholderView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(.orange)
    }
}

#Preview {
    MainTabView()
}

