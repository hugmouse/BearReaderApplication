//
//  ProfileNotificationsView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 28.11.25.
//

import SwiftUI
import UserNotifications

struct ProfileNotificationsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showSettingsAlert = false
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { notificationsEnabled },
                    set: { newValue in handleToggleChange(newValue) }
                )) {
                    HStack(spacing: 16) {
                        Image(systemName: "bell.badge")
                            .accessibilityHidden(true)
                        Text("Enable Notifications")
                    }
                }
                
                Button(action: openSystemSettings) {
                    HStack(spacing: 16) {
                        Image(systemName: "gear")
                            .foregroundStyle(.gray)
                            .accessibilityHidden(true)
                        Text("Open System Settings")
                    }
                }
            } header: {
                Text("Notifications")
            } footer: {
                if permissionStatus == .denied {
                    Text("Notifications are currently blocked in system settings.")
                        .foregroundStyle(.red)
                }
            }

            #if DEBUG
            Section {
                Button(action: scheduleTestNotifications) {
                    HStack(spacing: 16) {
                        Image(systemName: "bell.and.waves.left.and.right")
                            .accessibilityHidden(true)
                        Text("Test Grouped Notifications")
                    }
                }
            } header: {
                Text("Testing")
            } footer: {
                Text("Schedules 6 test notifications from 2 fake blogs to test thread grouping.")
            }
            #endif
        }
        .task {
            await checkPermissionStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await checkPermissionStatus() }
            }
        }
        // 7. Handle "Denied" state with an alert
        .alert("Permission Required", isPresented: $showSettingsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") { openSystemSettings() }
        } message: {
            Text("Notifications are disabled in Settings. Please enable them to receive updates.")
        }
    }
    
    // Updates the local state based on the actual system permission status.
    private func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        // Update state on MainActor (implicit in View methods)
        self.permissionStatus = settings.authorizationStatus
        
        // Resilience: If system denied it, force our local toggle OFF
        if settings.authorizationStatus == .denied {
            notificationsEnabled = false
        }
    }
    
    // Handles the user toggling the switch.
    private func handleToggleChange(_ newValue: Bool) {
        if newValue {
            // User wants to turn ON
            switch permissionStatus {
            case .notDetermined:
                // First time: Request Authorization
                requestAuthorization()
            case .denied:
                // Previously denied: Cannot programmatically enable. Guide user to settings.
                showSettingsAlert = true
                // Keep toggle off visually
                notificationsEnabled = false
            case .authorized, .provisional, .ephemeral:
                // Already authorized: Just update local preference
                notificationsEnabled = true
            @unknown default:
                break
            }
        } else {
            // User wants to turn OFF
            // We just update local pref. We do not revoke system permissions (Apple doesn't allow it).
            notificationsEnabled = false
        }
    }
    
    // Requests notification permissions using Swift 6 async/await.
    private func requestAuthorization() {
        Task {
            do {
                let center = UNUserNotificationCenter.current()
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                
                // Re-check status to sync UI immediately
                await checkPermissionStatus()
                
                if granted {
                    notificationsEnabled = true
                } else {
                    notificationsEnabled = false
                }
            } catch {
                print("Authorization request failed: \(error.localizedDescription)")
                notificationsEnabled = false
            }
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    #if DEBUG
    private func scheduleTestNotifications() {
        Task {
            let center = UNUserNotificationCenter.current()

            let testData: [(blog: String, blogTitle: String, posts: [String])] = [
                ("test-blog-a.bearblog.dev", "Test Blog A", ["First Post from A", "Second Post from A", "Third Post from A"]),
                ("test-blog-b.bearblog.dev", "Test Blog B", ["First Post from B", "Second Post from B", "Third Post from B"])
            ]

            for blogData in testData {
                for (index, postTitle) in blogData.posts.enumerated() {
                    let content = UNMutableNotificationContent()
                    content.title = "New post from \(blogData.blogTitle)"
                    content.body = postTitle
                    content.sound = .default
                    content.threadIdentifier = blogData.blog

                    let identifier = "test-\(blogData.blog)-\(index)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

                    do {
                        try await center.add(request)
                    } catch {
                        print("Failed to schedule test notification: \(error)")
                    }
                }
            }
        }
    }
    #endif
}
