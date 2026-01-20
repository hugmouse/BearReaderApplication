//
//  OnboardingView.swift
//  BearReaderApplication
//
//  Copyright 2026 Iaroslav Angliuster
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var currentPage = 0

    private let totalPages = 5

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)

                FeaturePage(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Discover",
                    subtitle: "Explore trending and recent posts from the community. Find writers who share your interests."
                )
                .tag(1)

                FeaturePage(
                    icon: "bell.badge.fill",
                    iconColor: .red,
                    title: "Subscribe",
                    subtitle: "Follow your favorite blogs and get notified when they publish new content."
                )
                .tag(2)

                FeaturePage(
                    icon: "arrow.down.circle.fill",
                    iconColor: .blue,
                    title: "Read Offline",
                    subtitle: "Posts are cached locally as you read. Access your content even without an internet connection."
                )
                .tag(3)

                FeaturePage(
                    icon: "magnifyingglass",
                    iconColor: .purple,
                    title: "Search",
                    subtitle: "Quickly find posts and blogs you've discovered. Your reading history is stored locally and searchable."
                )
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            VStack {
                Spacer()

                PageIndicator(currentPage: currentPage, totalPages: totalPages)
                    .padding(.bottom, 24)

                Button(action: {
                    if currentPage < totalPages - 1 {
                        currentPage += 1
                    } else {
                        settingsManager.hasSeenOnboarding = true
                    }
                }) {
                    Text(currentPage < totalPages - 1 ? "Continue" : "Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                if currentPage < totalPages - 1 {
                    Button("Skip") {
                        settingsManager.hasSeenOnboarding = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
                    .accessibilityIdentifier("OnboardingSkipButton")
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
    }
}

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                .padding(.bottom, 8)

            Text("Welcome to\nBear Reader")
                .font(.system(size: 36, weight: .bold, design: .default))
                .multilineTextAlignment(.center)

            Text("A minimal reader for Bear Blog")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

private struct FeaturePage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundColor(iconColor)
                .padding(.bottom, 8)

            Text(title)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

private struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingView(settingsManager: SettingsManager.shared)
}
