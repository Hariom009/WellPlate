//
//  Components.swift
//  WellPlate
//
//  Created by Hari's Mac on 27.01.2026.
//

import Foundation
import SwiftUI

struct LiquidGlassButton1: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glass background
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.9),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .frame(height: 65)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
                
                // Text with gradient
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black,
                                    Color.black.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                }
            }
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct NeumorphicButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background with soft shadows
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
                    .frame(height: 70)
                    .shadow(color: Color.black.opacity(0.15), radius: isPressed ? 5 : 15, x: 0, y: isPressed ? 3 : 8)
                    .shadow(color: Color.white.opacity(0.9), radius: isPressed ? 5 : 15, x: 0, y: isPressed ? -3 : -8)
                
                // Inner shadow effect
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.1),
                                Color.white.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(height: 70)
                
                // Text
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                }
            }
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct BouncingArrowButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    @State private var arrowOffset: CGFloat = 0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glass background
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                    )
                    .frame(height: 68)
                    .shadow(color: Color.black.opacity(0.12), radius: 15, x: 0, y: 8)
                
                // Text with animated arrow
                HStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    ZStack {
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.orange)
                            .offset(x: arrowOffset)
                    }
                }
            }
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                arrowOffset = 5
            }
        }
    }
}
