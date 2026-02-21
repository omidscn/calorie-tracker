import Foundation
import CoreData
import SwiftUI

@Observable
final class CloudSyncMonitor {
    var isSyncing = false

    private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else { return }

            guard event.type == .import || event.type == .setup else { return }

            withAnimation(.easeInOut(duration: 0.3)) {
                self?.isSyncing = event.endDate == nil
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
