//
//  Notifications.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 16.12.25.
//

import SwiftUI
import UserNotifications

@MainActor
class NotificationManager: NSObject, ObservableObject, @MainActor UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let title = userInfo["title"] as? String,
           let url = userInfo["url"] as? String,
           let age = userInfo["age"] as? String,
           let rating = userInfo["rating"] as? String {
            
            let post = PostItem(title: title, url: url, age: age, rating: rating)
            
            Task { @MainActor in
                Router.shared.openPost(post)
            }
        }
        
        completionHandler()
    }
    
    // Allow notifications to appear while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
