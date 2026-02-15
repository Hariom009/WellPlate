//
//  HomeView.swift
//  WellPlate
//
//  Created by Hari's Mac on 27.01.2026.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]
                        : [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Home")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Welcome to your dashboard")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Home")
        }
    }
}
