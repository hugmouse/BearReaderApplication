//
//  NotificationPermissionManager.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 22.11.25.
//

import UserNotifications
import SwiftUI
import Combine
import Observation

@MainActor
@Observable class NotificationPermissionManager {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    init() {
        checkStatus()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkStatus),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func checkStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            self.authorizationStatus = settings.authorizationStatus
        }
    }
    
    func requestPermission() async {
        do {
            let _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            checkStatus()
        } catch {
            print("APNS Authorization Error: \(error.localizedDescription)")
        }
    }
}
